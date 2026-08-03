# Dev Container

This Dev Container provisions the **Android** toolchain only: Android SDK cmdline-tools, JDK 17, and emulator dependencies (see `Dockerfile`). Opening it gets you a working `android/` build/test environment via VS Code's "Reopen in Container".

## iOS is not supported here

Xcode and the iOS Simulator only run on macOS — there is no Linux (or Docker-on-Linux) way to build, test, or run the `ios/` app. This is an Apple platform restriction, not a limitation of this container's configuration; no Dev Container image can work around it.

To work on `ios/MyGame`, you need one of:

- A native macOS machine with Xcode 15+ installed, or
- A macOS CI runner (already wired up for this repo — see `.github/workflows/ci.yml`'s `ios-test` job on `macos-latest`), or
- A macOS cloud/remote-build service, if your organization has one.

See [`docs/DEVELOPMENT.md`](../docs/DEVELOPMENT.md#ios-ios) for iOS setup once you have a macOS host.
