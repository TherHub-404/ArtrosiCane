-- Quick Check daily flow schema
-- Run in Supabase SQL Editor.

create table if not exists public.actions (
  id text primary key,
  text_it text not null,
  type text not null check (type in ('action', 'avoid')),
  category text not null,
  semaforo_min text not null check (semaforo_min in ('verde', 'giallo', 'rosso')),
  semaforo_max text not null check (semaforo_max in ('verde', 'giallo', 'rosso')),
  load_min smallint not null check (load_min between 0 and 2),
  load_max smallint not null check (load_max between 0 and 2),
  recovery_min smallint null check (recovery_min between 0 and 2),
  risk_factor_tags text[] not null default '{}',
  priority_base smallint not null default 10,
  cooldown_days smallint null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.daily_logs (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  dog_id uuid null references public.dogs(id) on delete set null,
  symptom_level smallint not null check (symptom_level between 0 and 2),
  load_planned smallint not null check (load_planned between 0 and 2),
  risk_factors text[] not null default '{}',
  recovery_delta smallint not null check (recovery_delta between 0 and 2),
  diagnosis_status text null check (diagnosis_status in ('confirmed', 'notDiagnosed', 'unknown')),
  raw_score smallint not null,
  score smallint not null,
  semaphore text not null check (semaphore in ('verde', 'giallo', 'rosso')),
  actions text[] not null default '{}',
  avoid text not null default '',
  route_tag text not null default 'standard',
  video_label text not null default '',
  video_url text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists public.factor_sensitivity (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  dog_id uuid null references public.dogs(id) on delete cascade,
  factor text not null,
  impact_weight smallint not null check (impact_weight between 0 and 5),
  source text not null default 'computed',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (owner_id, dog_id, factor)
);

alter table public.actions enable row level security;
alter table public.daily_logs enable row level security;
alter table public.factor_sensitivity enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'actions'
      and policyname = 'actions_read_authenticated'
  ) then
    create policy actions_read_authenticated
      on public.actions for select
      to authenticated
      using (true);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'daily_logs'
      and policyname = 'daily_logs_owner_all'
  ) then
    create policy daily_logs_owner_all
      on public.daily_logs for all
      to authenticated
      using (owner_id = auth.uid())
      with check (owner_id = auth.uid());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'factor_sensitivity'
      and policyname = 'factor_sensitivity_owner_all'
  ) then
    create policy factor_sensitivity_owner_all
      on public.factor_sensitivity for all
      to authenticated
      using (owner_id = auth.uid())
      with check (owner_id = auth.uid());
  end if;
end $$;

insert into public.actions (
  id, text_it, type, category, semaforo_min, semaforo_max,
  load_min, load_max, recovery_min, risk_factor_tags, priority_base
)
values
  ('A01', 'Spezza la passeggiata in 2 uscite piu brevi.', 'action', 'durata', 'giallo', 'rosso', 1, 2, null, '{}', 13),
  ('A02', 'Scegli fondo compatto e regolare.', 'action', 'superficie', 'verde', 'rosso', 0, 2, null, '{sabbia,scivoloso}', 11),
  ('A03', 'Aggiungi una pausa di 2 minuti ogni 10 minuti.', 'action', 'pause', 'giallo', 'rosso', 1, 2, null, '{}', 12),
  ('A04', 'Programma uscita al fresco: mattina presto o sera.', 'action', 'ambiente', 'verde', 'rosso', 0, 2, null, '{caldo}', 10),
  ('A05', 'Prediligi passo lento e costante.', 'action', 'ritmo', 'verde', 'rosso', 0, 2, 1, '{}', 10),
  ('A06', 'Fai un riscaldamento dolce di 2 minuti prima di uscire.', 'action', 'attivazione', 'giallo', 'rosso', 0, 2, null, '{}', 11),
  ('V01', 'Evita scale ripetute oggi.', 'avoid', 'evita-scale', 'giallo', 'rosso', 0, 2, null, '{scale}', 14),
  ('V02', 'Evita sabbia morbida nelle ore centrali.', 'avoid', 'evita-sabbia', 'giallo', 'rosso', 0, 2, null, '{sabbia,caldo}', 13),
  ('V03', 'Evita salti da auto o divano.', 'avoid', 'evita-salti', 'giallo', 'rosso', 0, 2, null, '{auto}', 12),
  ('V04', 'Evita scatti e cambi di ritmo improvvisi.', 'avoid', 'evita-scatti', 'verde', 'rosso', 0, 2, null, '{}', 10)
on conflict (id) do update set
  text_it = excluded.text_it,
  type = excluded.type,
  category = excluded.category,
  semaforo_min = excluded.semaforo_min,
  semaforo_max = excluded.semaforo_max,
  load_min = excluded.load_min,
  load_max = excluded.load_max,
  recovery_min = excluded.recovery_min,
  risk_factor_tags = excluded.risk_factor_tags,
  priority_base = excluded.priority_base,
  updated_at = now();
