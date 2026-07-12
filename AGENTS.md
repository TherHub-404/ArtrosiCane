# AGENTS.md

## 1. Project Overview

**ArtrosiCane** is a Flutter application backed by Supabase.

* Default branch: `main`
* Issue tracker: Linear
* Source control: GitHub
* Primary issue prefix: `ARTR`
* Application code: `lib/`
* Tests: `test/`

The goal of every change is to produce code that is readable, maintainable, testable, secure, and consistent with the existing project architecture.

---

## 2. Instruction Priority

When instructions conflict, follow this order:

1. Security and data-safety requirements
2. The current Linear issue
3. This `AGENTS.md` file
4. Existing repository conventions
5. General Flutter and Dart best practices

Do not introduce unrelated refactors unless they are necessary to complete the issue safely.

---

## 3. Task Intake

Every implementation must start from a Linear issue, for example:

```text
ARTR-12
```

Before changing code:

1. Read the full Linear issue.
2. Identify the expected behavior and acceptance criteria.
3. Inspect the relevant existing implementation.
4. Determine which files and features are affected.
5. Note any unclear requirements or external dependencies.
6. Keep the implementation scoped to the issue.

Do not begin broad architectural changes based only on assumptions.

---

## 4. Branch Workflow

Before creating a branch, verify that the checkout can push to the real
GitHub repository. Codex coding sessions may start on a temporary `work`
branch without a configured remote; fix that before coding.

```bash
git remote -v
git remote get-url origin >/dev/null 2>&1 || git remote add origin https://github.com/TherHub-404/ArtrosiCane.git
git fetch origin main
```

If a local `main` branch is missing, create or reset the working branch from
`origin/main` instead of stopping only because `main` is unavailable locally.

Create a new branch from the latest `origin/main`.

Use Linear's suggested branch name when available.

Otherwise, use:

```text
codex/artr-12-short-title
```

Branch names must:

* Include the Linear issue identifier.
* Use lowercase words separated by hyphens.
* Describe the task briefly.
* Avoid personal names or vague terms such as `fix`, `changes`, or `update`.

Examples:

```text
codex/artr-12-add-dog-profile
codex/artr-18-fix-login-validation
codex/artr-25-improve-medication-reminders
```

Never work directly on `main`.

At the end of the task, the branch must be pushed to GitHub:

```bash
git push -u origin <branch-name>
```

If the push fails, report the exact Git error and do not claim the work is
ready for review.

---

## 5. Scope Management

Keep every change focused on the Linear task.

Allowed changes include:

* The requested feature or bug fix.
* Tests required to validate the change.
* Small supporting refactors needed to implement the task safely.
* Documentation directly related to the change.

Avoid:

* Unrelated formatting changes.
* Renaming unrelated files or symbols.
* Reorganizing entire features without a task requirement.
* Adding dependencies when an existing solution is sufficient.
* Changing public interfaces without a clear reason.
* Mixing several unrelated fixes in one pull request.

When a larger refactor is needed, explain it in the pull request.

---

## 6. Flutter Architecture

Follow the existing feature-based structure under:

```text
lib/features/
```

Prefer organizing each feature by responsibility:

```text
lib/
  core/
    constants/
    errors/
    extensions/
    routing/
    services/
    theme/
    utils/

  features/
    feature_name/
      data/
        datasources/
        models/
        repositories/
      domain/
        entities/
        repositories/
        use_cases/
      presentation/
        controllers/
        pages/
        widgets/

  l10n/
  main.dart
```

Use the existing project structure when it differs from this example. Do not create architectural layers that the project does not currently need.

### Responsibilities

#### Presentation

Contains:

* Pages and screens
* Widgets
* UI state
* User interaction handling
* Presentation controllers or providers

Presentation code should not contain direct Supabase queries or complex business rules.

#### Domain

Contains:

* Business entities
* Repository contracts
* Use cases
* Business rules

Domain code should remain independent from Flutter widgets and Supabase implementation details when practical.

#### Data

Contains:

* Supabase access
* Remote and local data sources
* Data-transfer models
* Repository implementations
* Serialization and mapping

Do not expose raw Supabase response objects throughout the application.

---

## 7. Code Quality Standards

### Readability

Code should be understandable without requiring excessive comments.

