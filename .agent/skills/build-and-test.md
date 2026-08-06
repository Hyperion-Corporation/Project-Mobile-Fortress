# Skill: Build and Test

## Android

```bash
just apk                # ./gradlew assembleDebug
just unit-test           # ./gradlew testDebugUnitTest
just test-instrumented  # ./gradlew connectedDebugAndroidTest (needs a device/emulator)
just lint-check           # ./gradlew lint ktlintCheck
just install              # ./gradlew installDebug onto a connected device/emulator
```

Run `just unit-test` + `just lint-check` before every commit. Run `just test-instrumented` before opening a PR that touches lifecycle, `SurfaceView`, or Compose UI code — CI runs it too, but it's the slowest job and failures are cheaper to catch locally.

## iOS

**Requires a macOS host with Xcode** — see [`.devcontainer/README.md`](../../.devcontainer/README.md); these will fail on the Linux devcontainer.

```bash
just ios-build   # xcodebuild ... -destination 'generic/platform=iOS Simulator' build
just ios-test     # xcodebuild ... test (needs a simulator)
just ios-check    # xcodebuild ... analyze
just ios-archive  # xcodebuild ... archive (unsigned .xcarchive)
```

Run `just ios-test` + `just ios-check` before every commit that touches `ios/`. There is no instrumented/on-device-only test tier on iOS the way there is on Android — `just ios-test` already runs on a simulator and covers the same ground as both Android tiers combined, since XCTest can exercise `UIKit`/`SpriteKit` APIs directly in-process.
