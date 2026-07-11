alter table if exists public.dogs
  add column if not exists is_deleted boolean not null default false;

alter table if exists public.dogs
  add column if not exists deleted_at timestamptz null;

alter table if exists public.profiles
  add column if not exists is_deleted boolean not null default false;

alter table if exists public.profiles
  add column if not exists deleted_at timestamptz null;

create index if not exists dogs_owner_id_is_deleted_idx
  on public.dogs (owner_id, is_deleted);

create index if not exists dogs_owner_id_deleted_at_idx
  on public.dogs (owner_id, deleted_at);

create index if not exists profiles_is_deleted_idx
  on public.profiles (is_deleted);

create index if not exists profiles_deleted_at_idx
  on public.profiles (deleted_at);
