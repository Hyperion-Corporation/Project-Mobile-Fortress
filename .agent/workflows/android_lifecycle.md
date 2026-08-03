# Workflow: Android Lifecycle Change

Applies to `MainActivity.kt`, `GameView.kt`, `AndroidManifest.xml` lifecycle-affecting entries (`configChanges`, `screenOrientation`).

## When to use this workflow

- Changing how/when the `GameLoop` thread starts, pauses, or stops.
- Adding a sensor listener, permission request, or other lifecycle-bound resource.
- Changing save/restore behavior for game state.

## Steps

1. Read [`.agent/rules/android_lifecycle.md`](../rules/android_lifecycle.md).
2. Map out every relevant lifecycle transition your change affects: `onCreate`/`onResume`/`onPause`/`onStop`/`onDestroy` on the `Activity` side, `surfaceCreated`/`surfaceChanged`/`surfaceDestroyed` on the `SurfaceView` side, and rotation (destroy + recreate unless orientation is locked).
3. Verify the `GameLoop` thread is started/stopped exactly once per matching create/destroy pair — no double-start, no leaked thread.
4. If the change affects saved state, round-trip it: background the app, kill the process via `adb shell am kill <package>`, relaunch, and confirm state restores correctly (not just "app didn't crash").
5. Add or update an instrumented test under `android/app/src/androidTest/` covering the new transition.
6. Run `just test-instrumented` (requires a connected device/emulator) before merging.

## Anti-patterns

- Testing lifecycle changes only via "rotate the emulator once and it looked fine" — cover process-death-and-restore explicitly, it's the case that actually ships bugs.
