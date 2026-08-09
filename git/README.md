# git/

Human-browsable automation suite backing `.github/workflows/agent_sync.yml`,
kept separate from the dot-prefixed `.git/` directory (which GitHub itself
reads) so the actual logic is easy to find, read, and edit.

Ported from Visual-Graph-Programming's `git/` automation suite (via
Image-Toolkit's own copy), then adapted for Project-Mobile-Fortress: this
repo's GitHub Project board is
[project 17](https://github.com/users/ACFHarbinger/projects/17), and status
("Backlog"/"Ready"/"In progress"/"Rejected"/"In review"/"Done") and priority
("P0"/"P1"/"P2") are tracked via that board's **native `ProjectV2SingleSelectField`s**,
not GitHub labels — see `agent_tools.resolve_status_field`/`resolve_priority_field`.
Labels (`git/config/project_labels.json`) only cover component classification
(`component:android`, `component:core`, ...) plus `agent:generated`/`agent:needs-human`.

| Directory | Purpose |
| --- | --- |
| `config/` | `automation_rules.yaml` (policy DSL) and `project_labels.json` (component/agent label taxonomy) |
| `scripts/` | `agent_tools.py` (ProjectV2 GraphQL client), `sync_backlog.py` (roadmap→board reconciler), `check_commit_ref.py` (commit-message ticket linker) |
| `messages/` | Git commit trailer snippets (`*_coauthor.msg`) for each AI assistant, e.g. `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>` |
| `hooks/` | `post-commit` (+ `post-commit.bat` for Windows) plus `install.sh` to symlink it into `.git/hooks/`. **pre-commit is deliberately not here** — see below. |

## Why there's no `git/hooks/pre-commit`

This repo already uses the Python `pre-commit` framework
(`.pre-commit-config.yaml`, installed via `pre-commit install`) for its
pre-commit stage, including the **blocking** keystore-file guard and
ktlint/Android-Lint checks (see `.agent/AGENTS.md` §6.1 CRITICAL). A second,
separately-installed hook symlinked to the same `.git/hooks/pre-commit` path
would silently race with — and could disable — that framework's hook
depending on install order. So there's only one pre-commit mechanism in this
repo: `.pre-commit-config.yaml`. Its existing `check-yaml`/`check-json`
hygiene hooks (repo-wide, no `files:` filter) already validate
`automation_rules.yaml`/`project_labels.json`'s syntax, which is all this
suite's own hook would have added anyway.

`git/hooks/` only carries `post-commit`: a best-effort, fail-open hook that
checks the just-made commit message for a ticket reference
(`commit_ref.patterns` in `automation_rules.yaml`) and, if `PROJECT_ID` +
`GH_PROJECT_TOKEN` are set, transitions that issue to
`commit_ref.transition_to` (`"In progress"` by default) on the live board.

## Setup

```bash
bash git/hooks/install.sh    # symlinks post-commit only
pre-commit install           # separately -- the pre-commit stage (see above)

export PROJECT_ID="PVT_kwHOAV-XTM4BfYSx"   # this repo's Project 17 node ID
export GH_PROJECT_TOKEN="..."               # PAT with repo + project scopes
```

Why a separate PAT (`GH_PROJECT_TOKEN`) rather than the default
Actions-provided `GITHUB_TOKEN`: the built-in `GITHUB_TOKEN` cannot manage a
user-owned Projects v2 board (only org-owned ones, and even then needs
explicit `projects: write` wiring GitHub doesn't fully support for the
GraphQL ProjectV2 API yet) — `agent_tools.get_client()` reads
`GH_PROJECT_TOKEN` first, falling back to `GITHUB_TOKEN` for callers that
already export that name.

Running `git/scripts/*.py` directly (outside `uv run`, e.g. for local
testing) needs the `ci` extra installed: `pip install '.[ci]'` from the repo
root, or `uv sync --extra ci`.

## CI

`.github/workflows/agent_sync.yml` runs `git/scripts/sync_backlog.py`
(invoked as `uv run python -m git.scripts.sync_backlog`, since it imports
`agent_tools` via a relative import and must run as the `git.scripts`
package) on demand via `workflow_dispatch`. It needs two repository secrets
(`PROJECT_ISSUES_TOKEN`, mapped to the `GH_PROJECT_TOKEN` env var;
`GEMINI_API_KEY`) and one repository variable (`PROJECT_NUMBER`) configured
before it can mutate the live board — `GITHUB_PROJECT_OWNER` defaults to the
repository owner automatically. Until those are set, runs will fail fast
rather than silently no-op.

`sync_backlog.py` is currently **Gemini-driven only** (`llm.provider:
google-genai` in `automation_rules.yaml`) — it asks Gemini 2.5 Pro to
reconcile `docs/moon/ROADMAP.md`/`CHANGELOG.md` against the live board and
returns a structured JSON diff, which this script validates (circuit
breaker, allowed auto-transitions) before applying anything. A deterministic
(non-LLM) fallback mode is tracked as future work — see
[`docs/moon/roadmaps/repo_automation.md`](../docs/moon/roadmaps/repo_automation.md)'s
RA4 — rather than half-built alongside this pass's fixes.

## Windows

`hooks/post-commit.bat` is the Windows equivalent of `hooks/post-commit`
(invoked the same way `check_commit_ref.py` is from the bash version), but
`hooks/install.sh` itself is bash-only — Windows contributors need to wire
`post-commit.bat` into `.git/hooks/` manually (copy or `mklink`) until/unless
an `install.ps1` lands.
