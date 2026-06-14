# Quality Guidelines

> Code quality standards for frontend development.

---

## Overview

Run Flutter linting, tests, and a Windows build/run check for milestones that
touch the desktop app. Because Roosty depends on `super_clipboard`, Windows
builds pull in `super_native_extensions` and its native build scripts.

---

## Forbidden Patterns

- Do not commit debug logs, suppressed analyzer warnings, or generated run logs.
- Do not hardcode LLM API keys.
- Do not change the M0 interface signatures (`Source`, `Item`, `Fetcher`,
  `Processor`, `Sink`) without updating `ROADMAP.md` and the active PRD.
- Do not treat a non-ASCII Windows workspace path build failure as an app-code
  failure before reproducing from an ASCII path.

---

## Required Patterns

- Run `flutter pub get`, `flutter analyze`, and `flutter test` after dependency
  or Dart changes.
- For Windows native build/run verification from a workspace path containing
  non-ASCII characters, use an ASCII junction to the same repository, for
  example:

  ```powershell
  New-Item -ItemType Junction -Path C:\roosty-build -Target <repo-path>
  Set-Location C:\roosty-build
  flutter build windows
  flutter run -d windows
  ```

  `super_native_extensions` generates a temporary Dart `pubspec.yaml` during
  Windows builds. In a non-ASCII path, the generated path can be written in the
  wrong code page and Dart fails to decode or resolve `package:build_tool`.

---

## Testing Requirements

- Add focused unit/widget tests for new behavior.
- Config persistence changes need tests for defaults and saved values.
- Pipeline item mutations need tests for mutable fields such as tags.

---

## Code Review Checklist

- Linter passes.
- Tests pass.
- Windows build/run result is recorded, including whether an ASCII junction was
  required.
- No brand-forbidden copy or imagery is introduced into app code.
