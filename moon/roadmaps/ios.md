# iOS Roadmap

Scope: `ios/MyGame/`, `ios/MyGame.xcodeproj`, `ios/Tests/`.

## Done (template scaffolding)

- SpriteKit `GameScene` with fixed-delta-clamped `update(_:)`, `SKPhysicsContactDelegate`-based collision handling, and `TouchInputHandler`.
- SwiftUI chrome: `MainMenuView`, `HUDView`, `ShopView`, `GameOverView`, shared `Theme`.
- `GameManager` (`ObservableObject`) as the single state-machine source of truth — see `core/src/game-state-machine.md` for the cross-platform spec it implements today (pre-Rust-core).
- `HighScoreStore` / `SettingsStore` (`UserDefaults` + `Codable`).
- `LevelLoader` reading the canonical `core/assets/levels/` JSON, validated against `core/src/level-schema.json`.
- `XCTest` unit tests for state transitions, high-score ranking/capping, level loading, and player-movement math.
- Shared Xcode scheme (`xcshareddata/xcschemes/MyGame.xcscheme`) so `xcodebuild -scheme MyGame test` works headlessly in CI (`.github/workflows/ci.yml`'s `ios` job).

## Pending (Mobile Fortress adoption)

- Sengoku-Japan sprite/texture assets (currently solid-color `SKSpriteNode`s) — castle, Ashigaru/Matchlock/Samurai units, Yokai enemies.
- Rebuild `GameScene`/`GameManager` around the grid-based castle-defense core loop and Flow Field pathfinding (see [`gameplay.md`](gameplay.md)), replacing the current demo entity logic.
- Consume the shared Rust core via UniFFI-generated Swift bindings once [`shared_core.md`](shared_core.md) lands, retiring `GameManager`'s standalone state machine in favor of calling into Rust.
- Haptics (`GameSettings.isHapticsEnabled` is modeled but not yet wired to `UIImpactFeedbackGenerator`).
- App Store Connect signing/export automation to match Android's `release.yml` fastlane path (see `tools/build/justfile`'s `ios-archive` recipe, which currently only produces an unsigned `.xcarchive`).
- Co-Op networking client: server-authoritative session join, client-side prediction/reconciliation (see [`backend.md`](backend.md)).
- Bring Android's client to feature parity once both consume the same Rust core, so platform divergence is limited to native UI/UX rather than gameplay logic.
