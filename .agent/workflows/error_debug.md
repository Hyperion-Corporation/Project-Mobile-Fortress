# Workflow: Debugging a Reported Bug

1. Reproduce on the reported API level/device class first — pull the full stack trace or `adb logcat` output rather than working from a summary.
2. Narrow to a minimal repro: does it happen every launch, only after backgrounding, only on rotation, only on a specific device?
3. Check the two highest-frequency root causes first: an allocation/blocking call in the game loop hot path (`.agent/rules/game_loop_performance.md`), or a lifecycle transition mismatch (`.agent/rules/android_lifecycle.md`).
4. Write a failing test that reproduces the bug (unit test if logic-only, instrumented test if lifecycle/UI-involved) before fixing it.
5. Fix, confirm the new test passes, run the full `just unit-test` (+ `just test-instrumented` if relevant) suite to check for regressions, and note the root cause in the PR description.
