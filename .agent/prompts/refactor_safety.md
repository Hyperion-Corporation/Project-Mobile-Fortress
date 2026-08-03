# Prompt: Safe Refactor

Use when asked to refactor existing code (e.g. `GameLoop`, `GameEngine`, entity classes) without changing behavior.

---

1. Confirm test coverage exists for the current behavior before refactoring; add characterization tests first if it doesn't (see `.agent/rules/testing_qa.md`).
2. Make the smallest change that achieves the refactor's stated goal — resist opportunistic rewrites of adjacent code.
3. Re-run `just unit-test` (and `just test-instrumented` if lifecycle/UI code was touched) after each meaningful step, not just at the end.
4. For `GameLoop`/`engine/` changes specifically, re-profile (see `.agent/rules/game_loop_performance.md`) to confirm the refactor didn't introduce new per-frame allocations.
5. Call out any behavior change you couldn't avoid, however small, rather than letting it hide inside a "pure" refactor.
