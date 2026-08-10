# `.agent/cache/` — multi-agent coordination (markdown-only)

Temporary working memory for concurrent agents (Grok, Chat/Codex, Claude Code, Gemini/Antigravity) and the owner (`admin`). Inspired by the 2026-08-10 Coding-Assistants shared-report merge experiment.

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
| [`AGENT_BUS.md`](AGENT_BUS.md) | **Primary coordination channel** — decisions, task claims, handoffs |
| [`presence_<agent>.md`](presence_grok.md) | Heartbeat: ONLINE / IDLE / OFFLINE + current claim |
| `claim_<task>_<agent>.md` | Optional explicit claim file (bus table is usually enough) |
| [`owner_qa_lock.md`](owner_qa_lock.md) | Frozen owner answers from the 2026-08-10 brainstorm Q&A |
| `MERGE_DONE.md` / `CONSENSUS_DONE.md` | Session completion signals (append signatures) |

**Do not** invent a parallel bus (`team_comm_channel.md`, `*_coordination.md`, etc.) without first posting a pointer + migration note on `AGENT_BUS.md`. Lesson from CA: three buses at once caused thrash.

## Agent IDs

| Agent | Directory under `.agent/reports/` | Notes |
| --- | --- | --- |
| Grok (Build) | `grok/` | Last roadmap reviewer (owner R.30 / Grok Q48) |
| Chat (Codex) | `chat/` | |
| Claude (Code) | `claude/` | |
| Gemini (Antigravity) | `gemini/` | |
| Owner / human | `admin/` | Final authority |
| Shared synthesis | `shared/` | Concise **decision document** (owner preference) |

## Protocol (mandatory)

1. **Re-read** `AGENT_BUS.md` and your target file immediately before every write.
2. **Append only** under your own labeled block. Disagree by adding a response block, not by editing peers.
3. **Claim before bulk edit** of a shared file or roadmap row set (15-minute claim; re-claim if stale).
4. **Personal report first**, then short digest on the bus, then contribution to the shared decision doc.
5. **Roadmaps / GitHub issues:** wait for multi-agent consensus on the bus (or owner override) before large PR-style rewrites. Grok performs the final roadmap review pass.
6. **Commits:** fine-grained; Conventional Commits; agent coauthor trailers from `git/messages/*_coauthor.msg`.
7. **No secrets** in cache files.

## Session goals (current)

1. Ingest owner Q&A (Gemini / Chat / Grok question sets) → lock in `owner_qa_lock.md`.
2. Each agent writes/updates an independent report under their `reports/` subdir.
3. Fold into a **concise shared decision document**.
4. Align `docs/moon/roadmaps/*` + GitHub issues (epics + sub-issues) to those decisions.
5. Then implement: **G2 first** (playable dual-front offline prototype on Godot 4 + C++).
