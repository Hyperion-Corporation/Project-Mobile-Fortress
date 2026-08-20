---
### SUBAGENT DELEGATION PROTOCOL: CLAUDE

**Identity & Capability:**
You can deploy a Claude AI subagent via the local terminal using the `claude` CLI command. Claude is a stateless worker that excels at deep refactoring, nuanced code generation, and complex technical writing.

**When to Delegate:**
Invoke the Claude subagent for:
*   **Deep Refactoring:** Managing RAII/ownership discipline in the planned C++20 shared simulation core (`game/`, EnTT ECS + FlatBuffers — see `docs/moon/roadmaps/shared_core.md`), or Kotlin/Swift game-loop internals (`android/app/.../GameLoop.kt`, `ios/MyGame/Scenes/GameLevel/GameScene.swift`).
*   **UI/Frontend Generation:** Generating structured TypeScript/React code for `docs/website/` (the multi-framework docs portal and internal dashboard — see `docs/moon/roadmaps/internal_dashboard.md`).
*   **Granular Code Review:** Performing rigorous audits of Flow Field pathfinding, GA layout optimization, or netcode client-prediction/reconciliation logic.

**Execution Syntax:**
Run the command in your shell, wrapping the prompt in strong quotes.
`claude 'YOUR_COMPREHENSIVE_PROMPT_HERE'`

**Subagent Prompting Rules (How to talk to Claude):**
1.  **Complete Independence:** Claude cannot read your memory. You MUST provide the exact code block or exact error logs it needs to act upon.
2.  **ReAct / CoT Triggers:** Instruct Claude to use `<thinking>` XML blocks to plan its refactoring steps before outputting code.
3.  **Strict Boundaries:** Specify exact input and output formats (e.g., "Output ONLY valid Rust code inside a single markdown block").

**Example Usage:**
`claude 'Act as an expert Android game engineer. Refactor the following Kotlin GameLoop fixed-timestep implementation (SurfaceView + a dedicated thread) to eliminate per-frame allocations in the update/render hot path. Ensure surfaceCreated/surfaceDestroyed still correctly start/stop the thread. Wrap your reasoning in <thinking> tags, then provide the refactored code. Code to refactor: [INSERT_CODE_HERE]'`

**Failure Modes to Avoid:**
*   **Do not** include single quotes inside the prompt string without escaping them.
*   **Do not** delegate tasks that require multi-turn conversational context.
---