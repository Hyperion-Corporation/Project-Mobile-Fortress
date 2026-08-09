---
### SUBAGENT DELEGATION PROTOCOL: CHATGPT

**Identity & Capability:**
You can orchestrate a ChatGPT AI subagent via your local terminal using the `chatgpt` CLI command. ChatGPT acts as a stateless, highly capable reasoning engine. It does not share your context window.

**When to Delegate:**
Invoke the ChatGPT subagent for:
*   **Mathematical Formulations:** Drafting formal definitions for the Flow Field pathfinding cost function, the GA fitness function used in HQ-layout optimization, or CMAB reward models for offer personalization (see `docs/moon/roadmaps/ai_systems.md`).
*   **Literature & Concept Mapping:** Summarizing classical pathfinding/PCG algorithms (Dijkstra variants, Wave Function Collapse) or mapping them onto Mobile Fortress's specific coastal-fortress-defense mechanics.
*   **Creative Brainstorming:** Generating varied approaches to a design problem (e.g. Resource vs. Trading Outpost economy balance) before committing to an implementation.

**Execution Syntax:**
Run the command in your shell, wrapping the prompt in strong quotes to prevent shell evaluation errors.
`chatgpt 'YOUR_COMPREHENSIVE_PROMPT_HERE'`

**Subagent Prompting Rules (How to talk to ChatGPT):**
1.  **Zero-Shot Context:** You MUST include all necessary definitions, constraints, and current state.
2.  **Constraint Pattern:** Explicitly list what ChatGPT must *not* do to keep the response focused and token-efficient.
3.  **Role Definition:** Always assign ChatGPT a clear persona (e.g., "Act as a PhD-level Operations Research scientist").

**Example Usage:**
`chatgpt 'Act as an algorithms expert. I am implementing a Genetic Algorithm to optimize HQ/Citadel outpost layout in a coastal tower-defense game (Mobile Fortress). Provide the formal fitness-function formulation balancing raid-lane coverage against build cost, for a fixed-size grid of candidate outpost positions. Rules: 1. Use standard GA notation (chromosome, fitness, selection). 2. Define all variables clearly. 3. Output ONLY the formulation and variable definitions in plain text.'`

**Failure Modes to Avoid:**
*   **Do not** use unescaped single quotes inside the `chatgpt` command string.
*   **Do not** assume ChatGPT knows our current project state.
*   **Do not** delegate tasks requiring direct file manipulation.
---