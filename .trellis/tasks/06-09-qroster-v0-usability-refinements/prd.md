# Qroster v0 usability refinements

## Goal

Improve Q名册 v0 usability based on first manual testing without expanding the app into a full attendance analytics system. The refinement should make roster management reversible, import preview editable, long-term roster usage visible, and LLM parsing available for `.xlsx` imports.

This is a child task of `06-09-mobile-roster-attendance-app` and should preserve the existing offline-first Flutter architecture and OpenAI-compatible-only LLM boundary.

## Requirements

- Home roster list actions:
  - Each roster row/card can be swiped to reveal actions.
  - Actions include "置顶" with a grey/neutral visual treatment.
  - Actions include "删除" with a red/destructive visual treatment.
  - Deleting a roster requires confirmation.
  - Deleting a roster removes its entries, sessions, and results without affecting other rosters.
  - Pinning/top action moves that roster to the top of the home list.
- Import preview maintenance:
  - Users can delete a parsed preview item before saving the roster.
  - Editing a preview item with an empty display name must show a clear validation error.
  - Saving a roster with no valid preview entries must show a clear validation error.
- Long-term roster recording time and usage count:
  - When starting a recording session, users can set the session/statistics time.
  - The default session time is the device/system current time.
  - Long-term roster cards on the home screen show how many sessions have been recorded.
  - Wording should stay lightweight; suggested label: `已记录 X 次`.
- `.xlsx` plus LLM import:
  - After importing an `.xlsx`, users can run LLM parsing on spreadsheet-derived text.
  - Spreadsheet-derived content should be normalized to text before sending to the existing OpenAI-compatible parser.
  - Local fixed-format `.xlsx` import must continue working when LLM is disabled or unavailable.
- Result status filtering:
  - The result page should support quick filtering by status.
  - Users can tap a status such as "没到" to show only entries with that status.
  - Users can return to the full result list without leaving the page.
  - This is a lightweight filter, not an analytics/reporting feature.

## Acceptance Criteria

- [ ] Swiping a roster card reveals "置顶" and "删除" actions.
- [ ] "删除" asks for confirmation and removes the roster plus its scoped entries/sessions/results.
- [ ] "置顶" moves the roster to the top of the home list.
- [ ] Import preview rows can be deleted.
- [ ] Editing a preview row to an empty display name shows validation feedback and does not silently fail.
- [ ] Saving a roster with zero valid preview entries shows validation feedback.
- [ ] Starting a session offers a session time option defaulting to the current device time.
- [ ] Long-term roster cards show a lightweight usage-count label such as `已记录 X 次`.
- [ ] `.xlsx` import can feed spreadsheet-derived text into LLM parsing when LLM is configured.
- [ ] On the result page, tapping a status filter such as "没到" shows only entries with that status.
- [ ] The result page can return to showing all entries.
- [ ] `flutter analyze`, `flutter test`, and `flutter build apk --debug` pass after implementation.

## Out of Scope

- Complex analytics, charts, or attendance-rate reports.
- Multi-select batch deletion.
- Arbitrary custom fields beyond display name plus note.
- Non-OpenAI-compatible LLM protocols.

## Notes

- Keep `prd.md` focused on requirements, constraints, and acceptance criteria.
- Lightweight tasks can remain PRD-only.
- For complex tasks, add `design.md` for technical design and `implement.md` for execution planning before `task.py start`.
