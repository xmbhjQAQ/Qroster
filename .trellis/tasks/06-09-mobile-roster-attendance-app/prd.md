# Mobile roster attendance app

## Goal

Build a user-centered mobile roster / attendance app that replaces paper-based roll-call tracking. The app should let a user import a roster, step through names on a phone, mark each person with configurable attendance/status options, edit results, and export the final record as a spreadsheet.

The product should stay generic: "attendance" is the first use case, but the workflow should work for any situation where a user needs to process a list of people/items and assign one status per entry. A roster is a user-defined workspace/container, isolated from other rosters, and may represent roll call or any similar list-processing task.

## Confirmed Facts

- The repository currently has no application code or fixed technology stack.
- The first implementation can choose a greenfield architecture.
- The first release should use Flutter for cross-platform delivery and polished UI.
- The user wants a mobile-first experience.
- The app should be an offline-first small utility with no cloud/server component.
- The app must reduce manual paper tallying and manual post-processing.
- Status options must be user-configurable, not hard-coded to only "arrived / absent".
- New rosters should start with default statuses: "到了", "没到", "迟到", "请假".
- Each roster can customize its own status options.
- Each roster is an isolated unit with its own entries, status options, sessions/results, and export history.
- Each roster can be configured as either temporary/single-use or long-term.
- MVP roster entries should support a display name plus optional note/additional-info text.
- Roster input should support plain text and spreadsheets.
- LLM-assisted parsing is required in the MVP for adapting messy text or spreadsheet formats.
- Because the app is offline-first and has no cloud backend, LLM use must be configured from the client side and must not prevent local manual/rule-based import from working.
- MVP LLM integration should support only OpenAI-compatible chat/completions-style APIs with user-configured Base URL, API Key, and Model.
- Non-OpenAI-compatible LLM protocols are out of scope for the first release.
- On first app launch, users should be offered a guided first-use flow, but they may skip onboarding.
- If the user enters onboarding, step 1 configures LLM usage: users can enable and configure OpenAI-compatible parsing, or disable LLM.
- If LLM is disabled, import must use fixed supported formats plus editable review; messy free-form import is not expected to be automatically adapted.
- First-use step 2 creates the first roster and completes its core setup, including roster type, status options, and roster import.
- The home screen should focus on showing the roster count/overview and roster list.
- Global/secondary functions should live behind a top-left menu that opens a left-to-right half-screen overlay drawer.
- The home screen should provide a small floating action button at the bottom-left for creating a new roster.
- MVP visual direction should be a lightweight utility feel with soft Material 3 styling.
- UI should include generated/repo-owned SVG assets where useful, including at least an app icon, empty-state artwork/icons, and key feature icons.
- MVP product name is temporarily "Q名册"; English/app engineering name is "qroster".
- Results must be exportable to a spreadsheet.
- MVP export should support `.xlsx` only; CSV export is out of scope.
- The result data should remain editable after marking attendance.
- v0 milestone should deliver a complete local Flutter app loop: onboarding, roster creation/import, marking flow, result editing, and `.xlsx` export.

## Requirements

- Roster management:
  - Users can create multiple independent rosters.
  - Users can name a roster according to their actual use case, such as class roll call, event check-in, equipment checklist, or other list workflows.
  - Users can choose whether a roster is long-term or temporary/single-use.
  - Long-term rosters can preserve multiple marking sessions over time.
  - Temporary/single-use rosters can focus on one session/result without requiring long-term history management.
- First-use onboarding:
  - First launch offers a guided setup flow that can be skipped.
  - Step 1 lets users enable or disable LLM-assisted import.
  - When enabled, users configure OpenAI-compatible Base URL, API Key, and Model.
  - When disabled, the app explains that imports must follow fixed supported text/table formats.
  - Step 2 guides users through creating the first roster, configuring it, and importing/reviewing its entries.
  - If onboarding is skipped, users land on the roster list/empty state and can configure LLM or create rosters later.
  - After onboarding, normal launches open the roster list.
- Home and navigation:
  - The home screen shows how many rosters exist and displays the roster list.
  - The home screen has a top-left menu control.
  - Tapping the top-left menu opens a left-to-right overlay drawer covering about half the screen.
  - The drawer contains secondary/global functions such as app settings, LLM configuration, and long-term/global configuration controls.
  - Primary roster work remains on the home and roster detail screens, not inside the drawer.
  - Creating a new roster is accessed from a small bottom-left floating action button on the home screen.
  - Each roster card shows roster name, temporary/long-term type, entry count, and latest record time/status such as "尚未记录".
- Mobile-first roster processing flow:
  - Show one roster entry at a time in a large, clear mobile interface.
  - Let the user choose one of several status options for the current entry.
  - Let the user move forward/backward and correct previous choices.
- Configurable status options:
  - Users can define the available status labels.
  - Defaults should be "到了", "没到", "迟到", and "请假".
  - Status options are scoped to each roster.
