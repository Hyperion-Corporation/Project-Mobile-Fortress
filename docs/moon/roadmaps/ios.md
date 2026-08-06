# iOS Roadmap

Scope: `ios/MyGame/`, `ios/MyGame.xcodeproj`, `ios/Tests/`.

## Done (template scaffolding)

- SpriteKit `GameScene` with fixed-delta-clamped `update(_:)`, `SKPhysicsContactDelegate`-based collision handling, and `TouchInputHandler`.
- SwiftUI chrome: `MainMenuView`, `HUDView`, `ShopView`, `GameOverView`, shared `Theme`.
- `GameManager` (`ObservableObject`) as the single state-machine source of truth — see `core/src/game-state-machine.md` for the cross-platform spec it implements today (pre-C++-core).
- `HighScoreStore` / `SettingsStore` (`UserDefaults` + `Codable`).
- `LevelLoader` reading the canonical `core/assets/levels/` JSON, validated against `core/src/level-schema.json`.
- `XCTest` unit tests for state transitions, high-score ranking/capping, level loading, and player-movement math.
- Shared Xcode scheme (`xcshareddata/xcschemes/MyGame.xcscheme`) so `xcodebuild -scheme MyGame test` works headlessly in CI (`.github/workflows/ci.yml`'s `ios` job).

## Pending (Mobile Fortress adoption)

- Wōkòu-era sprite/texture assets (currently solid-color `SKSpriteNode`s) — HQ/outposts, Ming Garrison Spearmen/Fo-lang-ji Cannon Crews/Portuguese Arquebusiers/Veteran Commander units, Wōkòu raider enemies (land and naval).
- Rebuild `GameScene`/`GameManager` around the grid-based fortress-defense core loop and land/naval Flow Field pathfinding (see [`gameplay.md`](gameplay.md)), replacing the current demo entity logic.
- Consume the shared C++ core via Swift's native C++ interop (or an Objective-C++ shim where needed) once [`shared_core.md`](shared_core.md) lands, retiring `GameManager`'s standalone state machine in favor of calling into the C++ core.
- Haptics (`GameSettings.isHapticsEnabled` is modeled but not yet wired to `UIImpactFeedbackGenerator`).
- App Store Connect signing/export automation to match Android's `release.yml` fastlane path (see `tools/build/justfile`'s `ios-archive` recipe, which currently only produces an unsigned `.xcarchive`).
- Co-Op networking client: server-authoritative session join, client-side prediction/reconciliation (see [`backend.md`](backend.md)).
- Bring Android's client to feature parity once both consume the same C++ core, so platform divergence is limited to native UI/UX rather than gameplay logic.
