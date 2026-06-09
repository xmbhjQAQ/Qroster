# Simplify Roster Model and Improve XLSX Export Design

## Product Decision

Use one roster type only. A roster becomes "single-use" or "reused" by behavior:

- zero sessions: `尚未记录`
- one session: one-off use works naturally
- multiple sessions: repeated-use roster works naturally

This removes a low-value decision from roster creation and avoids unclear
temporary/long-term semantics.

## Data Compatibility

Existing persisted `Roster.type` fields may remain in local storage. The first
implementation can keep the field in the model for backward compatibility while
removing it from UI and export logic. A later storage migration can remove the
field once the local data format is formalized.

Compatibility rule:

- read old `temporary` / `longTerm` values without error
- do not show the distinction to users
- do not write copy that depends on the distinction

## UI Changes

- Roster creation screen removes the segmented `临时 / 长期` selector.
- Home metadata becomes:

```text
32 人 · 已记录 5 次 · 2026-06-09 10:30
```

- Roster detail keeps session history and export actions available for every
  roster.

## XLSX Export Format

Current export writes all content into generic `Sheet1` and mixes metadata rows
with the data table. The improved format should favor editable/filterable
tables.

### Single Session

Sheet name: `记录`

Rows:

1. Optional context rows:
   - `花名册`: roster name
   - `记录时间`: session title/time
   - `导出时间`: export time
2. Blank separator row
3. Table header:
   - `序号`
   - `姓名`
   - `备注`
   - `状态`
   - `记录时间`

Each entry row repeats the session time so the table remains meaningful if the
metadata rows are removed by the user.

### All History

Sheet name: `全部记录`

Rows:

1. Optional context rows:
   - `花名册`: roster name
   - `导出时间`: export time
2. Blank separator row
3. Table header:
   - `序号`
   - `姓名`
   - `备注`
   - one column per session title/time

No old `类型` row should be exported.

### Optional Summary

If implemented, keep summary lightweight:

- Sheet name: `统计`
- Columns: `记录`, `状态`, `数量`

No charts or rate calculations.
