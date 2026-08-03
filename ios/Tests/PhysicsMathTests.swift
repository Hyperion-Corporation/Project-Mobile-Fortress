import XCTest
@testable import MyGame

/// Exercises the pure-math step used by `PlayerNode.move(toward:deltaTime:)`
/// without spinning up SpriteKit — mirrors testing the Android `Ball`
/// entity's bounds/velocity math on the JVM without an emulator.
final class PhysicsMathTests: XCTestCase {
    func testPlayerMovesTowardTargetWithoutOvershooting() {
        let player = PlayerNode()
        player.position = .zero

        player.move(toward: CGPoint(x: 5, y: 0), deltaTime: 1.0 / 60.0)

        XCTAssertGreaterThan(player.position.x, 0)
        XCTAssertLessThanOrEqual(player.position.x, 5)
    }

    func testPlayerDoesNotMoveWhenAlreadyAtTarget() {
        let player = PlayerNode()
        player.position = CGPoint(x: 10, y: 10)

        player.move(toward: CGPoint(x: 10, y: 10), deltaTime: 1.0 / 60.0)

        XCTAssertEqual(player.position, CGPoint(x: 10, y: 10))
    }
}
