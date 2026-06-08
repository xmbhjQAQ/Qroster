# Qroster v0 Usability Refinements Implementation Plan

## Checklist

1. Add roster operations to `QrosterController`
   - `pinRoster`
   - `deleteRoster`
   - session count helper
   - optional session time support in `createSession`

2. Update home roster cards
   - Add swipe actions for "置顶" and "删除".
   - Confirm before deletion.
   - Show `已记录 X 次` for long-term rosters.

3. Improve import preview
   - Add delete action per preview item.
   - Add validation in preview edit dialog.
   - Block save with no valid entries and show feedback.

4. Add session time dialog
   - Show before starting a session.
   - Default to current device time.
   - Allow date/time adjustment.

5. Add `.xlsx` text extraction for LLM
   - Store last spreadsheet-derived text in the roster editor.
   - Allow LLM parsing from `.xlsx` content when configured.
   - Keep fixed local `.xlsx` parser path.

6. Add result-page status filters
   - Add `全部` plus one chip per roster status.
   - Filter visible entries by selected status.
   - When a non-`全部` filter is active, show `数量: {amount}` for visible rows.
   - Keep status editing available on filtered rows.

7. Verify
   - `flutter analyze`
   - `flutter test`
   - `flutter build apk --debug`

## Risk Areas

- Swipe action package choice can affect Android build; prefer a small,
  actively maintained Flutter package or a simple built-in implementation.
- Deletion must clean results by session IDs, not by entry IDs alone.
- `.xlsx` LLM parsing must never send binary data; only normalized text.
- Session time selection should not add analytics/reporting scope.
