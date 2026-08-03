package com.example.gametemplate.engine.entities

import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint

/**
 * Minimal demo entity: a circle that bounces off the screen bounds at a constant
 * velocity. Stands in for real gameplay — replace with actual game objects.
 *
 * All drawing state ([paint]) is allocated once at construction time and reused
 * every frame, per `.agent/rules/game_loop_performance.md`.
 */
class Ball(
    var x: Float,
    var y: Float,
    private val radiusPx: Float,
    velocityX: Float,
    velocityY: Float,
    color: Int = Color.parseColor("#4CC9F0"),
) : Entity {
    /** Current velocity, exposed read-only so [com.example.gametemplate.engine.GameEngine] can persist it. */
    var velocityX: Float = velocityX
        private set
    var velocityY: Float = velocityY
        private set

    private val paint =
        Paint(Paint.ANTI_ALIAS_FLAG).apply {
            this.color = color
            style = Paint.Style.FILL
        }

    override fun update(
        deltaMs: Float,
        boundsWidth: Int,
        boundsHeight: Int,
    ) {
        if (boundsWidth <= 0 || boundsHeight <= 0) return

        val deltaSeconds = deltaMs / MILLIS_PER_SECOND
        x += velocityX * deltaSeconds
        y += velocityY * deltaSeconds

        if (x - radiusPx < 0f) {
            x = radiusPx
            velocityX = -velocityX
        } else if (x + radiusPx > boundsWidth) {
            x = boundsWidth - radiusPx
            velocityX = -velocityX
        }

        if (y - radiusPx < 0f) {
            y = radiusPx
            velocityY = -velocityY
        } else if (y + radiusPx > boundsHeight) {
            y = boundsHeight - radiusPx
            velocityY = -velocityY
        }
    }

    override fun render(canvas: Canvas) {
        canvas.drawCircle(x, y, radiusPx, paint)
    }

    private companion object {
        const val MILLIS_PER_SECOND = 1000f
    }
}
