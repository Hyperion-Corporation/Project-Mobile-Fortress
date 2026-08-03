import SpriteKit

/// Translates raw touch events (forwarded from `GameScene.touchesBegan/Moved/Ended`)
/// into a simple continuous "move toward this point" signal, plus a tap
/// callback for discrete actions (e.g. firing). Kept separate from `GameScene`
/// so input handling stays independently testable and swappable (e.g. for a
/// virtual joystick later) — mirrors the separation between Android's
/// `GameView` (owns the surface) and a dedicated input package.
final class TouchInputHandler {
    private(set) var moveTarget: CGPoint?

    /// Called once per discrete tap (a touch that ends without having moved
    /// past `tapMovementTolerance`).
    var onTap: ((CGPoint) -> Void)?

    private var touchStartLocation: CGPoint?
    private let tapMovementTolerance: CGFloat = 12

    func touchesBegan(_ touches: Set<UITouch>, in scene: SKScene) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: scene)
        touchStartLocation = location
        moveTarget = location
    }

    func touchesMoved(_ touches: Set<UITouch>, in scene: SKScene) {
        guard let touch = touches.first else { return }
        moveTarget = touch.location(in: scene)
    }

    func touchesEnded(_ touches: Set<UITouch>, in scene: SKScene) {
        defer {
            moveTarget = nil
            touchStartLocation = nil
        }
        guard let touch = touches.first, let start = touchStartLocation else { return }
        let end = touch.location(in: scene)
        let distance = hypot(end.x - start.x, end.y - start.y)
        if distance <= tapMovementTolerance {
            onTap?(end)
        }
    }

    func touchesCancelled(_ touches: Set<UITouch>, in scene: SKScene) {
        moveTarget = nil
        touchStartLocation = nil
    }
}
