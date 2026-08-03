import SpriteKit

/// The player-controlled node. Movement is driven externally by `GameScene`
/// feeding `TouchInputHandler.moveTarget` into `move(toward:deltaTime:)` each
/// frame, rather than the node polling input itself — keeps this class
/// testable without a live touch/scene pipeline.
final class PlayerNode: SKSpriteNode {
    static let size = CGSize(width: 36, height: 36)

    convenience init() {
        self.init(color: .systemBlue, size: PlayerNode.size)
        name = "player"
        physicsBody = SKPhysicsBody(circleOfRadius: PlayerNode.size.width / 2)
        physicsBody?.categoryBitMask = PhysicsCategory.player
        physicsBody?.contactTestBitMask = PhysicsCategory.enemy
        physicsBody?.collisionBitMask = PhysicsCategory.none
        physicsBody?.affectedByGravity = false
        physicsBody?.linearDamping = 0
    }

    /// Moves at most `GameConstants.playerMoveSpeed * deltaTime` toward
    /// `target`, so an old/stale target set right before a long frame can't
    /// teleport the player.
    func move(toward target: CGPoint, deltaTime: TimeInterval) {
        let dx = target.x - position.x
        let dy = target.y - position.y
        let distance = hypot(dx, dy)
        guard distance > 1 else { return }

        let maxStep = GameConstants.playerMoveSpeed * CGFloat(deltaTime)
        let step = min(maxStep, distance)
        position = CGPoint(
            x: position.x + dx / distance * step,
            y: position.y + dy / distance * step
        )
    }
}
