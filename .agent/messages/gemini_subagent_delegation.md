---
### SUBAGENT DELEGATION PROTOCOL: GEMINI

**Identity & Capability:**
You have the authority to spawn a Gemini AI subagent via the terminal using the `agy` CLI command. Gemini operates independently, statelessly, and processes large contexts with high efficiency.

**When to Delegate:**
Invoke the Gemini subagent for:
*   **Data Pipeline Construction:** Parsing `docs/moon/ROADMAP.md`/`CHANGELOG.md` tables or large CI/instrumented-test logs into structured summaries (see `git/scripts/sync_backlog.py`, which itself calls Gemini for this).
*   **Cross-Language Boilerplate:** Generating the JNI (Android) or Swift C++-interop binding architecture between the game clients and the planned shared C++ simulation core (`game/`, see `docs/moon/roadmaps/shared_core.md`).
*   **System Architecture:** Designing the server-authoritative Co-Op netcode / matchmaking flow (`docs/moon/roadmaps/backend.md`) or extracting structured metrics from Firebase Test Lab / Crashlytics output.

**Execution Syntax:**
Execute the command in your terminal. Ensure the prompt is enclosed in single quotes.
`agy 'YOUR_COMPREHENSIVE_PROMPT_HERE'`

**Subagent Prompting Rules (How to talk to Gemini):**
1.  **Explicit Context:** Provide all required schemas, data samples, and environmental constraints (e.g., Linux, KDE, specific GPU hardware).
2.  **Template Pattern:** Dictate the exact output structure using a template to ensure the response can be easily parsed or piped into another tool.
3.  **Action-Oriented Verbs:** Start instructions with clear directives like "Analyze," "Generate," or "Extract."

**Example Usage:**
`agy 'Act as an expert systems architect. Design the JNI binding surface between android/app/'s Kotlin client and a future C++20 shared simulation core (EnTT ECS, FlatBuffers zero-copy state). Keep the FFI surface intentionally small and hand-reviewable — no automated binding generator. Constraints: 1. Output only the interface/header sketch. 2. Note which calls must be off the render thread. Context: [INSERT_CURRENT_GAMELOOP_STATE]'`

**Failure Modes to Avoid:**
*   **Do not** use unescaped single quotes in the `agy` execution string.
*   **Do not** expect Gemini to read files from the disk automatically unless you ask it to generate the shell commands to do so.
---