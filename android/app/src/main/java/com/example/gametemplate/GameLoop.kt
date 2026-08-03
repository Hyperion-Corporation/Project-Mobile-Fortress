package com.example.gametemplate

import android.graphics.Canvas
import android.util.Log
import android.view.SurfaceHolder
import com.example.gametemplate.engine.GameEngine

/**
 * Fixed-timestep update, variable-rate render loop running on its own [Thread].
 *
 * This is deliberately a plain thread, not a coroutine — a game loop wants
 * predictable, low-overhead wake/sleep timing, not a dispatcher's scheduling
 * heuristics. See `.agent/rules/game_loop_performance.md`.
 *
 * The accumulator pattern decouples simulation correctness from the device's
 * actual refresh rate: [engine]'s `update()` always advances by exactly
 * [FIXED_DELTA_MS], however many times are needed to catch up to real time,
 * capped by [MAX_CATCHUP_STEPS] so a long GC pause or debugger breakpoint
 * can't cause a "spiral of death".
 */
class GameLoop(
    private val surfaceHolder: SurfaceHolder,
    private val engine: GameEngine,
) : Thread("GameLoop") {
    @Volatile
    var running: Boolean = false

    override fun run() {
        var accumulatorMs = 0f
        var lastFrameTimeNs = System.nanoTime()

        while (running) {
            val nowNs = System.nanoTime()
            val frameDeltaMs = (nowNs - lastFrameTimeNs) / NANOS_PER_MILLI
            lastFrameTimeNs = nowNs
            accumulatorMs += frameDeltaMs

            var steps = 0
            while (accumulatorMs >= FIXED_DELTA_MS && steps < MAX_CATCHUP_STEPS) {
                engine.update(FIXED_DELTA_MS)
                accumulatorMs -= FIXED_DELTA_MS
                steps++
            }
            if (steps == MAX_CATCHUP_STEPS) {
                // We couldn't keep up (e.g. a long pause) — drop the remainder
                // instead of spiraling into simulating minutes of missed time.
                accumulatorMs = 0f
            }

            renderFrame()
        }
    }

    private fun renderFrame() {
        var canvas: Canvas? = null
        try {
            canvas = surfaceHolder.lockCanvas() ?: return
            synchronized(surfaceHolder) {
                engine.render(canvas)
            }
        } catch (e: IllegalStateException) {
            // Surface was torn down mid-frame (e.g. rotation/backgrounding race) — skip this frame.
            Log.w(TAG, "Skipped a frame: surface unavailable", e)
        } finally {
            if (canvas != null) {
                try {
                    surfaceHolder.unlockCanvasAndPost(canvas)
                } catch (e: IllegalStateException) {
                    Log.w(TAG, "Failed to post frame", e)
                }
            }
        }
    }

    private companion object {
        const val TAG = "GameLoop"
        const val TARGET_UPDATES_PER_SECOND = 60f
        const val FIXED_DELTA_MS = 1000f / TARGET_UPDATES_PER_SECOND
        const val MAX_CATCHUP_STEPS = 5
        const val NANOS_PER_MILLI = 1_000_000f
    }
}
