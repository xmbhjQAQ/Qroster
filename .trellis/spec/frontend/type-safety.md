# Type Safety

> Type safety patterns in this project.

---

## Overview

Flutter/Dart model contracts live in `lib/src/models/`. External payloads from
local storage, spreadsheets, and LLM responses must be decoded at the boundary
and normalized before UI consumption.

---

## Type Organization

- Persistent app contracts: `app_settings.dart`, `app_data.dart`,
  `roster_models.dart`.
- Import preview contract: `parsed_roster_entry.dart`.
- UI-only form state stays local to screen classes.

---

## Validation

Use explicit `fromJson` constructors and service-level normalization. LLM output
must be treated as untrusted JSON and converted to valid `ParsedRosterEntry`
objects before display or persistence.

---

## Common Patterns

- Use enums for bounded values such as `RosterType`.
- Use stable string IDs for roster, entry, and session references.
- Keep default status constants in one model-level location.
- For OpenAI-compatible LLM settings, accept either a provider domain/base URL
  or a URL ending in `/v1`; the service normalizes requests to
  `/chat/completions`. UI fields must show examples so users do not have to
  guess the suffix.
- `.xlsx` content sent to LLM parsing must first be normalized into readable
  text rows such as `Sheet: ...` and `Row N: cell | cell`; never pass binary
  workbook bytes or UI-only table objects to the LLM boundary.

---

## Forbidden Patterns

- Do not scatter casts from raw JSON across screens.
- Do not use roster entry names as primary keys.
