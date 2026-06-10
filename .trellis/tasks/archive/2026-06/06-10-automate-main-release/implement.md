# Automate Main Release Implementation Plan

## Checklist

- [x] Update `.github/workflows/flutter-ci.yml` so PR checks target `main` and development pushes target `master`.
- [x] Add PR release label validation for pull requests into `main`.
- [x] Rewrite `.github/workflows/flutter-release.yml` to trigger on pushes to `main`.
- [x] Add release-label discovery through GitHub API.
- [x] Add version parsing and bump logic for `release:patch`, `release:minor`, and `release:major`.
- [x] Commit the `pubspec.yaml` version update from the workflow.
- [x] Create a `vX.Y.Z` tag from the version bump commit.
- [x] Build and publish the release APK.
- [x] Update `README.md` with the new release process.
- [x] Validate workflow YAML and local project checks.

## Validation

Local validation:

```powershell
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --no-pub
```

Workflow validation:

- Check YAML syntax by inspecting the workflow and committing through a PR.
- After merge to `main`, verify exactly one version bump commit, tag, GitHub Release, and APK asset.

## Risk Points

- GitHub's commit-to-PR lookup must reliably find the merged PR for merge commits and squash merges.
- The workflow must not recursively release its own version bump commit.
- Tag creation must not happen before the version bump commit exists.
- Existing release signing currently uses the Android release configuration in the repository; formal keystore setup is separate.
