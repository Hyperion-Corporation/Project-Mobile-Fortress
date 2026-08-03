# Android Lifecycle Rules

Applies to `MainActivity.kt`, `GameView.kt`, and anything that owns a thread, sensor listener, or system resource tied to the app being visible/foregrounded.

- The `GameLoop` thread starts in `surfaceCreated()` and must be joined (not just flagged) in `surfaceDestroyed()` before that callback returns — a leaked render thread after the `Surface` is gone crashes on the next `lockCanvas()`.
- Mirror `SurfaceView` lifecycle with the `Activity`: pause the loop in `onPause()`, resume in `onResume()`. Don't rely on `surfaceDestroyed`/`surfaceCreated` alone — some OEM/multi-window transitions call one without the other.
- Persist game state in `onPause()` (not `onStop()` — the process can be killed without `onStop()` running on some Android versions) via `GameState`'s save/restore path (see [`docs/ARCHITECTURE.md`](../../docs/ARCHITECTURE.md)). Restore it in `onCreate()`/`surfaceCreated()`.
- Unregister sensor listeners (accelerometer/gyroscope input, if used) in `onPause()` and re-register in `onResume()` — a registered listener while backgrounded drains battery and can hold a wakelock indirectly.
- Never do bitmap decoding, file I/O, or network calls on the main thread or inside a `Surface` callback — dispatch to a coroutine (`Dispatchers.IO`) or a background thread and post results back.
- Handle configuration changes (rotation) explicitly: either lock orientation in the manifest for the game screen (simplest, common for arcade-style games) or resize the game surface's logical viewport in `surfaceChanged()` — never assume a fixed width/height.

## Anti-patterns

- Starting the `GameLoop` thread in the `Activity`'s `onCreate()` before the `Surface` exists — `lockCanvas()` will throw or the thread will be stuck retrying.
- Reading `SharedPreferences`/saved game state synchronously on the main thread on every frame — load once, cache in memory, write back only on pause/checkpoints.
