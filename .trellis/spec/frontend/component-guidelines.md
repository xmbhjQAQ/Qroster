# Component Guidelines

> How components are built in this project.

---

## Overview

<!--
Document your project's component conventions here.

Questions to answer:
- What component patterns do you use?
- How are props defined?
- How do you handle composition?
- What accessibility standards apply?
-->

(To be filled by the team)

---

## Component Structure

App-level screens live directly under `lib/src/ui/` with the `_screen.dart`
suffix. Expose global pages from the home drawer instead of roster-specific
detail screens when the page does not depend on a roster ID.

Example:

```dart
Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => const AboutScreen()),
);
```

---

## Props Conventions

<!-- How props should be defined and typed -->

(To be filled by the team)

---

## Styling Patterns

Use the shared widgets in `lib/src/ui/widgets/qroster_widgets.dart` before
adding new local styling wrappers:

- `QAssetIcon` for repo-owned SVG identity and state assets.
- `SectionCard` for grouped content blocks.
- `ListTile` rows for settings, support, and app-level actions.

App identity and utility pages should stay compact and task-oriented. Avoid
marketing-style hero layouts for in-app pages.

---

## Accessibility

<!-- A11y requirements and patterns -->

(To be filled by the team)

---

## Common Mistakes

<!-- Component-related mistakes your team has made -->

(To be filled by the team)
