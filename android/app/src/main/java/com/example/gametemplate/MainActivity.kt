package com.example.gametemplate

import android.os.Bundle
import androidx.activity.ComponentActivity

/**
 * Hosts the [GameView] game surface and wires the Android lifecycle to it.
 *
 * This template intentionally does not route the game surface through Compose
 * (see `.agent/AGENTS.md` §1.1 and `docs/adr/0002-rendering-approach.md`) —
 * [GameView] is set directly as the content view. Compose is reserved for
 * chrome around the game surface (see `ui/`), added via separate screens/
 * activities as the game grows past this single-surface skeleton.
 */
class MainActivity : ComponentActivity() {
    private lateinit var gameView: GameView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        gameView = GameView(this)
        setContentView(gameView)
    }

    override fun onResume() {
        super.onResume()
        gameView.resumeLoop()
    }

    override fun onPause() {
        // Persist state and stop the render thread before the framework can
        // kill this process — onStop() is not guaranteed to run first.
        gameView.saveState()
        gameView.pause()
        super.onPause()
    }
}
