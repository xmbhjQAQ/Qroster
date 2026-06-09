# Simplify Roster Model and Improve XLSX Export Implementation Plan

## Checklist

1. Simplify roster creation UI
   - Remove temporary/long-term segmented control.
   - Create rosters with a compatibility default internally.

2. Remove type-dependent UI behavior
   - Home cards stop showing `临时` / `长期`.
   - Home cards show `已记录 X 次` for every roster.
   - Roster detail always shows history/export actions independent of type.

3. Preserve data compatibility
   - Keep loading old `Roster.type` fields for now.
   - Avoid storage-breaking migration in this task.

4. Add record history deletion
   - Add controller method to delete one session and its results.
   - Add delete affordance in roster detail history rows.
   - Confirm before deleting.

5. Improve single-session `.xlsx`
   - Rename sheet to `记录`.
   - Add `序号`, `姓名`, `备注`, `状态`, `记录时间` columns.
   - Remove type metadata.

6. Improve all-history `.xlsx`
   - Rename sheet to `全部记录`.
   - Add `序号`, `姓名`, `备注`, session columns.
   - Remove type metadata.

7. Improve export save flow
   - Replace app-private default saving with a user-visible save/share flow.
   - Prefer a platform save picker when possible.
   - Keep Android behavior easy to locate from a file manager or target app.

8. Decide optional summary
   - If simple, add `统计` sheet with `记录`, `状态`, `数量`.
   - If it complicates API/tests, defer summary to a later task.

9. Verify
   - `flutter analyze`
   - `flutter test`
   - `flutter build apk --debug`

## Risk Areas

- Removing type from UI while keeping it in storage can create dead fields; keep
  comments/specs clear that it is compatibility-only.
- Export sheet names must stay short enough for Excel.
- Table format should remain simple and editable; avoid styling-heavy output
  that is harder to maintain.
