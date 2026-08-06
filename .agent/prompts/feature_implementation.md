# Prompt: Feature Implementation

Use when asked to implement a new gameplay feature or screen.

---

1. Restate the feature in one paragraph and identify which layer(s) it touches: `engine/` (simulation), `GameView`/`GameLoop` (rendering/timing), `ui/` (Compose chrome), or `infra/` (backend — confirm this is actually in scope before touching it).
2. Check `docs/moon/roadmaps/gameplay.md` (or the relevant roadmap file) and `docs/adr/` for prior decisions that constrain the design.
3. Follow the matching workflow in `.agent/workflows/` (`game_loop_performance.md` for engine work, `ui_compose.md` for screens, `android_lifecycle.md` if it touches save state or thread lifecycle).
4. Implement with a test alongside — unit test for `engine/` logic, instrumented/Compose test for UI.
5. Update `docs/ARCHITECTURE.md` and `docs/moon/CHANGELOG.md` if the feature changes module boundaries or ships user-visible behavior.
6. Run `just unit-test`, `just lint-check`, and `just install` for a manual sanity pass before calling it done.
