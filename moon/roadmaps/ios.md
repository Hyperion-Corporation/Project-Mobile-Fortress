# iOS Roadmap

Scope: `ios/MyGame/`, `ios/MyGame.xcodeproj`, `ios/Tests/`.

## Done (template scaffolding)

- SpriteKit `GameScene` with fixed-delta-clamped `update(_:)`, `SKPhysicsContactDelegate`-based collision handling, and `TouchInputHandler`.
- SwiftUI chrome: `MainMenuView`, `HUDView`, `ShopView`, `GameOverView`, shared `Theme`.
- `GameManager` (`ObservableObject`) as the single state-machine source of truth — see `core/src/game-state-machine.md` for the cross-platform spec it implements.
- `HighScoreStore` / `SettingsStore` (`UserDefaults` + `Codable`).
- `LevelLoader` reading the canonical `core/assets/levels/` JSON, validated against `core/src/level-schema.json`.
- `XCTest` unit tests for state transitions, high-score ranking/capping, level loading, and player-movement math.
- Shared Xcode scheme (`xcshareddata/xcschemes/MyGame.xcscheme`) so `xcodebuild -scheme MyGame test` works headlessly in CI (`.github/workflows/ci.yml`'s `ios` job).

## Pending (post-template adoption)

- Real sprite/texture assets (currently solid-color `SKSpriteNode`s).
- Haptics (`GameSettings.isHapticsEnabled` is modeled but not yet wired to `UIImpactFeedbackGenerator`).
- App Store Connect signing/export automation to match Android's `release.yml` fastlane path (see `tools/build/justfile`'s `ios-archive` recipe, which currently only produces an unsigned `.xcarchive`).
- Bring Android's `GameEngine` to feature parity (multiple entities, win/lose condition) so the two platforms' gameplay — not just their state machine shape — actually match. Tracked jointly with [`shared_core.md`](shared_core.md).
