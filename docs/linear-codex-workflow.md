# Linear to Codex Workflow

Use this workflow for ArtrosiCane tasks that should be implemented by Codex and opened as a pull request to `main`.

## One-Time Setup

1. In Linear, keep tasks in the `ArtrosiCane` team (`ARTR`).
2. Connect Linear to GitHub and link the repository `TherHub-404/ArtrosiCane`.
3. Enable the Codex agent/app in Linear.
4. Delegate implementation issues to `Codex`.
5. Keep GitHub branch protection on `main` and require the `Flutter CI` check before merge.

## Task Template

```markdown
## Goal

What should change, in user/product terms?

## Scope

- In scope:
- Out of scope:

## Implementation Notes

- Relevant files/routes/screens:
- Edge cases:
- Supabase/env/migration changes:

## Acceptance Criteria

- [ ] 
- [ ] 
- [ ] 

## Validation

- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] Manual smoke test:
```

## Delegation Prompt

Add this as the final paragraph when you want Codex to pick up the issue:

```markdown
Codex: implement this issue in `TherHub-404/ArtrosiCane`, create a branch from `main`, run the validation checks, and open a pull request targeting `main`. Keep the PR scoped to this issue, link this Linear issue in the PR body, and move this Linear issue to `In Review` when the PR is ready. Do not move it to `Done`; a human reviewer will do that after review/merge.
```

## Expected Codex Loop

1. Read the Linear issue and comments.
2. Pull latest `main`.
3. Create the branch named by Linear, when available.
4. Implement the smallest complete change.
5. Run validation.
6. Push the branch.
7. Open a PR to `main`.
8. Move the Linear issue to `In Review`.
9. Comment on the Linear issue with the PR link and validation notes.
