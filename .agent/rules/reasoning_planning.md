# Reasoning & Planning Rules

- Before implementing a new gameplay system, check `docs/moon/roadmaps/gameplay.md` and `docs/adr/` for existing decisions that constrain the design — don't re-litigate a settled ADR without a new one that supersedes it.
- For changes that touch the render loop, lifecycle, or save format, write out the failure mode you're protecting against (e.g. "surface torn down mid-lockCanvas", "process killed while paused") before writing the fix — these systems fail in ways that don't show up in a quick manual test.
- Prefer the smallest change that fixes the actual reported problem; resist rewriting `GameLoop`/`GameEngine` wholesale unless the task specifically asks for an architecture change.
- When a task is ambiguous between "quick arcade prototype" and "production release pipeline" scope, default to matching what's already in the repo (this project ships a real, working — if minimal — skeleton) rather than gold-plating.
- For anything touching Play Store release (signing, versioning, `release.yml`), plan the rollback path (previous AAB, previous versionCode) before executing, not after.
