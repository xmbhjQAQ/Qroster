# Automate release on main merge

## Goal

Make the repository's branch workflow match the intended release model:

- Work pushed to `master` is treated as development work and only produces debug CI artifacts.
- Pull requests into `main` are checked before merge.
- A successful merge into `main` automatically publishes a new GitHub Release APK and updates the app version metadata.

This removes the manual tag-push step from normal releases and makes the `main` branch the source of released builds.

## Confirmed Facts

- `.github/workflows/flutter-ci.yml` currently runs debug CI on pushes to `master`.
- `.github/workflows/flutter-ci.yml` currently checks pull requests targeting `main` or `master`.
- `.github/workflows/flutter-release.yml` currently publishes a release only when a `v*` tag is pushed.
- `pubspec.yaml` currently has `version: 1.0.0+1`.
- The app's About screen reads package version metadata at runtime, so release builds should receive correct `build-name` and `build-number` values.

## Requirements

- Keep `master` push behavior as debug-only CI with a debug APK artifact.
- Keep pull requests into `main` checked by analyze, test, and debug APK build before merge.
- Require pull requests into `main` to have exactly one supported release label before CI can pass.
- On push to `main`, automatically compute the next app version from the labels on the merged pull request.
- Support `release:patch` for patch releases, for example `1.2.3` to `1.2.4`.
- Support `release:minor` for minor releases, for example `1.2.3` to `1.3.0`.
- Support `release:major` for major releases, for example `1.2.3` to `2.0.0`.
- Fail the release workflow with a clear error if the merged pull request does not have exactly one supported release label.
- Update `pubspec.yaml` with the release version and build number.
- Commit the version metadata update back to `main` using GitHub Actions.
- Create a matching `vX.Y.Z` tag from the release commit.
- Build a release APK using the computed version name and build number.
- Publish a GitHub Release with the generated APK attached.
- Avoid release recursion when the workflow commits the version bump and tag.
- Document the new branch and release behavior in `README.md`.

## Acceptance Criteria

- [ ] Pushing to `master` does not create a GitHub Release.
- [ ] Opening or updating a PR into `main` runs analyze, tests, and debug APK build.
- [ ] Opening or updating a PR into `main` fails CI when it has no supported release label.
- [ ] Opening or updating a PR into `main` fails CI when it has conflicting supported release labels.
- [ ] Merging a PR labeled `release:patch` into `main` creates exactly one patch version bump commit.
- [ ] Merging a PR labeled `release:minor` into `main` creates exactly one minor version bump commit.
- [ ] Merging a PR labeled `release:major` into `main` creates exactly one major version bump commit.
- [ ] Merging a PR without a supported release label fails before creating a release commit, tag, or GitHub Release.
- [ ] Merging a PR with conflicting supported release labels fails before creating a release commit, tag, or GitHub Release.
- [ ] Merging into `main` creates exactly one new `vX.Y.Z` tag.
- [ ] Merging into `main` creates a GitHub Release with a release APK attached.
- [ ] The release APK is built with `build-name` equal to the tag version without `v`.
- [ ] The release APK is built with `build-number` matching the numeric build metadata in `pubspec.yaml`.
- [ ] README explains that `master` is debug-only and `main` is release-producing.

## Out of Scope

- Release signing is separate from this task. If no formal keystore is configured yet, this task can still automate the existing APK release flow, but the APK may remain debug-key signed until signing is configured.
- Store distribution tracks, changelog generation, and semantic release from conventional commits are out of scope.

## Open Questions

- None.
