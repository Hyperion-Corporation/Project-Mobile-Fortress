import Foundation

/// Mirrors the Kotlin `GameEngine`/`GameState` split on the Android side: the
/// SwiftUI-observable state machine driving which top-level screen is shown.
/// See `app/src/main/java/com/example/gametemplate/engine/GameEngine.kt` for
/// the Android counterpart and `.agent/rules/swift.md` for conventions.
enum GameStateKind: Equatable {
    case menu
    case playing
    case paused
    case gameOver(score: Int)
}

/// Single source of truth for which screen is active and the score of the
/// in-progress run. Injected into the SwiftUI environment from `MyGameApp`
/// and read by `GameScene` via `NotificationCenter` glue (SpriteKit scenes
/// aren't part of the SwiftUI view tree, so they can't use `@EnvironmentObject`
/// directly).
final class GameManager: ObservableObject {
    static let shared = GameManager()

    @Published private(set) var state: GameStateKind = .menu
    @Published private(set) var score: Int = 0

    private init() {}

    func startNewGame() {
        score = 0
        state = .playing
    }

    func pause() {
        guard state == .playing else { return }
        state = .paused
    }

    func resume() {
        guard state == .paused else { return }
        state = .playing
    }

    func addScore(_ delta: Int) {
        guard state == .playing else { return }
        score += delta
    }

    func endGame() {
        HighScoreStore.shared.submit(score: score)
        state = .gameOver(score: score)
    }

    func returnToMenu() {
        state = .menu
    }
}
