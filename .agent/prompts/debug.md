# Prompt: Debug a Reported Issue

Use when asked to investigate a crash, jank/frame-drop report, or incorrect game behavior.

---

Follow [`.agent/workflows/error_debug.md`](../workflows/error_debug.md):

1. Get the exact repro steps, device/API level, and full stack trace or logcat output — don't start from a paraphrase.
2. Check the two highest-frequency root causes first: game-loop hot-path allocation/blocking calls, or a lifecycle transition mismatch.
3. Write a failing test that reproduces the issue before fixing it.
4. Fix, verify the new test passes plus the full suite, and summarize root cause + fix in plain language.
