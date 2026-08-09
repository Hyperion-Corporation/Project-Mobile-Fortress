# Repository Automation Roadmap (`git/` tooling)

**IDs:** RA1–RA4 · **Status:** 🔄 core suite adapted to this repo, LLM-only sync

Scope: the `git/` directory's local hooks + CI automation for keeping this repo's GitHub Project
board (project 17) in sync with `docs/moon/ROADMAP.md`/`docs/moon/CHANGELOG.md`, and for
cross-assistant subagent-delegation conventions (`.agent/messages/`). This is repo/process tooling,
not game code — kept as its own small roadmap (mirroring why
[`multi_framework_platform.md`](multi_framework_platform.md) exists separately from the game
roadmaps) rather than shoehorned into `backend.md`/`qa_testing.md`, neither of which fit.

See [`git/README.md`](../../git/README.md) for the setup/usage docs; this file tracks open work
only.

## Deliverable index

| ID | Deliverable | Effort | Depends on | Status |
| --- | --- | --- | --- | --- |
| RA1 | Adapt the ported `git/` automation suite (hooks, `agent_tools.py`/`sync_backlog.py`/`check_commit_ref.py`, label taxonomy) to this repo's actual conventions: real Project 17 field IDs/option names (native `Status`/`Priority` fields, not invented labels), Mobile Fortress's module boundaries as the component taxonomy, and consistent secret/env-var naming with `.github/workflows/agent_sync.yml` | M | — | ✅ done |
| RA2 | Merge the local pre-commit config-validation check into `.pre-commit-config.yaml` (single hook-installation mechanism, avoiding a silent collision with the existing keystore/ktlint/lint gates) | S | RA1 | ✅ done |
| RA3 | `check_commit_ref.py`'s post-commit board update: finish the real item-id lookup + transition call (previously a stub that only logged what it *would* do) | S | RA1 | ✅ done |
| RA4 | Deterministic (non-LLM) fallback mode for `sync_backlog.py`: parse `ROADMAP.md`/`CHANGELOG.md` tables directly into a `SyncPlan` (rule-based — e.g. a roadmap row's own Status column maps straight to a board transition) instead of requiring `GEMINI_API_KEY`, selectable via a `--mode deterministic\|llm` flag. Useful for contributors who don't have/want a Gemini key, and as a sanity check against the LLM path. | M | RA1 | ⬜ not started — deferred, see below |

Effort key: S = days, M = 1–2 weeks, L = 3–6 weeks, XL = multi-month/cross-cutting.

## Why RA4 is deferred rather than half-built

A real deterministic mode needs its own markdown-table parser (roadmap tables aren't fully uniform
across `docs/moon/roadmaps/*.md` — see e.g. the Status column's mix of ✅/🔄/⬜/🔬/🔁 markers and
free-text notes), a mapping from that parser's output to the same `SyncPlan` shape
`request_plan()` returns today, and test coverage proving it produces sane output on this repo's
actual roadmap files — enough scope to deserve its own implementation pass rather than a rushed
addition alongside the RA1–RA3 fixes. The Gemini-driven path (`sync_backlog.py`'s default) is fully
functional and adapted to this repo in the meantime.

## Document history

| Date | Revision | Change |
| --- | --- | --- |
| 2026-08-09 | R1 | Initial roadmap: tracks the `git/` automation suite audit/adaptation (RA1–RA3, delivered) and the deferred deterministic-sync mode (RA4, backlog). |
