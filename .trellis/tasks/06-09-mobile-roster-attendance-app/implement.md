# Q名册 / qroster Implementation Plan

## Implementation Checklist

1. Bootstrap Flutter project
   - Create qroster Flutter app structure in the repository.
   - Add core dependencies for local storage, SVG assets, file picking/saving, spreadsheet import/export, and HTTP.
   - Configure app identity placeholders for "Q名册" / `qroster`.

2. Establish project structure
   - Create folders for models, storage/repositories, import/export services, LLM service, UI screens, reusable widgets, and assets.
   - Add repo-owned SVG assets for app icon/identity, empty state, and key actions.

3. Implement data layer
   - Define models for settings, rosters, entries, sessions, and results.
   - Implement local persistence.
   - Preserve stable IDs across edits.

4. Implement settings and LLM service
   - Store LLM enabled/disabled state.
   - Store OpenAI-compatible Base URL, API Key, and Model.
   - Implement a parsing request that returns `displayName` and optional `note`.
   - Validate/sanitize LLM output before exposing preview data.

5. Implement import services
   - Plain text fixed-format parser.
   - Spreadsheet parser with name-column handling.
   - Shared editable import preview model.
   - LLM-assisted parser path that falls back to local import on failure.

6. Implement onboarding
   - First-launch detection.
   - Skippable onboarding entry.
   - LLM enable/disable/configuration step.
   - First roster setup/import step.

7. Implement home/navigation shell
   - Home roster overview and roster count.
   - Roster cards with name, type, entry count, latest record status/time.
   - Top-left menu opening a left-to-right half-screen overlay drawer.
   - Drawer settings entry, including LLM configuration.
   - Small bottom-left floating action button for new roster creation.

8. Implement roster creation/detail
   - Roster name, temporary/long-term selection, status option editing.
   - Entry list and import/update actions.
   - Session history for long-term rosters.

9. Implement marking flow
   - One-entry-at-a-time mobile UI.
   - Large status buttons.
   - Previous/next correction.
   - Progress indicator.
   - Save session results locally.

10. Implement result editing
    - Editable result table for selected session.
    - Edit entry display name, note, and status.
    - Keep roster/session isolation intact.

11. Implement `.xlsx` export
    - Single selected session export.
    - Long-term all-history multi-column export.
    - Default filenames using `qroster` and roster/session context.

12. Polish and accessibility pass
    - Mobile viewport layout checks.
    - Touch targets.
    - Empty/loading/error states.
    - SVG rendering and app identity review.

## Validation Commands

Run available Flutter checks after implementation:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

If Flutter is unavailable in the environment, record that limitation and validate with any available static checks.

## Manual Verification

- First launch shows skippable onboarding.
- Onboarding can enable LLM, disable LLM, or be skipped.
- Skipping onboarding opens the roster list/empty state.
- Home shows roster count and roster cards.
- Top-left menu opens a half-screen left drawer.
- Bottom-left floating action button starts new roster creation.
- A roster can be temporary or long-term.
- Default statuses are "到了", "没到", "迟到", "请假".
- Text import creates editable preview entries.
- Spreadsheet import creates editable preview entries.
- LLM import creates editable preview entries when configured.
- Local import remains usable when LLM is disabled.
- Marking flow can assign and revise statuses.
- Result table can edit names, notes, and statuses.
- Single session `.xlsx` export works.
- Long-term all-history `.xlsx` export works.
- App can perform core non-LLM workflows without internet.

## Risky Areas

- Flutter project generation may introduce many files; keep generated structure scoped and avoid unrelated Trellis changes.
- Spreadsheet packages vary in platform support; choose a package that works for mobile Flutter and `.xlsx`.
- File save/share behavior differs by platform; prioritize Android/mobile v0 behavior.
- LLM responses are untrusted structured text; validate before preview.
- Half-screen drawer behavior may need custom layout instead of a default full-width drawer.

## Rollback Points

- After project bootstrap: if Flutter creation is wrong, remove only generated app files from this task, not `.trellis` artifacts.
- After dependency selection: if a package fails analysis/build, replace dependency while preserving service interfaces.
- After storage implementation: if database choice becomes too heavy, keep model contracts and swap persistence behind repositories.
- After export implementation: if styled `.xlsx` is unreliable, fallback to plain workbook layout while preserving required columns.
