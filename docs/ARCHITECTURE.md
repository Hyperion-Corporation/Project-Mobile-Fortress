# Architecture

> **TODO:** Expand with Mobile Fortress' actual fortress-defense/multiplayer architecture as it's implemented beyond the current inherited client skeletons — see [`moon/ROADMAP.md`](moon/ROADMAP.md) and [`moon/roadmaps/shared_core.md`](moon/roadmaps/shared_core.md). This page should stay in sync with the actual `android/app/` and `ios/MyGame/` modules.

## Overview

Mobile Fortress ships two independent native clients — an Android application module (`android/app/`, standard `com.android.application` + `kotlin-android` Gradle setup) and an iOS app (`ios/MyGame.xcodeproj`, SwiftUI-lifecycle + SpriteKit) — plus a shared-assets/spec module (`core/`, see `core/README.md`). Each client renders its game surface on a dedicated per-frame update loop decoupled from its UI-chrome framework (Android: `SurfaceView` + a fixed-timestep thread; iOS: SpriteKit's `SKScene.update(_:)`, delta-clamped); menus/HUD/settings around that surface use the platform's native declarative UI (Jetpack Compose / SwiftUI). An **optional** lightweight backend (`infra/`) can be added later for leaderboards or cloud save — both apps run fully offline without it.

## Android Module Boundaries (`android/app/`)

| Module | Responsibility |
| --- | --- |
| `MainActivity.kt` | Hosts `GameView`, wires Android lifecycle callbacks to the game loop, handles save/restore. |
| `GameView.kt` | `SurfaceView` + `SurfaceHolder.Callback`; owns the `GameLoop` thread's lifecycle. |
| `GameLoop.kt` | Fixed-timestep update/render thread, independent of Activity/View lifecycle beyond the `SurfaceHolder` reference it's given. |
| `engine/GameEngine.kt` | Orchestrates entity update/render each tick; owns the entity collection. |
| `engine/GameState.kt` | Serializable snapshot of game progress; save/restore boundary. |
| `engine/entities/` | Individual game objects (e.g. `Ball.kt`), each implementing `update()`/`render()`. |
| `ui/` | Jetpack Compose screens (main menu, pause, settings) — never part of the render loop. |

## iOS Module Boundaries (`ios/MyGame/`)

| Module | Responsibility |
| --- | --- |
| `App/MyGameApp.swift` | SwiftUI `@main` entry point; routes Menu/GameLevel/GameOver from `GameManager.state`. |
| `App/AppDelegate.swift` | Background/terminate hooks that pause the game (SpriteKit scenes aren't part of `ScenePhase`). |
| `Core/GameManager.swift` | `ObservableObject` state machine — the SwiftUI-side equivalent of Android's `GameEngine`/`GameState` pairing; implements the shared spec in `core/src/game-state-machine.md`. |
| `Scenes/GameLevel/GameScene.swift` | `SKScene` subclass owning the per-frame update loop, physics, and input wiring. |
| `Scenes/Nodes/` | `SKSpriteNode` subclasses (`PlayerNode`, `EnemyNode`, `BulletNode`). |
| `Engine/Physics/`, `Engine/Input/`, `Engine/Audio/` | Contact resolution, touch handling, AVFoundation SFX/music. |
| `Engine/Storage/` | `HighScoreStore` / `SettingsStore` — `UserDefaults` + `Codable` persistence. |
| `UI/` | SwiftUI chrome (`MainMenuView`, `HUDView`, `ShopView`, `GameOverView`, `Theme`) — never part of the render loop. |
| `Resources/Levels/LevelLoader.swift` | Decodes level JSON referenced directly from `core/assets/levels/` (see `core/README.md`). |

## Shared (`core/`)

Raw assets (`core/assets/`) and a documented-but-not-compiled spec (`core/src/`) for the level-data shape and the state-machine shape both clients implement independently. See `core/README.md` and `moon/roadmaps/shared_core.md` for what's real today vs. a future KMP/C++ option.

## Data Flow

**Android:**

```
Activity lifecycle ──▶ GameView (SurfaceView) ──▶ GameLoop thread
                                                        │
                                          ┌─────────────┴─────────────┐
                                          ▼                           ▼
                                   GameEngine.update()         GameEngine.render()
                                          │                           │
                                   engine/entities/*            Canvas draw calls
                                          │
                                   GameState (save/restore, on pause)
```

**iOS:**

```
SwiftUI Scene lifecycle ──▶ GameContainerView (SpriteView) ──▶ GameScene (SKScene)
                                                                      │
                                                    ┌─────────────────┴─────────────────┐
                                                    ▼                                   ▼
                                            GameScene.update(_:)            SpriteKit's own render pass
                                                    │
                                    PlayerNode/EnemyNode/BulletNode advance
                                                    │
                                GameManager (score/state) ──▶ HighScoreStore (on endGame)
```

## Rendering Approach

See [ADR 0002](adr/0002-rendering-approach.md) for the Android rationale (`SurfaceView` + `Canvas` over Compose Canvas or a full game engine) and [ADR 0003](adr/0003-ios-rendering-approach.md) for the iOS rationale (SpriteKit over Metal-from-scratch or a cross-platform engine), plus [`.agent/AGENTS.md`](../.agent/AGENTS.md) §1.1 for when to swap either out.

## Optional Backend

If leaderboards or cloud save are added, both apps talk to the backend only through a documented REST API (add the schema here once it exists) — never by reaching into backend internals. See `infra/docker/README.md`, `infra/k8s/README.md` for the optional deployment scaffolding.

## Architecture Decision Records

Significant, hard-to-reverse decisions are recorded under [`docs/adr/`](adr/) using the [Michael Nygard ADR format](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions).
