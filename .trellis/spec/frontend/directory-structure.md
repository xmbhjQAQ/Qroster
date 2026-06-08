# Directory Structure

> How frontend code is organized in this project.

---

## Overview

The current app is a Flutter project named `qroster`. Frontend code lives under
`lib/src/` and is split by responsibility rather than by screen-only folders.
UI code must not parse raw storage, spreadsheet, or LLM payloads directly.

---

## Directory Layout

```
lib/
├── main.dart
└── src/
    ├── app/        # MaterialApp, theme, top-level routing decisions
    ├── models/     # Serializable app contracts and parsed import DTOs
    ├── services/   # Import, LLM, and XLSX export boundaries
    ├── state/      # ChangeNotifier controllers / app orchestration
    ├── storage/    # Local persistence adapters
    └── ui/         # Screens and reusable widgets

assets/
└── svg/            # Repo-owned SVG identity and state/action assets
```

---

## Module Organization

- Put cross-screen app orchestration in `lib/src/state/`.
- Put any external format boundary in `lib/src/services/`.
- Put serializable data contracts in `lib/src/models/`.
- Put Flutter widgets and screens in `lib/src/ui/`.
- Shared visual widgets belong in `lib/src/ui/widgets/`.

---

## Naming Conventions

- Use `snake_case.dart` file names.
- Name screens with the `_screen.dart` suffix.
- Keep generated/repo-owned visual assets under `assets/svg/` and register the
  folder in `pubspec.yaml`.

---

## Examples

- `lib/src/state/qroster_controller.dart` owns roster/session state transitions.
- `lib/src/services/import_service.dart` owns local text and `.xlsx` parsing.
- `lib/src/services/llm_import_service.dart` owns OpenAI-compatible parsing.
- `lib/src/services/xlsx_export_service.dart` owns `.xlsx` output.
