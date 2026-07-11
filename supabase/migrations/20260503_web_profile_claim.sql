-- =====================================================================
-- Web profile claim (Option B2)
--
-- Lets the marketing website pre-populate public.profiles + public.dogs
-- before the user has any record in auth.users. At first app login,
-- public.claim_profile() binds the pre-populated row to auth.uid()
-- by rebinding profiles.id (cascades to dogs/quiz_results via FK).
--
-- After this migration:
--   - profiles.id is decoupled from auth.users.id (FK dropped)
--   - profiles.id default = gen_random_uuid() (site can omit it)
--   - profiles.auth_user_id uuid UNIQUE binds a profile to auth.users
--     (NULL = pre-populated by the website, not yet claimed)
--   - profiles.email is always lowercased + trimmed (trigger)
--   - dogs.owner_id and quiz_results.owner_id FKs gain ON UPDATE CASCADE
--     so the claim can rebind the profile.id atomically
--   - RLS on profiles switches from id = auth.uid() to
--     auth_user_id = auth.uid()
--   - public.claim_profile() (SECURITY DEFINER) callable by authenticated
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1) profiles: decouple id from auth.users + add auth_user_id
-- ---------------------------------------------------------------------
alter table public.profiles
  drop constraint if exists profiles_id_fkey;

alter table public.profiles
  alter column id set default gen_random_uuid();

alter table public.profiles
  add column if not exists auth_user_id uuid;

alter table public.profiles
  drop constraint if exists profiles_auth_user_id_fkey;

alter table public.profiles
  add constraint profiles_auth_user_id_fkey
  foreign key (auth_user_id) references auth.users(id) on delete cascade;

create unique index if not exists profiles_auth_user_id_unique_idx
  on public.profiles (auth_user_id)
  where auth_user_id is not null;

-- Backfill: existing rows where id == auth.users.id (current convention).
update public.profiles p
   set auth_user_id = p.id
 where p.auth_user_id is null
   and exists (select 1 from auth.users u where u.id = p.id);

-- ---------------------------------------------------------------------
-- 2) Email normalization + case-insensitive uniqueness
-- ---------------------------------------------------------------------
update public.profiles
   set email = lower(trim(email))
 where email is not null
   and email <> lower(trim(email));

create or replace function public.profiles_normalize_email()
returns trigger
language plpgsql
as $$
begin
  if new.email is not null then
    new.email := lower(trim(new.email));
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_normalize_email_trigger on public.profiles;
create trigger profiles_normalize_email_trigger
  before insert or update of email on public.profiles
  for each row execute function public.profiles_normalize_email();

alter table public.profiles
  drop constraint if exists profiles_email_key;

create unique index if not exists profiles_email_lower_idx
  on public.profiles (lower(email));

-- ---------------------------------------------------------------------
-- 3) Add ON UPDATE CASCADE to FKs that point at profiles.id so the
--    claim function can rebind profile.id atomically.
-- ---------------------------------------------------------------------
alter table public.dogs
  drop constraint if exists dogs_owner_id_fkey;
alter table public.dogs
  add constraint dogs_owner_id_fkey
  foreign key (owner_id) references public.profiles(id)
  on update cascade on delete cascade;

alter table public.quiz_results
  drop constraint if exists quiz_results_owner_id_fkey;
alter table public.quiz_results
  add constraint quiz_results_owner_id_fkey
  foreign key (owner_id) references public.profiles(id)
  on update cascade on delete cascade;

-- ---------------------------------------------------------------------
-- 4) RLS on profiles: id-based → auth_user_id-based
--    (dogs/quiz_results policies stay owner_id = auth.uid() because the
--     claim rebinds owner_id to auth.uid() via cascade.)
-- ---------------------------------------------------------------------
alter table public.profiles enable row level security;

drop policy if exists profiles_self_access on public.profiles;
drop policy if exists profiles_select_own on public.profiles;
drop policy if exists profiles_insert_own on public.profiles;
drop policy if exists profiles_update_own on public.profiles;

create policy profiles_select_own on public.profiles
  for select using (auth_user_id = auth.uid());

create policy profiles_update_own on public.profiles
  for update using (auth_user_id = auth.uid())
  with check (auth_user_id = auth.uid());

create policy profiles_insert_own on public.profiles
  for insert with check (auth_user_id = auth.uid());

-- ---------------------------------------------------------------------
-- 5) claim_profile()
--    Idempotent. Returns the profile.id now owned by auth.uid().
--
--    Behavior:
--      a) if a profile with auth_user_id = auth.uid() already exists →
--         return its id (no-op for repeat calls)
--      b) else if a pre-populated row matches by email and is unclaimed →
--         delete any auto-created row for this auth user, then
--         UPDATE profiles SET id = auth.uid(), auth_user_id = auth.uid()
--         (FK CASCADE rebinds dogs.owner_id and quiz_results.owner_id)
--      c) else → INSERT a fresh row with id = auth.uid()
-- ---------------------------------------------------------------------
create or replace function public.claim_profile()
returns uuid
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_uid uuid := auth.uid();
  v_email text := lower(trim(coalesce(auth.jwt() ->> 'email', '')));
  v_existing_id uuid;
  v_unclaimed_id uuid;
begin
  if v_uid is null then
    raise exception 'claim_profile: no authenticated user';
  end if;
  if v_email = '' then
    raise exception 'claim_profile: missing email in JWT';
  end if;

  -- (a) already claimed
  select id into v_existing_id
    from public.profiles
   where auth_user_id = v_uid
   limit 1;
  if v_existing_id is not null then
    return v_existing_id;
  end if;

  -- (b) pre-populated by website
  select id into v_unclaimed_id
    from public.profiles
   where lower(email) = v_email
     and auth_user_id is null
   limit 1;

  if v_unclaimed_id is not null then
    -- Drop any auto-created row that may collide on the new id (no children
    -- yet, since we have not run the app's first sync).
    delete from public.profiles
     where id = v_uid
       and auth_user_id is null;

    update public.profiles
       set id = v_uid,
           auth_user_id = v_uid
     where id = v_unclaimed_id;

    return v_uid;
  end if;

  -- (c) brand new user with no website data
  insert into public.profiles (id, email, auth_user_id)
       values (v_uid, v_email, v_uid)
  on conflict (id) do update
       set email = excluded.email,
           auth_user_id = excluded.auth_user_id
  returning id into v_existing_id;

  return v_existing_id;
end;
$$;

revoke all on function public.claim_profile() from public;
revoke execute on function public.claim_profile() from anon;
grant execute on function public.claim_profile() to authenticated;
