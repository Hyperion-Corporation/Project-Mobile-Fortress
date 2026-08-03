# Skill: Debug Frame Drops / Jank

1. Reproduce on a real mid-range device if at all possible — emulator GPU/CPU profiles are not representative of frame pacing.
2. Profile with Android Studio's CPU Profiler or Perfetto (`adb shell perfetto ...` or the Studio UI) — capture a trace during the janky segment, not the whole session.
3. Check the two highest-frequency causes first: an allocation inside `GameLoop.update()`/`render()` (search the diff/file for `new`, list/map literals, `Rect(...)`, `Paint()` inside the hot path), or a blocking I/O/bitmap-decode call on the render thread or main thread.
4. If the trace shows GC pauses, grep `engine/` for per-frame allocations and hoist them to pre-allocated fields.
5. If the trace shows a long single frame, check for main-thread work being dispatched synchronously (e.g. `SharedPreferences.getString` on every frame instead of a cached value).
6. Fix, re-profile to confirm the specific bottleneck is gone, and add a regression test if the bug was in deterministic logic (e.g. the accumulator cap).
