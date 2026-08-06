# 3. SpriteKit + SwiftUI for the iOS client

Date: 2026-08-03

## Status

Accepted

## Context

Mirroring [ADR 0002](0002-rendering-approach.md)'s Android decision, the iOS client needs a default rendering approach for its own game surface. The realistic options for a lightweight, dependency-light 2D iOS client:

1. **SpriteKit + SwiftUI chrome** — Apple's first-party 2D game framework, ships with iOS, integrates with SwiftUI via `SpriteView`; `SKScene.update(_:)` is display-link-driven, giving predictable per-frame timing without hand-rolling a render thread the way Android's `SurfaceView` approach requires.
2. **Metal from scratch** — maximum control, but building a 2D sprite/physics pipeline directly on Metal is a large, ongoing engineering investment wildly disproportionate to a lightweight arcade/puzzle client.
3. **A full cross-platform engine (Unity, Godot, LibGDX-via-RoboVM)** — the right call for teams that want one codebase across platforms, but pulls in a heavy, opinionated toolchain and abandons the "real, idiomatic per-platform app" premise of this project (see the parallel reasoning for the Android side skipping LibGDX/Godot by default).
4. **Kotlin Multiplatform targeting an iOS framework** — would let Android's `engine/` logic run on iOS too, but doesn't solve *rendering* (SpriteKit or Metal would still be needed on the iOS side to actually draw anything) and is a substantial architecture commitment tracked separately in `docs/moon/roadmaps/shared_core.md` rather than assumed here.

## Decision

Use SpriteKit (`SKScene`/`SKSpriteNode`/`SKPhysicsBody`) for the game surface (`ios/MyGame/Scenes/GameLevel/GameScene.swift`), hosted in SwiftUI via `SpriteView` (`GameContainerView.swift`). Use SwiftUI for everything *around* the game surface — main menu, HUD, shop, game-over — exactly mirroring the Android decision's "engine surface vs. chrome framework" split.

Unlike Android's `GameLoop`, no hand-rolled thread/accumulator is needed: SpriteKit already calls `update(_:)` once per display refresh. `GameScene.update(_:)` still clamps the per-frame delta (`GameConstants.maxFrameDelta`) to guard against a spiral-of-death after a debugger pause or long background gap — the one piece of Android's fixed-timestep discipline that's still worth keeping, even though the surrounding infrastructure differs.

## Consequences

- `Engine/`, `Scenes/Nodes/`, and `Core/GameManager.swift` stay framework-light where possible (no `UIKit` imports in `Engine/Storage/`, for instance) so they're unit-testable without booting a full SpriteKit scene — mirrors the Android `engine/` package's JVM-testability goal.
- The Android and iOS game loops are *not* the same code and never will be without the Option A/B investment described in `docs/moon/roadmaps/shared_core.md` — gameplay behavior can drift between platforms unless both sides are updated together and `core/src/game-state-machine.md` is kept current.
- Teams needing 3D, complex physics, or genuinely shared cross-platform logic should revisit `docs/moon/roadmaps/shared_core.md`'s options rather than extending SpriteKit past what it's good at.
