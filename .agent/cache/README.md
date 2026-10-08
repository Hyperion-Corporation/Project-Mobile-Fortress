# `.agent/cache/` — multi-agent coordination (markdown-only)

Working memory for the two agent teams and the owner (`admin`). Inspired by the 2026-08-10 Coding-Assistants shared-report merge experiment.

> **Signing:** read the authoritative `§Signing` section of
> [`AGENT_BUS.md`](AGENT_BUS.md) before signing new work.

## Why this exists

The Coding-Assistants app is not yet the coordination hub. Until it is, we synchronize by:

1. **One primary bus** (never spawn a second “main” channel)
2. **Per-agent presence heartbeats**
3. **Append-only logs** (never rewrite another agent’s block)
4. **Owned reports** under `.agent/reports/{agent}/`
5. **One shared decision document** under `.agent/reports/shared/`
6. **Owner authority** under `.agent/reports/admin/`

## Files

| Path | Role |
| --- | --- |
| [`AGENT_BUS.md`](AGENT_BUS.md) | **Primary coordination channel** — roster, task board, round briefs, append-only log, `§Naming`/`§Signing` rules |
| [`presence_<agent>.md`](presence_mistral.md) | Heartbeat: ONLINE / IDLE / OFFLINE + current claim (one file per agent) |
| `claim_<task>_<agent>.md` | Optional explicit claim file (bus table is usually enough) |
| [`owner_qa_lock.md`](owner_qa_lock.md) | Frozen owner answers from the 2026-08-10 brainstorm Q&A |
| `MERGE_DONE.md` / `CONSENSUS_DONE.md` | Session completion signals (append signatures) |

**Do not** invent a parallel bus (`team_comm_channel.md`, `*_coordination.md`, etc.) without first posting a pointer + migration note on `AGENT_BUS.md`. Lesson from CA: three buses at once caused thrash.

## Agent roster (current — 2026-10-08)

Two teams work this repository; the bus `§Signing` section is the authority for
signatures. Lower-case aliases are used in the task-board Owner column, file names
and report directories.

| Agent | Bus alias | Team / branch | Directory under `.agent/reports/` | Notes |
| --- | --- | --- | --- | --- |
| Claude Harbinger | `claude` | Harbinger / `harbinger` | `claude/` | Team lead; GitHub issue ownership |
| Codex Harbinger | `chat` | Harbinger / `harbinger` | `chat/` | Reviewer (T66 this round) |
| Grok Harbinger | `grok` | Harbinger / `harbinger` | `grok/` | Main dev; sole owner of `game/src/cpp/**` rebuilds |
| Gemini Harbinger | `gemini` | Harbinger / `harbinger` | `gemini/` | Design/art lead |
| Cursor Harbinger | `cursor` | Harbinger / `harbinger` | — (creates `cursor/` on first report) | Implementer |
| Mistral Harbinger | `mistral` | Harbinger / `harbinger` | — (creates `mistral/` on first report) | Implementer; docs lane |
| Kimi Harbinger | `kimi` | Harbinger / `harbinger` | — | Implementer |
| Qwen Harbinger | `qwen` | Harbinger / `harbinger` | — | Implementer; website lane |
| Muse Harbinger | `muse` | Harbinger / `harbinger` | — | Implementer |
| Gemini Wall | `geminiwall` | Wall / `GGWall` | — | **Different agent from Gemini Harbinger** |
| Owner / human | `admin` | — | `admin/` | Final authority |
| Shared synthesis | — | — | `shared/` | Concise **decision document** (owner preference) |

## Protocol (mandatory)

1. **Re-read** `AGENT_BUS.md` and your target file immediately before every write.
2. **Append only** under your own labeled block. Disagree by adding a response block, not by editing peers.
3. **Claim before bulk edit** of a shared file or roadmap row set (15-minute claim; re-claim if stale).
4. **Personal report first**, then short digest on the bus, then contribution to the shared decision doc.
5. **Roadmaps / GitHub issues:** wait for multi-agent consensus on the bus (or owner override) before large PR-style rewrites. Roadmap *status cells* belong to the task that owns the row.
6. **Commits:** fine-grained; Conventional Commits; `Agent: <Name> <Team>` trailer above the usual coauthor trailer from `git/messages/*_coauthor.msg`.
7. **No secrets** in cache files.
8. **Sign your work** per the bus `§Signing` section (pointer above).

## Current work

The live task board, round briefs and per-task CLAIMED/DONE blocks all live on
[`AGENT_BUS.md`](AGENT_BUS.md) — re-read its `§Roster`, `§Task board` and the latest
round entry before starting work. The 2026-08-10 bootstrap goals (owner Q&A lock,
independent reports, shared decision doc, roadmap/GitHub alignment) are complete and
frozen under `.agent/reports/`; new work is assigned in rounds (currently round 4,
T59–T66, on branch `harbinger`).
