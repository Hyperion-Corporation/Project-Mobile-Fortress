package com.example.gametemplate.engine

import android.content.Context
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

/**
 * Serializable snapshot of everything needed to resume a game session after
 * process death — the save/restore boundary for the whole app. Extend this
 * with real progression fields (level, score, inventory) as gameplay grows.
 *
 * Kept as a plain data class with no Android framework dependency so it stays
 * trivially unit-testable; [saveTo]/[loadFrom] are the only pieces that touch
 * [Context].
 */
@Serializable
data class GameState(
    val ballX: Float,
    val ballY: Float,
    val ballVelocityX: Float,
    val ballVelocityY: Float,
    val score: Int = 0,
) {
    fun saveTo(context: Context) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_STATE, Json.encodeToString(serializer(), this))
            .apply()
    }

    companion object {
        private const val PREFS_NAME = "game_state"
        private const val KEY_STATE = "state_json"

        /** Default starting state for a fresh game. */
        fun default(): GameState =
            GameState(
                ballX = 200f,
                ballY = 200f,
                ballVelocityX = 220f,
                ballVelocityY = 160f,
                score = 0,
            )

        /**
         * Restores the last saved state, or [default] if none exists / the saved
         * JSON fails to parse (e.g. after a save-format migration).
         */
        fun loadFrom(context: Context): GameState {
            val json =
                context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                    .getString(KEY_STATE, null) ?: return default()
            return runCatching { Json.decodeFromString(serializer(), json) }
                .getOrElse { default() }
        }
    }
}
