# Automate Main Release Design

## Workflow Shape

Use two workflows:

- `Flutter CI` remains the debug validation workflow for pushes to `master` and pull requests into `main`.
- `Flutter Release` changes from tag-triggered release to `main` push-triggered release.

The CI workflow also validates release labels on pull requests into `main`, so missing or conflicting labels are caught before merge.

The release workflow should ignore its own version bump commit by checking for a marker in the head commit message before doing release work.

## Release Label Source

The `push` event for a merged pull request does not directly include pull request labels. The release workflow will use `actions/github-script` with the repository `GITHUB_TOKEN` to find the pull request associated with the pushed merge commit:

1. Read `context.sha`.
2. Call GitHub's `listPullRequestsAssociatedWithCommit` endpoint for that SHA.
3. Select the merged PR targeting `main`.
4. Read that PR's labels.
5. Require exactly one supported release label.

Supported labels:

- `release:patch`: `X.Y.Z` becomes `X.Y.(Z+1)`.
- `release:minor`: `X.Y.Z` becomes `X.(Y+1).0`.
- `release:major`: `X.Y.Z` becomes `(X+1).0.0`.

Unsupported or conflicting labels fail before changing repository state.

## Version Metadata

Parse `pubspec.yaml` for `version: X.Y.Z+B`.

The release workflow computes:

- `next_version`: based on the PR release label.
- `next_build`: current build number plus one.
- `tag_name`: `v${next_version}`.
- `apk_name`: `qroster-${tag_name}-release.apk`.

Then it updates `pubspec.yaml`, commits the change to `main`, creates `tag_name` on that version bump commit, and builds the APK with:

```bash
flutter build apk --release --build-name "$next_version" --build-number "$next_build"
```

This keeps the checked-in version metadata and the built APK metadata aligned.

## Recursion Avoidance

The workflow commits with a fixed marker, for example:

```text
chore(release): v1.2.4 [skip release]
```

The release workflow exits early when the head commit message contains `[skip release]`.

## Permissions

The workflow needs:

- `contents: write` to commit, tag, upload release assets, and create releases.
- `pull-requests: read` to inspect labels on the merged PR.

## Rollback

If the release build fails after the version bump commit or tag, the repository may contain a version commit or tag without a published release. The workflow should create the tag only after analyze/test pass and immediately before building/publishing. If publishing fails after tag creation, a maintainer can delete the failed tag/release and rerun after fixing the workflow.

## Documentation

README should document:

- `master` push means debug CI only.
- PRs to `main` require exactly one of `release:patch`, `release:minor`, or `release:major`.
- Merge to `main` performs the version bump, tag creation, APK build, and GitHub Release creation.