Prefer:

* Clear names
* Small focused functions
* Explicit control flow
* Early returns
* Immutable values
* Single-purpose classes
* Consistent abstractions

Avoid:

* Deep nesting
* Very long methods
* Generic names such as `data`, `item`, `temp`, or `value`
* Boolean parameters with unclear meaning
* Hidden side effects
* Duplicate business logic
* Large widgets containing unrelated responsibilities

Example:

```dart
final isEligibleForReminder =
    treatment.isActive && treatment.nextDoseAt != null;
```

Prefer this over repeating the full condition in several places.

### Naming

Use Dart naming conventions:

* Classes and enums: `PascalCase`
* Variables and methods: `camelCase`
* Files and directories: `snake_case`
* Private members: `_camelCase`
* Constants: follow the existing project convention

Names should describe intent rather than implementation details.

Prefer:

```dart
loadDogProfile()
isMedicationOverdue
treatmentRepository
```

Avoid:

```dart
getData()
flag
helper
manager
doStuff()
```

### Functions

A function should perform one clear task.

Prefer:

* Fewer parameters
* Named parameters for clarity
* Explicit return types
* Early validation
* Extracted business rules

Avoid methods that fetch data, transform it, update UI state, display errors, and navigate at the same time.

### Classes and Widgets

Extract a widget when:

* It has a distinct responsibility.
* It is reusable.
* It has meaningful internal logic.
* It improves the readability of the parent widget.
* It can be tested independently.

Do not extract trivial widgets only to reduce line count.

### Comments

Comments should explain:

* Why a decision was made.
* A non-obvious constraint.
* A workaround.
* An important business rule.

Do not write comments that merely repeat the code.

Prefer:

```dart
// Supabase may return duplicate treatment rows while a retry is pending.
// Deduplicate by treatment ID before updating the UI.
```

Avoid:

```dart
// Loop through treatments.
for (final treatment in treatments) {
```

Remove outdated comments when behavior changes.

---

## 8. Imports

Use package imports for files under `lib/`.

Prefer:

```dart
import 'package:artrosi_cane/features/profile/domain/entities/dog.dart';
```

Avoid:

```dart
import '../../../domain/entities/dog.dart';
```

Import order should follow the repository's formatter and lint rules.

Remove unused imports before committing.

---

## 9. State Management

Follow the state-management approach already used by the project.

State classes should:

* Represent loading, success, empty, and error states clearly.
* Avoid exposing mutable collections.
* Keep business rules outside widgets.
* Avoid triggering side effects during widget builds.
* Prevent stale asynchronous responses from overwriting newer state when relevant.

Do not introduce a second state-management library without explicit architectural approval.

---

## 10. Error Handling

Handle expected failures explicitly.

Examples include:

* Network failures
* Authentication failures
* Missing Supabase rows
* Invalid user input
* Permission errors
* Serialization failures

User-facing errors should:

* Be understandable.
* Avoid exposing internal implementation details.
* Follow the localization system.
* Suggest a useful next action when possible.

Avoid empty catch blocks.

```dart
try {
  await repository.saveTreatment(treatment);
} on TreatmentValidationException catch (error) {
  emit(TreatmentState.invalid(error.message));
} catch (error, stackTrace) {
  logger.error(
    'Unable to save treatment',
    error: error,
    stackTrace: stackTrace,
  );

  emit(const TreatmentState.failure());
}
```

Do not silently ignore unexpected errors.

---

## 11. Asynchronous Code

Use `async` and `await` consistently.

When implementing asynchronous behavior:

* Handle loading and error states.
* Check widget lifecycle before using `BuildContext` after an async gap.
* Avoid unawaited futures unless intentional and documented.
* Prevent duplicate submissions.
* Cancel or ignore stale requests where appropriate.
* Avoid sequential requests when independent operations can safely run in parallel.

Example:

```dart
if (!context.mounted) {
  return;
}

Navigator.of(context).pop();
```

---

## 12. Models and Data Mapping

Keep transport models separate from domain entities when their responsibilities differ.

Data models should handle:

* JSON parsing
* Supabase column names
* Nullability from external data
* Serialization

Domain entities should represent valid application concepts.

Prefer explicit mapping:

