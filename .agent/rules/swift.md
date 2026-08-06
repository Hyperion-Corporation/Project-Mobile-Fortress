# Swift Rules

- Target Swift 5.0 / iOS 16+, built via Xcode (`ios/MyGame.xcodeproj`) — see [`.agent/workflows/ios_lifecycle.md`](../workflows/ios_lifecycle.md) for the SpriteKit/SwiftUI lifecycle contract.
- Format/lint with SwiftLint if configured locally (not bundled by default in this project — see `docs/DEVELOPMENT.md` for how to add it) and Xcode's built-in warnings; treat new warnings on touched files as blocking.
- Prefer `struct`/`enum` value types over `class` unless you need reference semantics or `SKNode`/`UIKit` inheritance forces a class (`SKSpriteNode` subclasses, `AVAudioPlayer`-owning managers).
- Use `ObservableObject` + `@Published` for SwiftUI-observable state (`GameManager`) rather than `NotificationCenter` broadcasts, except where bridging out of SpriteKit's non-SwiftUI node tree genuinely requires it (`GameScene` reads `GameManager.shared` directly since `SKScene` isn't part of the view hierarchy).
- No force-unwraps (`!`) or force-tries (`try!`) outside test code — prefer `guard let`, `if let`, or `try?` with an explicit fallback.
- Keep `Codable` models (`GameSettings`, `HighScoreEntry`, `LevelDefinition`) free of SpriteKit/UIKit imports so they stay trivially unit-testable — see [`Engine/Storage/`](../../ios/MyGame/Engine/Storage) and [`Resources/Levels/LevelLoader.swift`](../../ios/MyGame/Resources/Levels/LevelLoader.swift).
- Match the shared state-machine spec in [`core/src/game-state-machine.md`](../../core/src/game-state-machine.md) when changing `GameManager.GameStateKind` — update that doc and the Android side's equivalent states in the same PR, not just the Swift enum.

## Anti-patterns

- Doing gameplay math or persistence inside a SwiftUI `View`'s `body` — `View`s should read `@Published`/`@State` and call into `GameManager`/a store, never own game logic themselves (mirrors [`ui_compose.md`](ui_compose.md)'s Compose rule).
- Force-unwrapping `Bundle.main.url(forResource:withExtension:)` — a missing/renamed resource should surface as a typed error (`LevelLoaderError`), never a crash.
