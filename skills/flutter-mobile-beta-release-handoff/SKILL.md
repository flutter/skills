---
name: flutter-mobile-beta-release-handoff
description: Creates a reliable Flutter beta release handoff for Android Firebase App Distribution and iOS TestFlight. Use when building, uploading, or summarizing beta artifacts so release status, hashes, upload IDs, tester distribution, and follow-up gaps are explicit.
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Wed, 06 May 2026 00:00:00 GMT
---
# Flutter Mobile Beta Release Handoff

Use this skill when preparing or reporting a Flutter mobile beta release for Android and iOS. The goal is not only to build artifacts, but to leave a trustworthy handoff: what was built, where it was uploaded, who received it, what changed locally, and what still needs attention.

## Contents
- [Before You Start](#before-you-start)
- [Preflight Checklist](#preflight-checklist)
- [Build Artifacts](#build-artifacts)
- [Upload and Distribution](#upload-and-distribution)
- [Release Handoff Report](#release-handoff-report)
- [Troubleshooting](#troubleshooting)

## Before You Start

Confirm the release intent before changing versions or uploading externally.

- App and repository path.
- Active branch and target environment.
- Requested `version` and build number from `pubspec.yaml`.
- Release targets: Android Firebase App Distribution, Google Play, iOS TestFlight, or a local artifact only.
- Whether external uploads are explicitly approved for this task.
- Which testers or groups should receive the build, if any.

Do not assume that a successful upload means testers received the build. Firebase App Distribution can accept an artifact without tester or group targets.

## Preflight Checklist

1. Locate the actual Flutter package directory.
   - Many repositories keep the app in a subdirectory such as `flutter/`.
   - Run Flutter commands from the directory that contains `pubspec.yaml`.
2. Record the starting branch and working tree state.
   ```bash
   git branch --show-current
   git status --short
   ```
3. Verify the requested version and build number.
   - Android `versionCode` must fit store constraints and remain below Google Play limits.
   - iOS build numbers must be valid for App Store Connect and higher than the previous uploaded build for that marketing version.
4. Check platform configuration before building.
   - Android signing configuration and package id.
   - iOS bundle id, signing team, provisioning, and export method.
5. Prepare iOS dependencies when needed.
   - If CocoaPods or encoding issues appear, run from the iOS directory with UTF-8 locale:
     ```bash
     LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 pod install --repo-update
     ```
6. Capture any expected dirty files before the build so build-generated changes are not confused with intentional release edits.

## Build Artifacts

Build only the artifacts needed for the approved release target.

### Android

For Play-linked distribution or store submission, build an Android App Bundle:

```bash
flutter build appbundle --release
```

For Firebase App Distribution fallback or direct tester install, build an APK:

```bash
flutter build apk --release
```

Record the artifact path, size, and SHA-256 hash:

```bash
shasum -a 256 build/app/outputs/bundle/release/app-release.aab
shasum -a 256 build/app/outputs/flutter-apk/app-release.apk
```

### iOS

Build an IPA for TestFlight:

```bash
flutter build ipa --release
```

Record the artifact path, size, and SHA-256 hash:

```bash
shasum -a 256 build/ios/ipa/*.ipa
```

## Upload and Distribution

Upload only after the target and recipient expectations are clear.

### Firebase App Distribution

Capture these fields in the handoff:

- Firebase project id.
- Firebase app id.
- Artifact type: AAB or APK.
- Release id or console URL.
- Tester emails and/or groups used.
- Whether distribution was skipped because no testers or groups were specified.

If AAB upload fails because the Firebase Android app is not linked to a Google Play developer account, use an APK fallback only if that fallback is acceptable for the release request. Make the fallback explicit in the handoff.

### TestFlight

Capture these fields in the handoff:

- Apple account or team context.
- Bundle id.
- IPA path and SHA-256 hash.
- Upload tool used, such as Transporter, Xcode, or `altool`.
- Delivery UUID or upload id.
- Any processing warnings or follow-up required in App Store Connect.

## Release Handoff Report

End every release task with a concise report that can be trusted later.

```markdown
# Mobile Beta Release Handoff

- App/repo:
- Branch:
- Requested version/build:
- Working tree before build:
- Working tree after build:

## Android
- Target:
- Artifact type/path:
- SHA-256:
- Firebase/Play status:
- Upload result/release id:
- Testers/groups:
- Distribution status:

## iOS
- Target:
- IPA path:
- SHA-256:
- TestFlight Delivery UUID:
- Processing status:

## Changed files
-

## Warnings/gaps
-

## Recommended next step
-
```

Use explicit language:

- Say `uploaded but not distributed to testers` when no testers or groups were specified.
- Say `built locally only` when no upload was approved or attempted.
- Say `dirty files remain` and list them when build or version changes are not committed.
- Do not claim store availability until the relevant store console has processed and exposed the build.

## Troubleshooting

- **Flutter command cannot find the project**: move to the directory that contains `pubspec.yaml`.
- **Android AAB rejected by Firebase App Distribution**: check whether the Firebase Android app is linked to Google Play. If not, build and upload an APK fallback only with approval.
- **Firebase upload succeeds but nobody receives it**: verify testers or groups were passed to the upload command.
- **iOS CocoaPods fails with encoding errors**: rerun `pod install` using `LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8`.
- **TestFlight upload succeeds but build is missing**: wait for App Store Connect processing, then check processing errors and export compliance prompts.
- **Unexpected dirty files appear**: compare `git status --short` before and after the build and identify which changes came from version edits, dependency updates, or generated artifacts.

## Definition of Done

A Flutter mobile beta release handoff is complete when:

- Requested artifacts were built or explicitly marked blocked.
- SHA-256 hashes were recorded for every artifact handed off or uploaded.
- Upload IDs, release IDs, or delivery UUIDs were recorded.
- Tester/group distribution status is explicit.
- Dirty files and warnings are listed.
- The next recommended action is clear.
