# Loom Script (3-5 minuti): Overview Supabase

Obiettivo: far vedere a colpo d'occhio come e' strutturato Supabase per ArtrosiCane (tabelle + connessioni + automazioni) e dove il codice app "tocca" il backend.

## 0. Intro (15s)

- "Vi faccio vedere velocemente: tabelle principali, relazioni e cosa usa l'app Flutter. Nota: nel repo non ci sono migrations/edge functions versionate, quindi la parte 'automazioni' e' soprattutto dashboard + uno script di import."

## 1. Chiavi + connessione app (45s)

Apri repo (o menziona file):
- `.env` (valori): `SUPABASE_URL`, `SUPABASE_ANON_KEY`
- `lib/core/config/app_config.dart`: carica `.env`
- `lib/core/providers/supabase_provider.dart`: `Supabase.initialize(...)`
- Nota: Realtime e' configurato (`eventsPerSecond: 2`) ma nel codice non vedo subscription Realtime al momento.

## 2. Auth + Profiles (45s)

In dashboard Supabase:
- Auth: Users (sign up / sign in)
- Tabella `profiles`
  - `id` = `auth.users.id`
  - `email`, `nickname`

Nel codice:
- `lib/features/auth/data/auth_repository.dart`:
  - signup/login
  - `profiles.upsert(...)` dopo login e dopo signup (se sessione creata subito)

## 3. Tabelle dominio (1m30s)

### `breeds`

Dashboard: tabella `breeds` con `name`, `name_it`, `image_url`.
Codice:
- `lib/features/onboarding/data/repositories/breed_repository.dart` fa select `id, name, name_it`.

Automazione/script:
- `tool/import_dog_breeds.dart`:
  - prende razze da TheDogAPI
  - traduce (LibreTranslate + overrides CSV)
  - upsert via REST su `breeds` con service role

### `dogs`

Dashboard: tabella `dogs`:
- `owner_id`, `name`, `age_years`, `weight_kg`, `breed_id`, `created_at`
Relazione:
- `dogs.breed_id -> breeds.id`

Codice:
- `lib/features/home/data/dog_remote_repository.dart`: fetch + join `breeds(...)`, add/update/delete (sempre scoping per `owner_id`)
- `lib/features/onboarding/data/repositories/dog_supabase_repository.dart`: upsert per `(owner_id, name)`

### `quiz_results` + `quiz_answers`

Dashboard:
- `quiz_results`: `owner_id`, `dog_id` (opzionale), `score`, `risk_level`, `created_at`
- `quiz_answers`: `result_id`, `question_id`, `answer_value`
Relazioni:
- `quiz_results.dog_id -> dogs.id`
- `quiz_answers.result_id -> quiz_results.id`

Codice:
- `lib/features/quiz/data/datasources/quiz_remote_data_source.dart`: inserisce `quiz_results`, poi bulk insert in `quiz_answers`
- `lib/features/home/data/dog_remote_repository.dart`: carica ultimi risultati per owner e li associa in memoria ai cani

## 4. Automazioni + sicurezza (45s)

Spiega cosa e' "automazione" qui:
- Nel repo non ci sono Edge Functions / cron / migrazioni SQL.
- Automazione presente: script import razze.

Mostra in dashboard:
- RLS + Policies su `dogs`, `quiz_results`, `quiz_answers`, `profiles` (da verificare).

Chiusura:
- "Se mi date un export schema/policy (o accesso read-only), posso completare la parte 'automazioni' con trigger/edge/scheduler effettivi."

