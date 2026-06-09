# Prevent Missed Marking and Rename Sessions Implementation Plan

## Checklist

1. Add derived unrecorded helpers
   - Add controller helpers for recorded/unrecorded counts per session.
   - Add helper to find next unrecorded entry index for a roster/session.
   - Keep `未记录` as a UI/export sentinel, not a roster status option.

2. Improve marking flow
   - Show `已记录` / `未记录` counts under progress.
   - Add `未记录 {count}` jump action.
   - Change forward button to `跳过` when current entry has no status.
   - Confirm before skipping an unrecorded entry.
   - Confirm before finishing with remaining unrecorded entries.

3. Improve result page
   - Add `未记录` filter chip.
   - Include count display for `未记录`.
   - Show a visible `未记录` marker for rows without status.
   - Keep dropdown editing available for all rows.

4. Add session rename
   - Add controller method to update session title.
   - Add edit icon and rename dialog on history rows.
   - Validate non-empty title.
   - Preserve `createdAt`; update `updatedAt`.

5. Improve session creation
   - Add optional record title input to the record-time dialog.
   - Pass title to `createSession`.
   - Default to formatted selected time if the title is empty.

6. Update XLSX export
   - Write `未记录` for missing status cells.
   - Count `未记录` in the `统计` sheet.
   - Add regression tests for export behavior.

7. Update tests
   - Marking page skip confirmation.
   - Finish-with-unrecorded confirmation.
   - Result page `未记录` filter and count.
   - Session rename persistence.
   - XLSX missing statuses become `未记录`.

8. Verify
   - `flutter analyze`
   - `flutter test`
   - `flutter build apk --debug`

## Risk Areas

- Do not accidentally persist `未记录` as a normal status.
- Confirm dialogs should not block fast normal marking when users selected a status.
- Result filters must distinguish empty stored status from real user statuses.
- Export summary should include `未记录` without duplicating user statuses.