- Roster import:
  - Users can import from plain text.
  - Users can import from spreadsheet files.
  - Users can use LLM-assisted parsing to adapt irregular text or spreadsheet formats.
  - Users can configure an OpenAI-compatible LLM endpoint for parsing.
  - If LLM is disabled/unavailable, users import using fixed local formats such as one-entry-per-line text or a spreadsheet with a selected name column.
  - Users can preserve lightweight extra imported context as notes/additional info.
  - Users must be able to review and edit parsed roster entries before starting.
  - The app must retain a local/manual import path when LLM parsing is unavailable or disabled.
  - Imported entries should be normalized into a roster that the user can review before starting.
- Result editing:
  - Users can edit names, notes/additional info, and statuses after the marking flow.
  - Users can correct import mistakes before or after the session.
  - Users can review results within the current roster without mixing data from other rosters.
- Export:
  - Users can export results as an `.xlsx` spreadsheet.
  - Exported data should include at least roster name, session context, entry name, and status.
  - Users can export one selected session/result.
  - Long-term rosters can export all historical sessions as a multi-column `.xlsx` table.
  - MVP export should not include complex statistical reports.
- Data/storage:
  - The app must work offline.
  - The app must not require accounts, cloud sync, or a backend service.
  - Rosters, status options, and attendance sessions should be stored locally on the device.
- v0 milestone:
  - Initialize a Flutter project for qroster.
  - Implement skippable first-use onboarding.
  - Implement OpenAI-compatible LLM settings and import parsing.
  - Implement home roster overview with drawer and create button.
  - Implement roster creation/configuration/import.
  - Implement one-by-one marking flow.
  - Implement editable result table.
  - Implement `.xlsx` export for single session and long-term all-history export.
  - Include baseline SVG assets for app identity, empty states, and key actions.
- Usability:
  - The first screen should be the usable app flow, not a marketing page.
  - Common workflows should require minimal taps.
  - The interface should be understandable without paper-roll-call-specific terminology where possible.
  - Visual design should use a lightweight utility feel with soft Material 3 styling.
  - SVG assets should be used for app identity and important UI affordances instead of leaving generic/missing icons.
  - App naming, app identity assets, and default export filenames should use the temporary product identity "Q名册" / "qroster".

## Acceptance Criteria

- [ ] A user can create or load a roster on a phone-sized screen.
- [ ] First launch offers a skippable guided setup for LLM enable/disable/configuration and first roster creation.
- [ ] If onboarding is skipped, the user can still configure LLM and create a roster later from the normal app UI.
- [ ] After onboarding is completed, normal app launch opens the roster list.
- [ ] The home screen displays roster count/overview and a list of rosters.
- [ ] A top-left menu opens a left-to-right half-screen overlay drawer for secondary/global settings.
- [ ] A small bottom-left floating action button on the home screen starts new roster creation.
- [ ] Roster cards display name, type, entry count, and latest record time/status.
- [ ] The Flutter UI follows a lightweight utility + soft Material 3 visual direction.
- [ ] The app includes repo-owned SVG assets for app identity and key empty/action states.
- [ ] The app uses "Q名册" as the Chinese product name and "qroster" as the English/engineering name.
- [ ] A user can maintain multiple rosters whose entries and results are isolated from each other.
- [ ] A user can mark a roster as temporary/single-use or long-term.
- [ ] A user can configure the available marking statuses before a session.
- [ ] New rosters start with "到了", "没到", "迟到", and "请假" status options.
- [ ] A user can step through roster entries one at a time and assign a status.
- [ ] A user can revise a previously assigned status.
- [ ] A user can view and edit the full result table after the session.
- [ ] A user can export the relevant roster/session result as an `.xlsx` file.
- [ ] A long-term roster can export all historical sessions as an `.xlsx` table with entries as rows and sessions as columns.
- [ ] Plain text import handles common line-separated name lists.
- [ ] Spreadsheet import handles at least one common tabular roster format.
- [ ] Imported roster entries support display name plus optional note/additional-info text.
- [ ] LLM-assisted import can turn messy pasted text or spreadsheet-derived content into a roster draft for user review.
- [ ] LLM settings support user-entered Base URL, API Key, and Model for an OpenAI-compatible provider.
- [ ] The import workflow still works without LLM access by using local rule-based parsing and editable preview.
- [ ] When LLM is disabled, the UI clearly constrains import to fixed supported formats.
- [ ] The UI remains usable on mobile viewport sizes.
- [ ] The app can complete import, marking, editing, and export workflows without internet access.
- [ ] v0 provides the complete local loop from first launch through `.xlsx` export.

## Out of Scope Candidates

- Multi-user real-time collaboration.
- School- or organization-specific attendance reporting integrations.
- Mandatory cloud accounts.
- Cloud sync or server-side persistence.
- Non-OpenAI-compatible LLM provider protocols in the MVP.
- CSV export in the MVP.
- Complex statistics, charts, or attendance analytics in the MVP.
- Biometric or identity verification.
- Fully automatic attendance detection.

## Open Questions

- None blocking v0 planning.

## Notes

- Keep `prd.md` focused on requirements, constraints, and acceptance criteria.
- Lightweight tasks can remain PRD-only.
- For complex tasks, add `design.md` for technical design and `implement.md` for execution planning before `task.py start`.
