# Development Guide

This is a two-client monorepo: Android/Kotlin under [`android/`](../android/) and iOS/Swift under [`ios/`](../ios/), sharing raw assets and a documented spec under [`core/`](../core/) (see `core/README.md` for what's actually shared vs. aspirational).

## Prerequisites (both platforms)

- [`just`](https://github.com/casey/just) as the command runner.
- `pre-commit` (`pip install pre-commit && pre-commit install`).

## Android (`android/`)

- Android Studio (Ladybug or newer) or a standalone JDK 17 + Android SDK cmdline-tools install.
- Android SDK Platform 35, Build-Tools 35.0.0.

```bash
git clone https://github.com/<org>/<repo>.git
cd <repo>
cp .env.example .env       # only needed if you use the optional backend
pip install pre-commit && pre-commit install
just --list
```

Open `android/` in Android Studio ("Open" → select `android/`, which contains `settings.gradle.kts`) and let it sync Gradle. Or from the CLI:

```bash
./android/gradlew -p android tasks
```

### Running the Android app

```bash
just install     # ./android/gradlew installDebug onto a connected device/emulator
```

Or run/debug directly from Android Studio's device toolbar.

### Android emulator setup

```bash
sdkmanager "system-images;android-35;google_apis;x86_64"
avdmanager create avd -n game-template -k "system-images;android-35;google_apis;x86_64"
emulator -avd game-template
```

## iOS (`ios/`)

**Requires a native macOS host with Xcode 15+.** There is no Linux devcontainer for iOS — Xcode and the iOS Simulator only run on macOS; see [`.devcontainer/README.md`](../.devcontainer/README.md).

```bash
open ios/MyGame.xcodeproj
```

Select the `MyGame` scheme and an iOS Simulator destination, then Run (⌘R). From the CLI:

```bash
just ios-build     # xcodebuild ... -destination 'generic/platform=iOS Simulator' build
just ios-test       # xcodebuild ... test
```

No SwiftLint configuration ships by default with this template — add a `.swiftlint.yml` under `ios/` and wire it into `tools/validation/justfile`'s `ios-check` recipe if you want stricter enforcement than the compiler's own warnings.

## Containerized Dev Environment

Open the repo in VS Code and choose "Reopen in Container" — see [`.devcontainer/devcontainer.json`](../.devcontainer/devcontainer.json). This container only provisions the **Android** toolchain (Android SDK, JDK 17, emulator deps); it cannot build or run the iOS app. The emulator itself also needs `/dev/kvm` passed through and is best run on the host, not inside the container, for acceptable performance.

## Common Tasks

| Task | Command | Platform |
| --- | --- | --- |
| Build debug APK | `just apk` | Android |
| Run unit tests | `just unit-test` | Android |
| Run instrumented tests | `just test-instrumented` | Android |
| Lint (ktlint + Android Lint) | `just lint-check` | Android |
| Build a signed release bundle | `just assemble-release` | Android |
| Install debug build on a device | `just install` | Android |
| Build for the iOS Simulator | `just ios-build` | iOS |
| Run the XCTest suite | `just ios-test` | iOS |
| Analyze iOS sources | `just ios-check` | iOS |
| Archive a Release build (unsigned) | `just ios-archive` | iOS |
| Start the optional backend stack | `just docker-up` | shared |
