import SpriteKit

/// The core gameplay scene. Owns the per-frame update loop, delegating
/// physics resolution to `PhysicsCollisionHandler` and input to
/// `TouchInputHandler` — the SpriteKit/iOS counterpart to Android's
/// `GameView` + `GameLoop` + `GameEngine` trio. Unlike the Android
/// implementation (a hand-rolled fixed-timestep thread, since `SurfaceView`
/// gives you nothing for free), SpriteKit already drives `update(_:)` off
/// the display link; we still clamp the per-frame delta to guard against
/// spiral-of-death after a long pause. See
/// `docs/adr/0003-ios-rendering-approach.md`.
final class GameScene: SKScene {
    private let inputHandler = TouchInputHandler()
    private let collisionHandler = PhysicsCollisionHandler()

    private var player: PlayerNode!
    private var lastUpdateTime: TimeInterval?
    private var enemySpawnAccumulator: TimeInterval = 0
    private let enemySpawnInterval: TimeInterval = 1.2

    override func didMove(to view: SKView) {
        backgroundColor = .black
        physicsWorld.contactDelegate = collisionHandler
        physicsWorld.gravity = .zero
        collisionHandler.gameManager = GameManager.shared

        let border = SKPhysicsBody(edgeLoopFrom: frame)
        border.categoryBitMask = PhysicsCategory.wall
        physicsBody = border

        player = PlayerNode()
        player.position = CGPoint(x: frame.midX, y: frame.minY + 80)
        addChild(player)

        inputHandler.onTap = { [weak self] _ in self?.fireBullet() }
        AudioManager.shared.playMusic(named: "background_loop")
    }

    override func update(_ currentTime: TimeInterval) {
        defer { lastUpdateTime = currentTime }
        guard case .playing = GameManager.shared.state else { return }

        let rawDelta = lastUpdateTime.map { currentTime - $0 } ?? 0
        let deltaTime = min(rawDelta, GameConstants.maxFrameDelta)

        if let target = inputHandler.moveTarget {
            player.move(toward: CGPoint(x: target.x, y: player.position.y), deltaTime: deltaTime)
        }

        advanceBullets(deltaTime: deltaTime)
        advanceEnemies(deltaTime: deltaTime)
        spawnEnemiesIfNeeded(deltaTime: deltaTime)
    }

    // MARK: - Input forwarding (called from GameSceneRepresentable)

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        inputHandler.touchesBegan(touches, in: self)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        inputHandler.touchesMoved(touches, in: self)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        inputHandler.touchesEnded(touches, in: self)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        inputHandler.touchesCancelled(touches, in: self)
    }

    // MARK: - Gameplay

    private func fireBullet() {
        guard case .playing = GameManager.shared.state else { return }
        let bullet = BulletNode()
        bullet.position = CGPoint(x: player.position.x, y: player.position.y + PlayerNode.size.height)
        addChild(bullet)
        AudioManager.shared.playEffect(named: "shoot")
    }

    private func advanceBullets(deltaTime: TimeInterval) {
        for case let bullet as BulletNode in children where bullet.name == "bullet" {
            if bullet.advance(deltaTime: deltaTime, sceneHeight: frame.height) {
                bullet.safeRemoveFromParent()
            }
        }
    }

    private func advanceEnemies(deltaTime: TimeInterval) {
        for case let enemy as EnemyNode in children where enemy.name == "enemy" {
            if enemy.advance(deltaTime: deltaTime) {
                enemy.safeRemoveFromParent()
            }
        }
    }

    private func spawnEnemiesIfNeeded(deltaTime: TimeInterval) {
        enemySpawnAccumulator += deltaTime
        guard enemySpawnAccumulator >= enemySpawnInterval else { return }
        enemySpawnAccumulator = 0

        let enemy = EnemyNode()
        enemy.position = CGPoint(x: .random(in: frame.minX...frame.maxX), y: frame.maxY + EnemyNode.size.height)
        addChild(enemy)
    }
}
