# Prevent missed marking and rename sessions

## Goal

Improve Q名册 record flow by surfacing unrecorded entries, preventing accidental skips, allowing session rename, and keeping interactions consistent across marking, result, history, and export.

## Requirements

- Prevent accidental skipped entries during marking:
  - If the current entry has no selected status, the primary forward action should communicate that it is a skip, not a normal "next" action.
  - Users should get a lightweight confirmation before intentionally skipping an unrecorded entry.
  - Finishing a session with unrecorded entries should warn the user and offer a direct way to return and complete missing entries.
  - Users should be able to jump to the next unrecorded entry during marking.
- Surface unrecorded entries consistently:
  - Treat missing session results as a derived `未记录` state in UI, exports, and counts.
  - Do not add `未记录` to user-defined roster status options.
  - Result filters should include `未记录` and show the count the same way other status filters do.
  - Exports should write `未记录` instead of blank status cells.
- Improve record history management:
  - Session history entries can be renamed.
  - Session rename changes the display title and `updatedAt`, but preserves the original `createdAt` record time.
  - Starting a session may optionally accept a custom session title; if omitted, it continues using the selected record time as the title.
- Keep interaction style consistent:
  - Marking page, result page, and history rows should use the same concepts and wording: `已记录`, `未记录`, `记录`.
  - Destructive actions require confirmation and use error styling.
  - Corrective actions such as jumping to unrecorded entries should be obvious but not visually louder than primary status selection.

## Acceptance Criteria

- [ ] Marking page shows both current position and counts for `已记录` / `未记录`.
- [ ] On an unrecorded current entry, the forward button says `跳过` and uses a weaker/warning treatment.
- [ ] Tapping `跳过` on an unrecorded current entry asks for confirmation before moving forward.
- [ ] Tapping `完成` with remaining unrecorded entries asks whether to return for completion or view results.
- [ ] Marking page provides a direct action to jump to the next unrecorded entry.
- [ ] Result page includes a `未记录` filter chip and displays `数量: {amount}` when selected.
- [ ] Result page allows users to assign statuses to unrecorded entries from the filtered list.
- [ ] Record history rows show `已记录 X · 未记录 Y · {record time}`.
- [ ] Record history rows expose rename and delete actions with consistent icon-button styling.
- [ ] Renaming a session rejects empty names and persists the new title.
- [ ] Starting a session supports an optional custom title, defaulting to the selected time if empty.
- [ ] Single-session and all-history `.xlsx` exports write `未记录` for entries without results.
- [ ] `flutter analyze`, `flutter test`, and `flutter build apk --debug` pass after implementation.

## Out of Scope

- Attendance rate calculations.
- Charts or analytics dashboards.
- Arbitrary per-session templates.
- Adding `未记录` as a user-editable status option.

## Notes

- Keep `prd.md` focused on requirements, constraints, and acceptance criteria.
- Lightweight tasks can remain PRD-only.
- For complex tasks, add `design.md` for technical design and `implement.md` for execution planning before `task.py start`.
