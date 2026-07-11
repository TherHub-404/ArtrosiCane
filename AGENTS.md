# Codex Instructions

## Project

ArtrosiCane is a Flutter app backed by Supabase. The default target branch is `main`.

## Workflow

- Start from the Linear issue identifier, for example `ARTR-12`.
- Create a branch from `main` using Linear's branch name when available, otherwise use `codex/artr-12-short-title`.
- Keep changes scoped to the Linear task.
- Do not commit secrets or local `.env` values.
- Link the Linear issue in the PR title or body.
- When work is ready for human review, move the Linear issue to `In Review`, not `Done`.
- Only a human reviewer should move the issue to `Done` after checking and merging the PR.

## Validation

Run the relevant checks before opening a PR:

```bash
flutter pub get
flutter analyze
flutter test
```

For UI work, also run the app on the relevant target when practical:

```bash
flutter run -d chrome
```

## Repo Notes

- Use package imports for files under `lib/`.
- Prefer existing feature folder structure under `lib/features/`.
- Keep localized/user-facing text aligned with the existing localization approach in `lib/l10n/`.
- If a task touches Supabase behavior, call out any required database or environment changes in the PR body.
