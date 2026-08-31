-- Store the calendar day chosen by the client so diary availability follows
-- the user's local day rather than resetting at UTC midnight.
alter table public.daily_logs
  add column if not exists diary_date date;

-- Preserve every historical row. For legacy duplicate days, only the newest
-- row receives the normalized date; older rows remain available in history.
with ranked_logs as (
  select
    ctid as row_locator,
    row_number() over (
      partition by owner_id, dog_id, created_at::date
      order by created_at desc, ctid desc
    ) as daily_rank
  from public.daily_logs
  where diary_date is null
)
update public.daily_logs as daily_log
set diary_date = daily_log.created_at::date
from ranked_logs
where daily_log.ctid = ranked_logs.row_locator
  and ranked_logs.daily_rank = 1;

create unique index if not exists daily_logs_owner_dog_diary_date_key
  on public.daily_logs (owner_id, dog_id, diary_date);
