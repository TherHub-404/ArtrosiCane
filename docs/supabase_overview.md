# Supabase Overview (ArtrosiCane)

Questo documento e' derivato da cio' che risulta nel repo Flutter (query, tabelle referenziate, script di import). Le automazioni lato Supabase (RLS/policy, trigger, Edge Functions, scheduler) non sono versionate qui: per una panoramica completa serve guardare anche la dashboard Supabase.

## Connessione (app Flutter)

- Config:
  - `SUPABASE_URL`, `SUPABASE_ANON_KEY` vengono letti da `.env` in `lib/core/config/app_config.dart`.
- Init:
  - `initializeSupabase()` in `lib/core/providers/supabase_provider.dart` chiama `Supabase.initialize(url, anonKey, realtimeClientOptions: eventsPerSecond=2)`.
- Accesso al client:
  - `Supabase.instance.client` viene esposto come provider Riverpod `supabaseClientProvider` in `lib/core/providers/supabase_provider.dart`.

## Auth + profili

- Login/Signup:
  - `AuthRepository` in `lib/features/auth/data/auth_repository.dart` usa:
    - `auth.signUp(email, password, data: {nickname})`
    - `auth.signInWithPassword(email, password)`
- Tabella `profiles`:
  - L'app fa `upsert` su `profiles` con:
    - `id` (uguale a `auth.users.id`)
    - `email`
    - `nickname` (opzionale)
  - Nota: l'upsert avviene lato client dopo signup (solo se sessione creata subito) e dopo login.

## Tabelle usate dall'app (dai `from('...')` nel codice)

### `breeds`

Usata per selezionare razze in onboarding.

- Lettura: `lib/features/onboarding/data/repositories/breed_repository.dart`
  - select: `id, name, name_it`
  - order: `name`
- Import/aggiornamento: `tool/import_dog_breeds.dart`
  - upsert su `breeds` via REST: `POST {SUPABASE_URL}/rest/v1/breeds?on_conflict=name`
  - header `Authorization: Bearer {SUPABASE_SERVICE_ROLE}` (service role key)
  - header `Prefer: resolution=merge-duplicates`
  - campi upsertati: `name`, `name_it`, `image_url`

### `dogs`

Profilo cane associato all'utente.

- Lettura: `lib/features/home/data/dog_remote_repository.dart`
  - filtra per owner: `.eq('owner_id', userId)`
  - select include join: `breeds(name, name_it, image_url)` (relazione su `breed_id`)
- Upsert:
  - `lib/features/onboarding/data/repositories/dog_supabase_repository.dart`:
    - cerca esistente per `(owner_id, name)` e poi update/insert
  - `lib/features/home/data/dog_remote_repository.dart`:
    - insert / update / delete sempre scoping con `owner_id`

Campi visti nel payload:
- `owner_id`
- `name`
- `age_years`
- `weight_kg`
- `breed_id`
- (usato in query) `created_at`, `id`

### `quiz_results`

Risultato del quiz, eventualmente legato a un cane.

- Scrittura: `lib/features/quiz/data/datasources/quiz_remote_data_source.dart`
  - insert: `owner_id`, `dog_id` (opzionale), `score`, `risk_level`
  - select ritorno `id`
- Lettura (per Home): `lib/features/home/data/dog_remote_repository.dart`
  - select: `dog_id, risk_level, score`
  - filtra per owner: `.eq('owner_id', userId)`
  - order `created_at desc` e poi in memoria tiene il piu' recente per `dog_id`

### `quiz_answers`

Risposte dettagliate associate a un `quiz_results`.

- Scrittura: `lib/features/quiz/data/datasources/quiz_remote_data_source.dart`
  - insert multiplo per answers con:
    - `result_id` (FK verso `quiz_results.id`)
    - `question_id`
    - `answer_value`

## Relazioni (inferite dal codice)

- `dogs.breed_id -> breeds.id`
  - usata nella select `dogs ... breeds(name, name_it, image_url)`.
- `quiz_results.dog_id -> dogs.id` (opzionale)
- `quiz_answers.result_id -> quiz_results.id`
- `profiles.id -> auth.users.id` (pattern tipico + usato dall'app)

## “Automazioni” presenti nel repo

Nel codice non risultano Edge Functions, cron, trigger SQL o migration Supabase (cartella `supabase/` assente).

Automazione effettivamente presente:
- Script import razze: `tool/import_dog_breeds.dart`
  - Prende razze da TheDogAPI
  - Completa immagini mancanti
  - Traduce (LibreTranslate + overrides CSV `tool/dog_breeds_it.csv` se presente)
  - Upsert in `breeds` con service role

## Note di sicurezza (importanti da verificare in dashboard)

L'app filtra spesso per `owner_id = currentUser.id`, ma questo NON sostituisce RLS:
- Se RLS non e' abilitato o policy sono permissive, un client potrebbe leggere/scrivere dati di altri utenti.

Checklist rapida in Supabase:
- Database:
  - RLS `ON` su `dogs`, `quiz_results`, `quiz_answers`, `profiles`
  - Policy:
    - `owner_id = auth.uid()` per `dogs` e `quiz_results`
    - `quiz_answers` accessibile solo tramite join/ownership del relativo `quiz_results`
    - `profiles.id = auth.uid()` per select/update
- API keys:
  - service role key non deve stare nel client (qui e' usata solo dallo script tool).

