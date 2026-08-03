package com.example.gametemplate

import android.content.Context
import android.util.AttributeSet
import android.view.SurfaceHolder
import android.view.SurfaceView
import com.example.gametemplate.engine.GameEngine
import com.example.gametemplate.engine.GameState

/**
 * The game surface. Owns [GameLoop]'s lifecycle, mirroring [SurfaceHolder.Callback]
 * transitions so the render thread never touches a torn-down [android.view.Surface].
 *
 * See `.agent/rules/android_lifecycle.md` — the thread start/stop pairing here is
 * the most crash-sensitive part of this template.
 */
class GameView
    @JvmOverloads
    constructor(
        context: Context,
        attrs: AttributeSet? = null,
    ) : SurfaceView(context, attrs), SurfaceHolder.Callback {
        private val engine = GameEngine(GameState.loadFrom(context))
        private var gameLoop: GameLoop? = null

        init {
            holder.addCallback(this)
        }

        override fun surfaceCreated(holder: SurfaceHolder) {
            val loop = GameLoop(holder, engine)
            gameLoop = loop
            loop.running = true
            loop.start()
        }

        override fun surfaceChanged(
            holder: SurfaceHolder,
            format: Int,
            width: Int,
            height: Int,
        ) {
            engine.resize(width, height)
        }

        override fun surfaceDestroyed(holder: SurfaceHolder) {
            stopLoop()
        }

        /** Call from [android.app.Activity.onPause] in addition to relying on surface teardown. */
        fun pause() {
            stopLoop()
        }

        /** Call from [android.app.Activity.onResume]; a no-op if the surface isn't ready yet. */
        fun resumeLoop() {
            if (gameLoop == null && holder.surface.isValid) {
                surfaceCreated(holder)
            }
        }

        /** Persists the current simulation state — call from [android.app.Activity.onPause]. */
        fun saveState() {
            engine.captureState().saveTo(context)
        }

        private fun stopLoop() {
            val loop = gameLoop ?: return
            loop.running = false
            // join (not just flag) so a new loop is never started before the old
            // thread has actually released the surface — see android_lifecycle.md.
            var retry = true
            while (retry) {
                try {
                    loop.join()
                    retry = false
                } catch (e: InterruptedException) {
                    // Retry the join; don't leak the thread.
                }
            }
            gameLoop = null
        }
    }
