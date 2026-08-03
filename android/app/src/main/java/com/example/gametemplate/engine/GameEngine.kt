package com.example.gametemplate.engine

import android.graphics.Canvas
import android.graphics.Color
import com.example.gametemplate.engine.entities.Ball
import com.example.gametemplate.engine.entities.Entity

/**
 * Orchestrates per-frame update/render across all live [Entity] instances.
 *
 * Deliberately framework-light: it only needs a [Canvas] to render and plain
 * ints for viewport bounds, so it's unit-testable on the JVM without
 * Robolectric or an emulator. See `app/src/test/.../GameEngineTest.kt`.
 */
class GameEngine(initialState: GameState) {
    private var boundsWidth: Int = 0
    private var boundsHeight: Int = 0

    private val ball =
        Ball(
            x = initialState.ballX,
            y = initialState.ballY,
            radiusPx = BALL_RADIUS_PX,
            velocityX = initialState.ballVelocityX,
            velocityY = initialState.ballVelocityY,
        )

    private val entities: List<Entity> = listOf(ball)

    var score: Int = initialState.score
        private set

    /** Must be called whenever the render surface size changes (creation, rotation). */
    fun resize(
        width: Int,
        height: Int,
    ) {
        boundsWidth = width
        boundsHeight = height
    }

    /** Advances every entity by exactly [deltaMs]. Called from the fixed-timestep accumulator. */
    fun update(deltaMs: Float) {
        for (entity in entities) {
            entity.update(deltaMs, boundsWidth, boundsHeight)
        }
    }

    /** Draws the current frame. Called once per render pass, never mutates state. */
    fun render(canvas: Canvas) {
        canvas.drawColor(BACKGROUND_COLOR)
        for (entity in entities) {
            entity.render(canvas)
        }
    }

    /** Captures the current simulation state for persistence. */
    fun captureState(): GameState =
        GameState(
            ballX = ball.x,
            ballY = ball.y,
            ballVelocityX = ball.velocityX,
            ballVelocityY = ball.velocityY,
            score = score,
        )

    private companion object {
        const val BALL_RADIUS_PX = 40f
        val BACKGROUND_COLOR = Color.parseColor("#101418")
    }
}
