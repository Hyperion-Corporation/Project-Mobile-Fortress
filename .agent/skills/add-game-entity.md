# Skill: Add a New Game Entity

## Android

1. Create the entity class under `android/app/src/main/java/com/example/gametemplate/engine/entities/`, implementing the same `update(deltaMs: Float)` / `render(canvas: Canvas, paint: Paint)` contract as `Ball.kt`.
2. Pre-allocate any `Rect`/`Paint`/scratch objects the entity needs as constructor-time `private val` fields — never inside `update()`/`render()` (see [`.agent/rules/game_loop_performance.md`](../rules/game_loop_performance.md)).
3. Register the entity with `GameEngine` (add to its entity collection, wire spawn/despawn logic).
4. Add a unit test under `android/app/src/test/java/com/example/gametemplate/` asserting the entity's update math (e.g. position after N steps, collision response).
5. Run `just unit-test`; if the entity is visually verified, `just install` and eyeball it in the running app.

## iOS

1. Create the entity class under `ios/MyGame/Scenes/Nodes/`, as an `SKSpriteNode` subclass following the same shape as `EnemyNode.swift`/`BulletNode.swift`: a `convenience init()` setting up appearance + `physicsBody` (category/contact/collision bitmasks from `Core/Constants.swift`), and an `advance(deltaTime:) -> Bool` method that mutates `position` and returns whether the caller should remove it — the node never removes itself (see [`.agent/rules/game_loop_performance.md`](../rules/game_loop_performance.md)).
2. Wire spawn logic into `GameScene` (a `spawn...IfNeeded` method following `spawnEnemiesIfNeeded`'s shape) and advance/cleanup logic into `GameScene.update(_:)` (following `advanceEnemies`/`advanceBullets`).
3. If the entity participates in collisions, add its category to `PhysicsCategory` (`Core/Constants.swift`) and a case in `PhysicsCollisionHandler.didBegin(_:)`.
4. Add a test in `ios/Tests/` asserting the entity's pure movement math (see `PhysicsMathTests.swift` for the pattern — construct the node directly, no live `SKScene`/physics simulation needed for position math).
5. Run `just ios-test`; if the entity is visually verified, run via Xcode in the Simulator and eyeball it.

## If the entity should exist conceptually on both platforms

Update [`core/src/game-state-machine.md`](../../core/src/game-state-machine.md) if it affects game state, and implement it independently on both platforms — there is no shared entity code (see [`core/README.md`](../../core/README.md)). Keep the two implementations' *behavior* in sync (speed, size, scoring), not their code.
