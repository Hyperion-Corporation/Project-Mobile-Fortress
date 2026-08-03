package com.example.gametemplate

import androidx.lifecycle.Lifecycle
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Instrumented test skeleton: exercises real [android.app.Activity] lifecycle
 * transitions against [MainActivity] on a device/emulator, per
 * `.agent/rules/testing_qa.md`.
 */
@RunWith(AndroidJUnit4::class)
class MainActivityTest {
    @Test
    fun activityLaunchesAndHostsGameView() {
        ActivityScenario.launch(MainActivity::class.java).use { scenario ->
            scenario.onActivity { activity ->
                val contentRoot = activity.window.decorView.findViewById<android.view.View>(android.R.id.content)
                assertTrue(
                    "Activity's content view should be a GameView",
                    (contentRoot as? android.view.ViewGroup)?.getChildAt(0) is GameView,
                )
            }
        }
    }

    @Test
    fun activitySurvivesPauseResumeWithoutCrashing() {
        ActivityScenario.launch(MainActivity::class.java).use { scenario ->
            scenario.moveToState(Lifecycle.State.CREATED) // triggers onPause
            scenario.moveToState(Lifecycle.State.RESUMED) // triggers onResume
            // No assertion beyond "didn't throw" — this covers the GameLoop
            // thread start/stop pairing across a real lifecycle transition,
            // per .agent/rules/android_lifecycle.md.
        }
    }
}
