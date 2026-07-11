create table if not exists public.app_events (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  event_name text not null,
  flow text,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists app_events_owner_id_created_at_idx
  on public.app_events (owner_id, created_at desc);

alter table public.app_events enable row level security;

drop policy if exists app_events_owner_access on public.app_events;

create policy app_events_owner_access
  on public.app_events
  for all
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());
