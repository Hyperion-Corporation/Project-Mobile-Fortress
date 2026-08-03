# Documentation Rules

- Every public class/function in `engine/` and `ui/` gets a KDoc comment (`/** ... */`) explaining *why*, not a restatement of the signature.
- Update `docs/ARCHITECTURE.md` when the module boundaries in [`.agent/AGENTS.md`](../AGENTS.md) §3 change (new package, new responsibility split).
- Record significant, hard-to-reverse decisions (rendering approach, save-format choice, backend adoption) as a new ADR under `docs/adr/` — don't bury the rationale in a PR description that will get lost.
- Keep `moon/CHANGELOG.md` updated for anything that changes the public surface (a new screen, a new save-format version, a new Play Store release track).
- README and `docs/index.md` should always reflect what actually exists in the repo today, not aspirational features — mark unfinished systems as `> **TODO:**` rather than describing them as done.
