# Quality Guidelines

> Code quality standards for frontend development.

---

## Overview

Flutter changes should pass static analysis, widget/unit tests, and at least one
target-platform build when platform tooling is available.

---

## Forbidden Patterns

- Do not hard-code roster status behavior outside the roster model/controller.
- Do not write raw external payload parsing in screens.
- Do not leave default Flutter app identity assets as the only visible identity
  for qroster.
- Do not create `TextEditingController`s for a `showDialog` input in the caller
  and dispose them immediately after `await showDialog`. Flutter may still have
  inherited dependencies attached while the dialog route is unwinding, which can
  trigger `_dependents.isEmpty` assertions. Prefer `TextFormField(initialValue:
  ...)` with local draft variables, or a dedicated dialog `StatefulWidget` that
  owns and disposes its controllers.

---

## Required Patterns

- Run `flutter analyze` after code changes.
- Run `flutter test` after behavior or UI changes.
- For mobile-facing changes, run `flutter build apk --debug` when Android
  tooling is available.
- Keep import/export contracts behind service classes.

---

## Testing Requirements

At minimum, add widget or unit tests for new app entry states and pure parsing /
normalization behavior. Broaden tests when changing model persistence,
import/export contracts, or marking state transitions.

---

## Code Review Checklist

- Cross-layer data flow: external input -> service validation -> preview/model
  -> controller persistence -> UI.
- Offline behavior remains intact when LLM is disabled/unavailable.
- `.xlsx` export remains the only MVP spreadsheet output.
