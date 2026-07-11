-- =====================================================================
-- advice_videos
--
-- Dynamic content for the "Passeggiate" reels tab. Lets maintainers add
-- or reorder advice videos from the web dashboard without an app release.
--
--   - title / description are JSONB keyed by language (it/en/fr/de);
--     the app falls back to 'it' when a language is missing.
--   - storage_path is the file name inside the public 'advice-videos'
--     Storage bucket.
--   - position controls the reel order; is_active hides a video without
--     deleting it.
--   - RLS: public (anon + authenticated) read of active rows only.
--     Writes go through the dashboard service-role client.
-- =====================================================================

create table if not exists public.advice_videos (
  id uuid primary key default gen_random_uuid(),
  title jsonb not null default '{}'::jsonb,
  description jsonb not null default '{}'::jsonb,
  storage_path text not null,
  position integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists advice_videos_active_position_idx
  on public.advice_videos (is_active, position);

alter table public.advice_videos enable row level security;

drop policy if exists advice_videos_public_read on public.advice_videos;
create policy advice_videos_public_read on public.advice_videos
  for select
  using (is_active = true);

grant select on public.advice_videos to anon, authenticated;

create or replace function public.advice_videos_touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists advice_videos_touch on public.advice_videos;
create trigger advice_videos_touch
  before update on public.advice_videos
  for each row execute function public.advice_videos_touch_updated_at();

-- ---------------------------------------------------------------------
-- Seed: the 4 videos previously hard-coded in the app.
-- ---------------------------------------------------------------------
insert into public.advice_videos (title, description, storage_path, position, is_active) values
(
  '{"it":"Consigli per le passeggiate","en":"Walking advice","fr":"Conseils pour les promenades","de":"Tipps fuer Spaziergaenge"}'::jsonb,
  '{"it":"Trasforma la passeggiata quotidiana in un momento di benessere per le articolazioni del tuo cane.","en":"Turn the daily walk into a moment of wellness for your dog''s joints.","fr":"Transformez la promenade quotidienne en un moment de bien-etre pour les articulations de votre chien.","de":"Mache den taeglichen Spaziergang zu einem Moment des Wohlbefindens fuer die Gelenke deines Hundes."}'::jsonb,
  'walks-advice.mp4', 1, true
),
(
  '{"it":"Camminata: tecnica e ritmo","en":"Walking: technique and pace","fr":"Marche : technique et rythme","de":"Gehen: Technik und Rhythmus"}'::jsonb,
  '{"it":"Il ritmo giusto e la postura corretta per proteggere le articolazioni durante la camminata.","en":"The right pace and correct posture to protect the joints while walking.","fr":"Le bon rythme et la posture correcte pour proteger les articulations pendant la marche.","de":"Das richtige Tempo und die korrekte Haltung, um die Gelenke beim Gehen zu schuetzen."}'::jsonb,
  'consigli-camminata-cane.mp4', 2, true
),
(
  '{"it":"Camminata in acqua","en":"Walking in water","fr":"Marche dans l''eau","de":"Gehen im Wasser"}'::jsonb,
  '{"it":"L''acqua riduce il carico sulle articolazioni: ecco come sfruttarla al meglio con il tuo cane.","en":"Water reduces the load on the joints: here is how to make the most of it with your dog.","fr":"L''eau reduit la charge sur les articulations : voici comment en profiter au mieux avec votre chien.","de":"Wasser verringert die Belastung der Gelenke: So nutzt du es mit deinem Hund optimal."}'::jsonb,
  'consigli-camminata-in-acqua.mp4', 3, true
),
(
  '{"it":"Camminata in spiaggia","en":"Walking on the beach","fr":"Marche sur la plage","de":"Gehen am Strand"}'::jsonb,
  '{"it":"Camminare sulla sabbia rinforza la muscolatura: i consigli per farlo in sicurezza.","en":"Walking on sand strengthens the muscles: tips to do it safely.","fr":"Marcher sur le sable renforce la musculature : nos conseils pour le faire en toute securite.","de":"Gehen im Sand staerkt die Muskulatur: Tipps, um es sicher zu tun."}'::jsonb,
  'consigli-camminata-in-spiaggia.mp4', 4, true
)
on conflict do nothing;