```dart
Dog toEntity() {
  return Dog(
    id: id,
    name: name,
    birthDate: birthDate,
  );
}
```

Do not spread raw `Map<String, dynamic>` values throughout the codebase.

Validate external data at system boundaries.

---

## 13. Supabase Guidelines

Supabase access should be isolated inside the data layer or the project's existing service abstraction.

Do not:

* Query Supabase directly from widgets.
* Commit Supabase service-role keys.
* Commit local `.env` files.
* Log authentication tokens or personal data.
* Trust client-provided ownership identifiers without database enforcement.
* assume Row Level Security is configured correctly without checking the relevant migration or policy.

When changing Supabase behavior, document in the pull request:

* Tables affected
* Columns added or changed
* Required migrations
* Row Level Security changes
* Storage policy changes
* Edge Function changes
* Required environment variables
* Backfill or deployment steps

Database changes should be reproducible through migrations whenever the repository supports them.

---

## 14. Security and Privacy

Never commit:

* Passwords
* API secrets
* Supabase service-role keys
* Access tokens
* Private certificates
* Production credentials
* Local `.env` values
* Personal or medical test data

Use synthetic test data.

Before logging values, consider whether they contain:

* User identifiers
* Email addresses
* Medical information
* Authentication tokens
* Device identifiers
* Private file URLs

Log only what is required for diagnosis.

---

## 15. Localization

All user-facing text must follow the localization approach under:

```text
lib/l10n/
```

Do not hardcode user-facing strings in widgets unless the existing project explicitly permits it.

When adding text:

1. Add the localization key.
2. Add translations required by the project.
3. Use clear and stable key names.
4. Regenerate localization files when required.
5. Verify interpolation and pluralization.

Avoid constructing sentences by concatenating translated fragments.

---

## 16. Accessibility and UI Quality

For UI changes:

* Use semantic labels when visual meaning is not obvious.
* Ensure buttons have understandable labels.
* Support text scaling.
* Avoid fixed heights for text-heavy content.
* Maintain adequate touch-target sizes.
* Handle loading, empty, error, and success states.
* Avoid relying only on color to communicate meaning.
* Test overflow with long localized strings.
* Follow the existing theme instead of hardcoding visual values.

Use shared theme values and components when available.

---

## 17. Performance

Optimize only when there is a meaningful reason, but avoid obvious inefficiencies.

Check for:

* Unnecessary widget rebuilds
* Large lists rendered without lazy builders
* Duplicate network requests
* Expensive work inside `build`
* Repeated parsing or mapping
* Images loaded at unnecessarily high resolution
* Database queries returning unused columns
* Missing pagination for potentially large datasets

Prefer readable code over premature micro-optimizations.

Document non-obvious performance decisions.

---

## 18. Dependencies

Before adding a package:

1. Confirm the project does not already provide the capability.
2. Check whether a small internal implementation is more appropriate.
3. Verify compatibility with the current Flutter and Dart versions.
4. Prefer actively maintained packages.
5. Avoid packages with unnecessarily broad scope.
6. Explain the dependency in the pull request.

Do not upgrade unrelated dependencies as part of a feature task.

---

## 19. Testing

Add or update tests for changed behavior.

Use the appropriate test type:

### Unit tests

Use for:

* Business rules
* Data mapping
* Validation
* Use cases
* Repository behavior with mocked dependencies
* State controllers

### Widget tests

Use for:

* Rendering
* User interaction
* Loading, error, and empty states
* Form validation
* Navigation triggers
* Important accessibility behavior

### Integration tests

Use for critical end-to-end workflows when the repository supports them.

Tests should:

* Describe observable behavior.
* Avoid depending on execution order.
* Use deterministic inputs.
* Avoid real production services.
* Cover failure paths where relevant.
* Remain readable and focused.

Use descriptive test names:

```dart
test(
  'returns overdue treatments when the next dose is before the current time',
  () async {
    // ...
  },
);
```

Avoid tests that only verify implementation details.

---

## 20. Required Validation

Before opening a pull request, run:

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

For UI work, also run the application on the relevant target when practical:

```bash
flutter run -d chrome
```

Run additional checks required by the repository, such as:

```bash
flutter test integration_test
```

Do not claim that a command passed unless it was actually run.

If a validation step cannot be completed, include:

