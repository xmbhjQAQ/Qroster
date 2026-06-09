# Prevent Missed Marking and Rename Sessions Design

## Product Model

Use `未记录` as a derived state:

- A session result exists -> the entry is `已记录` with that status label.
- No session result exists -> the entry is `未记录`.

This state should be computed from `entriesFor(rosterId)`, `resultsFor(sessionId)`, and `statusFor(...)`. It should not be stored as a normal user status option, because users should not be able to accidentally rename or remove the app's missing-data sentinel.

## Marking Page

The marking page should make accidental skips visible before and after they happen.

Header/progress area:

```text
12 / 32
已记录 12 · 未记录 20
```

Add a compact `未记录 {count}` action near the progress summary. Tapping it moves to the next entry without a result. If no unrecorded entries remain, it can be disabled or show a short snackbar.

Bottom action rules:

- Current entry has a status:
  - Forward button label: `下一个` or `完成`
  - Style: primary filled button
- Current entry has no status:
  - Forward button label: `跳过`
  - Style: tonal or warning-secondary treatment
  - First tap opens confirmation: `{姓名}还没有选择状态，确定跳过吗？`

Finish rules:

- If all entries are recorded, `完成` opens results normally.
- If unrecorded entries remain, show a dialog:
  - title: `还有 {count} 人未记录`
  - actions: `返回补录`, `查看结果`
  - `返回补录` jumps to the next unrecorded entry.
  - `查看结果` opens the result page.

## Result Page

Filter chips should be ordered:

```text
全部 | 未记录 | 到了 | 没到 | ...
```

When a filter is selected, keep the existing count pattern:

```text
数量: {amount}
```

For unrecorded rows:

- Show a visible `未记录` label or chip next to the status dropdown.
- Keep the dropdown available so users can fill missing statuses directly.

## Record History

Each history row should expose the state of that record:

```text
周二早读
已记录 29 · 未记录 3 · 2026-06-09 08:30
[编辑] [删除] [进入]
```

Interaction:

- Tap row: open result page.
- Edit icon: rename session.
- Delete icon: delete session after confirmation.
- Chevron remains a visual enter affordance.

Rename dialog:

- title: `重命名记录`
- input default: current session title
- empty input: show `记录名称不能为空`
- save: update `RosterSession.title` and `updatedAt`; keep `createdAt`.

## Session Creation

The record-time dialog should include an optional title field:

- label: `记录名称`
- hint: `默认使用所选时间`

If the field is empty, use the formatted selected time as the title. If present, use the trimmed custom title.

## Export

For single-session and all-history `.xlsx` exports:

- Write `未记录` instead of blank cells when no result exists.
- Summary sheet should count `未记录` in addition to user-defined statuses.
- Continue not adding `未记录` to roster status options.

## Compatibility

No storage migration is required. Existing sessions already have `title`, `createdAt`, and `updatedAt`; rename can use `copyWith`.
