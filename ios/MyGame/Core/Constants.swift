import CoreGraphics

/// Global tuning constants and physics collision categories. Keep gameplay
/// numbers here rather than scattered as magic numbers in scene/node code —
/// mirrors the `companion object` constant blocks in the Kotlin `GameEngine`
/// and `GameLoop`.
enum GameConstants {
    /// Target simulation rate. SpriteKit's `update(_:)` is display-refresh
    /// driven rather than a fixed-timestep thread like Android's `GameLoop`,
    /// but we still clamp/report against this for parity in telemetry and
    /// to bound a single frame's simulated delta (see `GameScene.update`).
    static let targetUpdatesPerSecond: Double = 60
    static let maxFrameDelta: TimeInterval = 1.0 / 20.0 // clamp long pauses (breakpoints, backgrounding)

    static let ballRadius: CGFloat = 18
    static let ballInitialVelocity = CGVector(dx: 220, dy: 160)

    static let playerMoveSpeed: CGFloat = 260
    static let bulletSpeed: CGFloat = 480
    static let enemySpeed: CGFloat = 80
}

/// Bitmask categories for `SKPhysicsBody.categoryBitMask` / `contactTestBitMask`.
/// See `Engine/Physics/PhysicsCollisionHandler.swift` for how these combine.
enum PhysicsCategory {
    static let none: UInt32 = 0
    static let player: UInt32 = 0x1 << 0
    static let enemy: UInt32 = 0x1 << 1
    static let bullet: UInt32 = 0x1 << 2
    static let wall: UInt32 = 0x1 << 3
    static let all: UInt32 = .max
}
