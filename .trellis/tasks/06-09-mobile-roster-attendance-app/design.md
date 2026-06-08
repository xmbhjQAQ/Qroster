# Q名册 / qroster Technical Design

## Architecture

qroster is a greenfield Flutter app. The MVP is an offline-first local utility with no backend, no account system, and no cloud sync.

The app is organized around rosters. A roster is an isolated local workspace containing:

- metadata: id, name, type, created/updated timestamps
- status options scoped to that roster
- entries scoped to that roster
- marking sessions/results scoped to that roster

The first release should prioritize Android/mobile ergonomics while keeping Flutter structure portable to other platforms.

## UX Structure

### First Launch

First launch offers a skippable onboarding flow.

If the user enters onboarding:

1. LLM setup
   - Choose enable or disable.
   - Enabled: configure OpenAI-compatible Base URL, API Key, and Model.
   - Disabled: imports are constrained to fixed supported local formats.
2. First roster setup
   - Set roster name and temporary/long-term mode.
   - Review default statuses: "到了", "没到", "迟到", "请假".
   - Import entries from text, spreadsheet, or LLM-assisted parsing.
   - Review/edit imported entries before saving.

If the user skips onboarding, the app opens the home roster list/empty state. LLM configuration and roster creation remain available later.

### Home

Home is the main work surface:

- roster count/overview
- roster cards showing name, temporary/long-term type, entry count, and latest record time/status
- top-left menu button
- left-to-right overlay drawer covering about half the screen
- small bottom-left floating action button to create a roster

The drawer contains secondary/global functions such as settings, LLM configuration, and long-term/global configuration controls. Primary roster work stays on home and roster detail screens.

### Roster Detail

Roster detail owns:

- entry list
- status option editing
- session history
- import/update roster actions
- start marking session
- export actions

### Marking Flow

The marking screen shows one entry at a time:

- display name is the primary visual focus
- optional note/additional info appears as supporting text
- status buttons use large touch targets
- previous/next controls allow correction
- progress is visible

### Result Table

The result table allows editing before export:

- entry display name
- optional note/additional info
- status for the selected session
- export selected session

For long-term rosters, export all history creates a multi-column `.xlsx`: entries as rows, sessions as columns.

## Visual Direction

Use lightweight utility UI with soft Material 3 styling:

- calm neutral surfaces
- restrained accent color
- compact but touch-friendly spacing
- no marketing-style hero screen
- no dense backend-dashboard layout
- status choices should be visually distinct without becoming noisy

Use repo-owned SVG assets for:

- app identity/icon
- empty home state
- import/parse state
- export action
- settings/LLM affordance

Flutter should load SVG assets through a normal asset pipeline, likely `flutter_svg`.

## Data Model

Suggested logical models:

- `AppSettings`
  - `onboardingCompleted`
  - `llmEnabled`
  - `llmBaseUrl`
  - `llmApiKey`
  - `llmModel`
- `Roster`
  - `id`
  - `name`
  - `type`: `temporary` or `longTerm`
  - `statusOptions`
  - `createdAt`
  - `updatedAt`
- `RosterEntry`
  - `id`
  - `rosterId`
  - `displayName`
  - `note`
  - `sortOrder`
- `RosterSession`
  - `id`
  - `rosterId`
  - `title`
  - `createdAt`
  - `updatedAt`
- `SessionResult`
  - `sessionId`
  - `entryId`
  - `statusLabel`
  - `updatedAt`

Use stable IDs instead of relying on names. This protects historical results when a display name changes.

## Storage

The MVP stores all app data locally. A local embedded database is preferred over ad hoc JSON once roster/session history is involved.

Recommended approach:

- local database for rosters, entries, sessions, and results
- secure or local preferences storage for LLM settings
- file picker/import and file saver/share APIs for `.xlsx`

No server API is introduced.

## Import Flow

All import paths end in the same editable preview contract:

```text
ParsedRosterEntry {
  displayName: string
  note?: string
}
```

Local import modes:

- plain text: one entry per non-empty line
- spreadsheet: user selects/accepts a name column; lightweight extra fields can be joined into note/additional info

LLM-assisted mode:

- available only when LLM is enabled/configured
- uses OpenAI-compatible API only
- sends pasted text or spreadsheet-derived text content
- asks the model to return structured entries with display name and optional note
- validates/sanitizes model output before preview
- never writes directly to a roster without user review

If LLM is disabled or fails, the user can continue with local fixed-format import.

## Export Flow

MVP supports `.xlsx` only.

Single-session export:

- roster metadata
- session title/date
- rows: display name, note, status

Long-term all-history export:

- rows: display name and note
- columns: session title/date
- cells: status label

No CSV, charts, analytics, or complex statistical reports in MVP.

## Trade-Offs

- Flutter is chosen for cross-platform reach and polished UI, despite the current repository having no existing app.
- OpenAI-compatible LLM support is included in MVP, but other provider protocols are excluded to prevent integration sprawl.
- The app remains offline-first by keeping LLM optional/configurable and preserving fixed local import formats.
- Entry fields are limited to display name plus note/additional info to avoid turning MVP into a general database editor.
- Long-term rosters support history export, but not analytics, to keep scope bounded.

## Compatibility and Rollback

Because the repository is greenfield, initial implementation can create the Flutter project structure directly. Any generated files should be kept scoped to the project root. If a dependency choice causes build issues, rollback by replacing the package and preserving the logical data/import/export contracts above.
