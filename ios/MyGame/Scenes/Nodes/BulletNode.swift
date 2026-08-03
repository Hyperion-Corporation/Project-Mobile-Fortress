import SpriteKit

/// A player-fired projectile that travels straight upward at a constant
/// speed. Like `EnemyNode`, it reports off-screen exit rather than
/// self-removing, so `GameScene` owns all node-list mutation in one place.
final class BulletNode: SKSpriteNode {
    static let size = CGSize(width: 6, height: 14)

    convenience init() {
        self.init(color: .white, size: BulletNode.size)
        name = "bullet"
        physicsBody = SKPhysicsBody(rectangleOf: BulletNode.size)
        physicsBody?.categoryBitMask = PhysicsCategory.bullet
        physicsBody?.contactTestBitMask = PhysicsCategory.enemy
        physicsBody?.collisionBitMask = PhysicsCategory.none
        physicsBody?.affectedByGravity = false
    }

    /// Returns `true` once the bullet has traveled off the top of the scene.
    func advance(deltaTime: TimeInterval, sceneHeight: CGFloat) -> Bool {
        position.y += GameConstants.bulletSpeed * CGFloat(deltaTime)
        return position.y > sceneHeight + BulletNode.size.height
    }
}
