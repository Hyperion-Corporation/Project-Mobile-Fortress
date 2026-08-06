# Prompt: Architecture Analysis

Use when asked to explain or evaluate the current architecture, or to assess the impact of a proposed change.

---

1. Read `docs/ARCHITECTURE.md`, `docs/adr/`, and `.agent/AGENTS.md` §3 (Module Boundaries) first — don't re-derive the architecture from source alone when a document already explains the intent.
2. Trace the actual code (`android/app/src/main/java/com/acfharbinger/mobilefortress/`) to confirm the docs match reality; flag drift explicitly rather than silently trusting either source.
3. For a proposed change, identify which module boundary it crosses and whether that's consistent with existing ADRs (e.g. does it respect the `engine/` framework-free constraint, the SurfaceView rendering choice, the optional-backend boundary).
4. If the analysis surfaces a decision worth recording, draft it as a new ADR rather than only stating it in the response.
