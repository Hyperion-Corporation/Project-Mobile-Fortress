import SpriteKit

/// A simple enemy that drifts downward at a constant speed and removes itself
/// once off-screen (in case it's never hit) — mirrors `Ball`'s bounds-check
/// pattern in the Kotlin `engine/entities/Ball.kt`.
final class EnemyNode: SKSpriteNode {
    static let size = CGSize(width: 28, height: 28)

    convenience init() {
        self.init(color: .systemRed, size: EnemyNode.size)
        name = "enemy"
        physicsBody = SKPhysicsBody(circleOfRadius: EnemyNode.size.width / 2)
        physicsBody?.categoryBitMask = PhysicsCategory.enemy
        physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.bullet
        physicsBody?.collisionBitMask = PhysicsCategory.none
        physicsBody?.affectedByGravity = false
    }

    /// Advances the enemy and reports whether it drifted past `sceneHeight`
    /// (bottom edge), letting the caller decide cleanup — this node never
    /// removes itself directly, keeping ownership/cleanup centralized in
    /// `GameScene.update`.
    func advance(deltaTime: TimeInterval) -> Bool {
        position.y -= GameConstants.enemySpeed * CGFloat(deltaTime)
        return position.y < -EnemyNode.size.height
    }
}
