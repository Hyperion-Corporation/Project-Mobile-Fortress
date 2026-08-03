# Workflow: Game Loop / Performance Change

Applies to Android's `android/app/.../GameLoop.kt`, `GameEngine.kt`, `engine/entities/`, and iOS's `ios/MyGame/Scenes/GameLevel/GameScene.swift`, `Scenes/Nodes/`.

## When to use this workflow

- Changing Android's fixed-timestep accumulator, update rate, or catch-up cap — or iOS's per-frame delta clamp.
- Adding a new entity type that participates in the per-frame update/render path, on either platform.
- Investigating a reported frame-drop/jank issue, on either platform.

## Steps

1. Read [`.agent/rules/game_loop_performance.md`](../rules/game_loop_performance.md) before touching `GameLoop.kt` (Android) or `GameScene.swift` (iOS) — these are the most failure-sensitive files in the template; a subtle regression here degrades every frame of every session.
2. Reproduce/baseline first: on Android, run `just install` on a real mid-range device if available (the emulator's GPU/CPU profile is not representative), profile with Perfetto or the CPU Profiler. On iOS, run on a real device via Xcode if available, profile with Instruments' Time Profiler. Confirm the actual bottleneck before changing code, on either platform.
3. If adding a new entity type, verify its update/render methods allocate nothing per call — Android: pool any objects it needs (e.g. `Rect`, `Paint`) at construction time; iOS: avoid creating `SKAction`/`SKTexture` instances inside `update(_:)`, only at node-spawn time.
4. Android: if touching the accumulator loop, keep the catch-up step cap intact and add/update a unit test asserting the loop doesn't spiral under a simulated long frame. iOS: if touching the delta clamp, keep `GameConstants.maxFrameDelta` intact and add/update an XCTest exercising a simulated long gap (see [`.agent/rules/testing_qa.md`](../rules/testing_qa.md)).
5. Re-profile after the change; confirm the fix addresses the measured bottleneck, not a guessed one.
6. Android: run `just unit-test` and, if the change is render-visible, `just install` for a manual sanity pass. iOS: run `just ios-test` and, if render-visible, run in the Simulator via Xcode for a manual sanity pass.

## Anti-patterns

- "Optimizing" based on a hunch instead of a profile, on either platform.
- Fixing jank by skipping update calls instead of fixing the actual allocation/blocking-call source.
