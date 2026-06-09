# Add about page

## Goal

Add an in-app About page for Q名册 and expose it from the bottom of the left-side menu.

## Requirements

- Add a menu entry named `关于 Q名册` at the bottom of the existing left-side menu.
- The About page should be an app-level page, not a roster-specific page.
- The page should show the app identity:
  - Q名册
  - qroster
  - app icon / SVG brand asset when available
  - current app version and build number when available from app metadata
- The page should briefly explain the app purpose in Chinese:
  - offline-first roster/status recording
  - import roster data
  - record member statuses
  - view statistics
  - export `.xlsx`
- The page should include privacy/data behavior in concise wording:
  - local data is stored on the device
  - LLM requests are only sent when the user has enabled LLM parsing and actively uses it
- The page should include project/support actions where practical:
  - GitHub repository link
  - issue/feedback link or repository link reuse
  - third-party license entry using Flutter's license page if available
- The UI should follow the existing Q名册 visual style and avoid a marketing/landing-page layout.

## Acceptance Criteria

- [x] The left-side menu shows `关于 Q名册` fixed at the bottom.
- [x] Tapping `关于 Q名册` navigates to an About page.
- [x] The About page displays app name, English name, version/build information, and a short Chinese description.
- [x] The About page describes local data and LLM request behavior clearly.
- [x] The About page exposes a way to view third-party licenses.
- [x] The page works on mobile-sized layouts without text overlap or clipped controls.
- [x] Existing analyze/test checks pass.

## Notes

- This is a lightweight task and can remain PRD-only unless implementation reveals broader navigation or dependency changes.
