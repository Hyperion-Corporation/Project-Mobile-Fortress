# Skill: Cut a Play Store Release

1. Bump `versionCode` (integer, always increasing) and `versionName` (semver-ish, human-facing) in `android/app/build.gradle.kts`.
2. Update `docs/moon/CHANGELOG.md` with the release notes.
3. Ensure signing config is provided via environment/CI secrets (`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`) — never commit a keystore or password. See [`android/app/build.gradle.kts`](../../android/app/build.gradle.kts)'s `signingConfigs` block and [`.github/workflows/release.yml`](../../.github/workflows/release.yml).
4. Locally: `just assemble-release` produces a signed `.aab` under `android/app/build/outputs/bundle/release/`. Sanity-install the equivalent APK (`./android/gradlew assembleRelease`) on a device to smoke-test the release build specifically (R8 minification can behave differently from debug).
5. Tag the release (`git tag vX.Y.Z`) — pushing the tag triggers `.github/workflows/release.yml`'s `android-release` job, which builds, signs, and (if `fastlane` Play Store credentials are configured as secrets) runs `fastlane supply` to upload to the configured track (default: internal testing).
6. Promote internal → closed → open → production tracks manually in the Play Console after QA sign-off; this project does not auto-promote.

For the iOS equivalent (App Store Connect), see [`docs/moon/roadmaps/ios.md`](../../docs/moon/roadmaps/ios.md) — signing/export automation is not built yet; `just ios-archive` produces an unsigned `.xcarchive` as a starting point.
