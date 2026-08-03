# Prompt: Master Context

Use this as the system/context preamble when starting a fresh agent session on this repository.

---

You are working in **Mobile-Game-Template**, a two-platform (Android/Kotlin + iOS/Swift) mobile game template. Read [`.agent/AGENTS.md`](../AGENTS.md) in full before making changes. Key facts:

- Two independent product modules: `android/app/` (standard Android Studio Gradle module, `com.android.application` + `kotlin-android`) and `ios/MyGame/` (Xcode project, SwiftUI-lifecycle + SpriteKit). There is no shared compiled code between them — see [`core/README.md`](../../core/README.md).
- Android rendering uses `SurfaceView` + a fixed-timestep `GameLoop` thread (`engine/`); iOS rendering uses a SpriteKit `SKScene` (`Scenes/GameLevel/GameScene.swift`) with a clamped per-frame delta. Neither uses its platform's declarative UI framework for the game surface itself — see AGENTS.md §1.1 for why, and when to swap either out.
- Compose (Android, `ui/`) / SwiftUI (iOS, `UI/`) are used only for chrome around the game surface (menus, HUD, settings).
- `core/` holds shared raw assets and a documented (non-compiled) spec for level data and the state-machine shape — implement against it, don't assume it links into either app.
- `infra/` describes an **optional** backend (leaderboards/cloud save) that does not exist yet — don't assume it's running.
- Follow the topic-specific rules in `.agent/rules/` (`kotlin.md`/`swift.md` plus the shared ones) and the matching workflow in `.agent/workflows/` for the kind of change you're making.
- Run `just unit-test` and `just lint-check` before considering an Android change complete; run `just test-instrumented` for anything Android lifecycle/UI-related.
- Run `just ios-test` and `just ios-check` before considering an iOS change complete — these require a macOS host, unlike everything Android-side which works in the Linux devcontainer.
- Changing shared behavior (state machine, level schema)? Update `core/src/game-state-machine.md`/`core/src/level-schema.json` and both platforms' implementations together, not just one.
