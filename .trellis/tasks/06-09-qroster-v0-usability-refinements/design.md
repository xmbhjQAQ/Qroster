# Qroster v0 Usability Refinements Design

## Scope

This task tightens the existing v0 Flutter app. It does not introduce a backend,
cloud sync, analytics dashboards, CSV export, or new LLM provider protocols.

## Roster List Actions

Use a swipe action pattern on home roster cards:

- `置顶`: neutral/grey action, moves roster to index 0.
- `删除`: red destructive action, opens a confirmation dialog.

The controller owns the actual operations:

- `pinRoster(rosterId)`
- `deleteRoster(rosterId)`

`deleteRoster` must delete only records scoped to that roster:

- roster metadata
- entries for roster
- sessions for roster
- results whose session belongs to roster

## Import Preview

Import preview remains local screen state until saved. Each preview row gains:

- edit action
- delete action

Validation behavior:

- Editing a preview item with an empty display name keeps the dialog open and
  shows an error.
- Saving a roster requires at least one valid preview item.

## Session Time

Starting a session opens a lightweight dialog before creating the session.

Default:

- session time = `DateTime.now()` from device/system time
- title defaults to formatted session time

User options:

- accept current time immediately
- pick/change date/time before starting

Implementation can keep the persisted session shape unchanged by setting
`RosterSession.title`, `createdAt`, and `updatedAt` from the selected time.

## Long-Term Usage Count

Home roster cards should remain compact. For long-term rosters, append a short
usage count based on session count:

```text
长期 · 32 人 · 已记录 5 次 · 2026-06-09 10:30
```

For temporary rosters, keep the existing compact metadata unless a session count
is useful.

## `.xlsx` LLM Parsing

The existing local spreadsheet parser normalizes `.xlsx` rows into
`ParsedRosterEntry`. For LLM parsing, add a second contract:

```text
spreadsheet bytes -> plain text representation -> LLM parser -> preview rows
```

The text representation should include row/column values in a readable format,
not raw binary or workbook internals. Local fixed-format `.xlsx` import remains
available regardless of LLM state.

## Result Status Filtering

The result page should expose the roster's status options as filter chips above
the result list:

- `全部`
- one chip per roster status, such as `到了`, `没到`, `迟到`, `请假`

Selecting a status filters the visible rows to entries with that exact status.
Entries without a status should appear only under `全部` unless an explicit
unmarked filter is added later.

When a status filter is active, show a separate count label near the filters:

```text
数量: 3
```

This task does not add charts or summary analytics.
