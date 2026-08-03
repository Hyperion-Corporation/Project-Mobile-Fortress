import SpriteKit

/// Central `SKPhysicsContactDelegate`. Keeping all contact-resolution logic
/// in one place (rather than scattered across node classes) makes the full
/// set of interactions auditable at a glance — see `.agent/rules/swift.md`
/// §Physics for the rationale, mirroring the Android
/// `Engine/Physics/` collision-bitmask convention.
final class PhysicsCollisionHandler: NSObject, SKPhysicsContactDelegate {
    weak var gameManager: GameManager?

    func didBegin(_ contact: SKPhysicsContact) {
        let categories = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask

        switch categories {
        case PhysicsCategory.bullet | PhysicsCategory.enemy:
            handleBulletHitEnemy(contact)
        case PhysicsCategory.player | PhysicsCategory.enemy:
            handlePlayerHitEnemy(contact)
        default:
            break
        }
    }

    private func handleBulletHitEnemy(_ contact: SKPhysicsContact) {
        let bulletNode = contact.bodyA.categoryBitMask == PhysicsCategory.bullet ? contact.bodyA.node : contact.bodyB.node
        let enemyNode = contact.bodyA.categoryBitMask == PhysicsCategory.enemy ? contact.bodyA.node : contact.bodyB.node

        bulletNode?.safeRemoveFromParent()
        enemyNode?.safeRemoveFromParent()
        AudioManager.shared.playEffect(named: "explosion")
        gameManager?.addScore(10)
    }

    private func handlePlayerHitEnemy(_ contact: SKPhysicsContact) {
        let enemyNode = contact.bodyA.categoryBitMask == PhysicsCategory.enemy ? contact.bodyA.node : contact.bodyB.node
        enemyNode?.safeRemoveFromParent()
        AudioManager.shared.playEffect(named: "hit")
        gameManager?.endGame()
    }
}
