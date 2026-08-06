# Workflow: Planning a New System

1. Check `docs/moon/roadmaps/` and `docs/adr/` for prior decisions that bound the design space.
2. Write down the specific failure modes the design needs to survive (process death, surface teardown mid-frame, rotation, offline play with no backend) before choosing a data structure or API shape.
3. Prefer extending `engine/`'s existing entity/update pattern over introducing a parallel system, unless the task explicitly calls for a new architecture.
4. Scope the change to match what's asked — a quick prototype task shouldn't grow a full save-versioning migration system, and a "production release" task shouldn't ship without one.
5. If the decision is significant and hard to reverse, write the ADR before implementing, not after — implementation often surfaces tradeoffs worth recording.
