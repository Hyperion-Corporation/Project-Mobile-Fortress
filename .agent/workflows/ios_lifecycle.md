# Workflow: iOS Lifecycle Change

Applies to `ios/MyGame/App/AppDelegate.swift`, `ios/MyGame/App/MyGameApp.swift`, `ios/MyGame/Scenes/GameLevel/GameScene.swift`, and `ios/MyGame/Core/GameManager.swift`.

## When to use this workflow

- Changing how/when `GameScene`'s update loop should pause (backgrounding, an interruption like a phone call, the pause button).
- Adding a resource tied to the app being foregrounded (audio session, sensor input).
- Changing save/restore behavior for `HighScoreStore`/`SettingsStore` or `GameManager` state.

## Steps

1. Read [`.agent/rules/swift.md`](../rules/swift.md) and [`core/src/game-state-machine.md`](../../core/src/game-state-machine.md).
2. Map out every relevant lifecycle transition your change affects: `AppDelegate.applicationDidEnterBackground`/`applicationWillTerminate`, SwiftUI's `ScenePhase` (if adopted beyond the current `@UIApplicationDelegateAdaptor` hooks), and `GameManager.pause()`/`resume()` on the game-state side. SpriteKit's `SKScene` has no view-controller-style lifecycle of its own — it only stops calling `update(_:)` when the hosting `SpriteView` is torn down, so backgrounding must be handled explicitly via `AppDelegate`, not assumed.
3. Verify `GameManager.pause()` is actually reached on backgrounding/termination — a game left in `.playing` while backgrounded means the (paused, since `GameScene.update` gates on `GameManager.shared.state == .playing`) scene silently resumes simulating a stale `deltaTime` on foreground if this check is ever removed.
4. If the change affects saved state, round-trip it: background the app (⌘⇧H in the simulator, or the Home gesture on device), force-quit, relaunch, and confirm state restores correctly (not just "app didn't crash").
5. Add or update a test in `ios/Tests/GameManagerTests.swift` covering the new transition — these are plain `XCTestCase`s, no simulator UI interaction needed for state-machine-only changes.
6. Run `just ios-test` before merging.

## Anti-patterns

- Testing lifecycle changes only via "backgrounded and re-foregrounded once and it looked fine" — cover force-quit-and-relaunch explicitly, it's the case that actually loses state.
- Relying on `deinit`/ARC teardown to release audio/session resources instead of explicit `AppDelegate` hooks — timing isn't guaranteed relative to the app actually leaving the foreground.
