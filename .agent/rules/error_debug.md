# Error & Debug Rules

- Reproduce Android-specific bugs with the exact API level and screen density from the bug report first — `SurfaceView` timing and touch-input quirks vary meaningfully across OEM skins and API levels; "works on my emulator" is not a fix.
- For crashes, get the full stack trace via `adb logcat -s AndroidRuntime:E` or the crash report; don't guess from a truncated message.
- For frame-drop/jank reports, profile with Android Studio's CPU Profiler or Perfetto before changing code — see [`game_loop_performance.md`](game_loop_performance.md) for the usual suspects (per-frame allocation, main-thread I/O).
- For `SurfaceView` lifecycle crashes (`lockCanvas` on a destroyed surface, thread leaks), check `surfaceCreated`/`surfaceDestroyed` pairing first — see [`android_lifecycle.md`](android_lifecycle.md).
- Never swallow an exception silently in `catch` blocks around game-state I/O — log it and fail visibly in debug builds (`BuildConfig.DEBUG` gated), degrade gracefully (fresh state) in release builds.
- When a bug only reproduces on a real device (sensor input, thermal throttling affecting frame pacing), say so explicitly rather than "cannot reproduce" — note it for someone with the physical device.
