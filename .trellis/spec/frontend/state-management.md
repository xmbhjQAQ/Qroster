# State Management

> How state is managed in this project.

---

## Overview

The current Flutter app uses `provider` plus `ChangeNotifier` for app-level
state. There is no server state in the MVP; all durable data is local.

`QrosterController` is the app-state owner. Screens should call controller
methods instead of mutating model lists directly.

---

## State Categories

- Local widget state: form fields, selected step/index, temporary import preview.
- App state: settings, rosters, entries, sessions, and session results.
- External/service state: LLM request/response and file import/export are
  handled by services, then normalized before app state changes.
- Server state: none in MVP.

---

## When to Use Global State

Use controller state when data must survive screen navigation, be persisted, or
be consumed by multiple screens. Keep transient UI editing state inside the
screen until the user saves.

---

## Server State

No cloud/server state is introduced for qroster MVP. LLM calls are client-side
requests for parsing only; their responses must be validated into
`ParsedRosterEntry` previews before saving.

---

## Common Mistakes

- Do not let UI widgets parse raw LLM JSON or spreadsheet cells.
- Do not rely on display names as identifiers; stable IDs preserve historical
  results when names are edited.
