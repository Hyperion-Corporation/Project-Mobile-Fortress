import XCTest
@testable import MyGame

/// Mirrors the scope of the Android `GameEngineTest.kt`: pure state-machine
/// transitions, no SpriteKit/UIKit involved, so these run fast on any host
/// (no simulator boot required for this file specifically, though the test
/// bundle as a whole still needs one — see `tools/ios/justfile`).
final class GameManagerTests: XCTestCase {
    func testStartNewGameResetsScoreAndEntersPlaying() {
        let manager = GameManager.shared
        manager.startNewGame()
        XCTAssertEqual(manager.state, .playing)
        XCTAssertEqual(manager.score, 0)
    }

    func testAddScoreOnlyAppliesWhilePlaying() {
        let manager = GameManager.shared
        manager.startNewGame()
        manager.addScore(10)
        XCTAssertEqual(manager.score, 10)

        manager.pause()
        manager.addScore(10)
        XCTAssertEqual(manager.score, 10, "score should not change while paused")
    }

    func testPauseResumeRoundTrip() {
        let manager = GameManager.shared
        manager.startNewGame()
        manager.pause()
        XCTAssertEqual(manager.state, .paused)
        manager.resume()
        XCTAssertEqual(manager.state, .playing)
    }

    func testEndGameCapturesFinalScore() {
        let manager = GameManager.shared
        manager.startNewGame()
        manager.addScore(50)
        manager.endGame()
        XCTAssertEqual(manager.state, .gameOver(score: 50))
    }
}
