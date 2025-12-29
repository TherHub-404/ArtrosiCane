# artrosi_cane

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Supabase
Create a `.env` file from `.env.example` and set your Supabase project values:
```
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
```
The `.env` file is loaded at startup and used to initialize `supabase_flutter`.

## Razze (import da TheDogAPI)
- Richiede variabili d'ambiente: `DOG_API_KEY`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE` (quest'ultima si trova in Supabase Settings → API).
- Esegui: `dart tool/import_dog_breeds.dart`
- Lo script scarica le razze da TheDogAPI e le upsert nella tabella `breeds` (on_conflict=name).
