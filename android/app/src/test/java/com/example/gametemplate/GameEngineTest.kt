package com.example.gametemplate

import com.example.gametemplate.engine.GameEngine
import com.example.gametemplate.engine.GameState
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

/**
 * Pure-JVM unit tests for [GameEngine] — no Android framework classes involved,
 * per `.agent/rules/testing_qa.md`.
 */
class GameEngineTest {
    private lateinit var engine: GameEngine

    @Before
    fun setUp() {
        // ballVelocityX is in px/sec.
        engine =
            GameEngine(
                GameState(
                    ballX = 100f,
                    ballY = 100f,
                    ballVelocityX = 100f,
                    ballVelocityY = 0f,
                    score = 0,
                ),
            )
        engine.resize(400, 400)
    }

    @Test
    fun `update advances ball position by velocity times elapsed time`() {
        // 500ms at 100px/sec on X should move the ball 50px right.
        engine.update(500f)

        val state = engine.captureState()
        assertEquals(150f, state.ballX, 0.01f)
        assertEquals(100f, state.ballY, 0.01f)
    }

    @Test
    fun `ball bounces off the right bound and reverses X velocity`() {
        // Ball starts near the right edge with radius 40 in a 400-wide viewport;
        // a large update step should push it past the bound and force a bounce.
        engine.update(10_000f)

        val state = engine.captureState()
        assertTrue("ball X should be clamped within bounds", state.ballX <= 400f)
        assertTrue("X velocity should have reversed to negative after bouncing", state.ballVelocityX < 0f)
    }

    @Test
    fun `captureState round-trips through GameState serialization-relevant fields`() {
        engine.update(250f)
        val captured = engine.captureState()

        val restoredEngine = GameEngine(captured)
        restoredEngine.resize(400, 400)
        val reCaptured = restoredEngine.captureState()

        assertEquals(captured.ballX, reCaptured.ballX, 0.01f)
        assertEquals(captured.ballY, reCaptured.ballY, 0.01f)
        assertEquals(captured.ballVelocityX, reCaptured.ballVelocityX, 0.01f)
        assertEquals(captured.ballVelocityY, reCaptured.ballVelocityY, 0.01f)
    }
}
