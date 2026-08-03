package com.example.gametemplate.engine.entities

import android.graphics.Canvas

/**
 * Contract for anything participating in [com.example.gametemplate.engine.GameEngine]'s
 * per-frame update/render cycle.
 *
 * Implementations must not allocate inside [update] or [render] — pre-allocate any
 * scratch objects (Paint, Rect, etc.) as constructor-time fields. See
 * `.agent/rules/game_loop_performance.md` for the rationale.
 */
interface Entity {
    /**
     * Advances this entity's simulation state by exactly [deltaMs] milliseconds.
     * Called zero or more times per frame by the fixed-timestep accumulator in
     * [com.example.gametemplate.GameLoop]. Must never touch a [Canvas].
     */
    fun update(
        deltaMs: Float,
        boundsWidth: Int,
        boundsHeight: Int,
    )

    /**
     * Draws this entity's current state to [canvas]. Called exactly once per frame.
     * Must never mutate simulation state.
     */
    fun render(canvas: Canvas)
}