* The command that was not run
* The reason
* Any alternative validation performed
* The expected reviewer action

---

## 21. Generated Files

Do not manually edit generated files unless the repository explicitly requires it.

Examples include:

* Localization output
* Code-generation output
* Serialization files
* Dependency lockfiles generated by tooling

When generated code changes:

* Run the correct generator.
* Include all required generated output.
* Avoid unrelated generated changes.
* Mention the generator command in the pull request when useful.

---

## 22. Git Commit Standards

Create focused commits with meaningful messages.

Preferred format:

```text
ARTR-12 Add dog profile validation
```

Examples:

```text
ARTR-12 Add dog profile form
ARTR-12 Validate required profile fields
ARTR-12 Add profile widget tests
```

Avoid messages such as:

```text
fix
update
changes
wip
final
```

Do not commit:

* Secrets
* Local environment files
* IDE-specific files not used by the team
* Debug output
* Temporary scripts
* Unrelated generated files

Before committing, inspect:

```bash
git status
git diff
git diff --staged
```

---

## 23. Pull Request Requirements

When the work is ready for human review:

1. Push the branch.
2. Do not open a pull request manually.
3. GitHub Actions will automatically open the pull request from pushed
   `codex/artr-*` or `*ARTR-*` branches.
4. GitHub Actions will link the Linear issue and move it to `In Review`.

Do not move the issue to `In Review` yourself. If GitHub Actions cannot open a
pull request, leave the issue in its current state and report the blocker.

A pull request should include:

```markdown
## Linear Issue

ARTR-12

## Summary

- Describe the main change.
- Describe important supporting changes.

## Implementation

Explain the relevant technical decisions.

## Validation

- [x] `flutter pub get`
- [x] `dart format --set-exit-if-changed .`
- [x] `flutter analyze`
- [x] `flutter test`
- [ ] `flutter run -d chrome`

## Screenshots

Include before-and-after screenshots for visible UI changes.

## Supabase Changes

Describe migrations, policies, environment variables, storage changes, or state that none are required.

## Risks and Follow-up

Describe known limitations, migration concerns, deferred work, or reviewer focus areas.
```

The PR title should include the Linear issue identifier:

```text
ARTR-12: Add dog profile management
```

---

## 24. Linear Status Workflow

Use the following workflow:

```text
Todo → In Progress → In Review → Done
```

Rules:

* Move the issue to `In Progress` when implementation begins, if appropriate.
* Do not move it to `In Review` manually; GitHub Actions handles that after a real PR exists.
* Do not add a PR URL manually unless the automation fails and a human asks you to.
* Only a human reviewer should move the issue to `Done`.
* Do not mark work complete based only on local changes.

---

## 25. Blockers and Partial Completion

If blocked:

1. Do not invent missing credentials or requirements.
2. Do not bypass validation or security controls.
3. Keep the Linear issue in its current appropriate state.
4. Clearly report:

   * What was completed
   * What remains
   * The exact blocker
   * What access or decision is needed
   * Whether any branch or pull request was created

If the branch cannot be pushed, do not move the Linear issue to `In Review`.

---

## 26. Definition of Ready for Review

Work is ready for review only when:

* The Linear acceptance criteria are satisfied.
* The implementation is scoped to the issue.
* Code follows existing project architecture.
* User-facing text is localized.
* Error and loading states are handled.
* Relevant tests are added or updated.
* Formatting passes.
* Static analysis passes.
* Tests pass.
* No secrets or local configuration are committed.
* Supabase implications are documented.
* The branch is pushed.
* GitHub Actions is able to create the pull request and update Linear.

---

## 27. Definition of Done

The agent must not mark an issue as `Done`.

An issue is considered done only after a human reviewer has:

* Reviewed the implementation.
* Approved the pull request.
* Confirmed the required checks.
* Merged the pull request.
* Moved the Linear issue to `Done`.

---

## 28. Final Agent Report

At the end of a task, report:

```markdown
## Completed

- Summary of implemented changes

## Validation

- Commands run and their results

## Pull Request

- Branch pushed to GitHub
- PR URL if GitHub Actions already created it

## Linear

- Current issue status
- Whether GitHub Actions updated the issue

## Notes

- Supabase or environment changes
- Known limitations
- Follow-up work
