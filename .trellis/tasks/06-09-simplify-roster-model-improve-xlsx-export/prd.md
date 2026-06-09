# Simplify roster model and improve XLSX export

## Goal

Simplify Q名册 by removing the confusing temporary/long-term roster distinction and improve exported `.xlsx` files so they are easier to read, filter, and continue editing in Excel/WPS.

Current product direction: every roster should be one unified roster type. A roster can be used once or many times naturally based on how many sessions it has. Users should not need to decide "temporary vs long-term" when creating a roster.

## Requirements

- Roster model simplification:
  - Remove temporary/long-term choice from roster creation UI.
  - Existing rosters should continue to load even if stored data still contains the old `type` field.
  - All rosters support multiple sessions/history.
  - Home cards show usage based on behavior, such as `已记录 X 次`, instead of a type label.
  - Export and UI copy should not display "临时" or "长期".
- `.xlsx` export format improvement:
  - Replace generic `Sheet1` with meaningful sheet names.
  - Single-session export should be a directly usable table with clear columns.
  - All-history export should be a directly usable matrix with names as rows and sessions as columns.
  - Exported tables should include enough context to identify roster name, session time, and export time.
  - Exported tables should avoid unnecessary "type" metadata because roster type is being removed.
  - Prefer table-friendly columns that users can filter/sort in Excel/WPS.
- Proposed single-session columns:
  - `序号`
  - `姓名`
  - `备注`
  - `状态`
  - `记录时间`
- Proposed all-history columns:
  - `序号`
  - `姓名`
  - `备注`
  - one column per session, labeled by session time/title
- Optional lightweight summary:
  - Add a small status-count summary sheet or section only if it stays simple and does not become analytics/charts.

## Acceptance Criteria

- [ ] Roster creation no longer asks the user to choose temporary/long-term.
- [ ] Existing data with old roster `type` values still loads.
- [ ] Home cards no longer show `临时` / `长期`; they show entry count and `已记录 X 次`.
- [ ] Roster detail and export no longer depend on roster type.
- [ ] Single-session `.xlsx` export uses a meaningful sheet name and table columns: `序号`, `姓名`, `备注`, `状态`, `记录时间`.
- [ ] All-history `.xlsx` export uses a meaningful sheet name and removes old type metadata.
- [ ] Exported `.xlsx` files remain editable in Excel/WPS.
- [ ] `flutter analyze`, `flutter test`, and `flutter build apk --debug` pass after implementation.

## Out of Scope

- Charts.
- Attendance rate calculations.
- Cloud sync or cross-device history.
- User-defined arbitrary export templates.

## Notes

- Keep `prd.md` focused on requirements, constraints, and acceptance criteria.
- Lightweight tasks can remain PRD-only.
- For complex tasks, add `design.md` for technical design and `implement.md` for execution planning before `task.py start`.
