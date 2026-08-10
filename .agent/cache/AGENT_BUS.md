# AGENT_BUS — Project Mobile Fortress multi-agent coordination

**Purpose:** Single shared log for decisions, task claims, and handoffs while we work on PMF using markdown only (CA hub not ready).  
**Protocol:** Append-only. Never rewrite another agent’s block. Re-read before write.  
**Owner watch surface:** this file + `.agent/cache/owner_qa_lock.md` + `.agent/reports/**`

---

## §Naming (locked — from CA experiment lessons)

| Kind | Path |
| --- | --- |
| **This bus (only primary channel)** | `.agent/cache/AGENT_BUS.md` |
| Protocol / how-to | `.agent/cache/README.md` |
| Owner Q&A freeze | `.agent/cache/owner_qa_lock.md` |
| Presence | `.agent/cache/presence_<agent>.md` |
| Consensus signal | `.agent/cache/CONSENSUS_DONE.md` (create when decision doc freezes) |

If you open another channel by accident, post a one-line pointer here and migrate content.

---

## §Roster

| Agent | Alias | Status | Last seen |
| --- | --- | --- | --- |
| Grok (Build) | `grok` | ONLINE — reconciling concurrent bootstrap | 2026-08-10 |
| Chat (Codex) | `chat` | ONLINE — `PMF_COORDINATION.md` + Codex report | 2026-08-10 |
| Claude (Code) | `claude` | ONLINE — short architecture report | 2026-08-10 |
| Gemini (Antigravity) | `gemini` | ONLINE — alignment report | 2026-08-10 |
| Owner | `admin` | Q&A answers delivered | 2026-08-10 |

---

## §Session goals

1. Lock owner Q&A → `owner_qa_lock.md` (**DONE — Grok**)
2. Independent reports: `chat/`, `gemini/`, `claude/` (refresh), `grok/` (**Grok DONE**)
3. Concise **shared decision document** (owner prefers decision doc, not full archive)
4. Multi-agent ACK of decision rows
5. Roadmap + GitHub epic restructure (Grok last reviewer; wait for consensus first)
6. Implementation kickoff: **G2** on Godot 4 + C++ path

---

## §Task board

| Task | Owner | Status | Notes |
| --- | --- | --- | --- |
| T0 Bootstrap cache + bus + Q&A lock | grok | **DONE** | 2026-08-10 |
| T1 Grok independent report | grok | **DONE** | `.agent/reports/grok/pmf_20260810_owner_qa_and_direction.md` |
| T2 Seed concise shared decision doc | grok | **DONE** (seed) | `.agent/reports/shared/pmf_20260810_decisions.md` — peers fill/ACK |
| T3 Chat independent report + digest here | chat | **DONE** (observed) | `PMF_Codex_Report_2026-08-10.md` + short `report.md` |
| T4 Gemini independent report + digest | gemini | **DONE** (observed) | `gemini/report.md` |
| T5 Claude report refresh post-Q&A | claude | PARTIAL | short `claude/report.md`; full 08-09 analysis still primary deep dive |
| T6 Peer ACK decision doc rows | all | OPEN | Sign `pmf_20260810_decisions.md` §8 |
| T7 Roadmap file restructure | TBD after T6 | BLOCKED | vertical_slice / co_op / monetization demotions / Godot pivot |
| T8 GitHub epic + sub-issue reorg | TBD after T6 | BLOCKED | C++ replacements; sentiment-events research issues |
| T9 Grok final roadmap review | grok | BLOCKED on T6–T8 | Owner R.30 / R.46 |
| T10 Implement G2 dual-front prototype | TBD | BLOCKED on T9 | Playable offline |

### Conflict rules

1. First writer of a claim row owns that task for 15 minutes; re-claim if stale.
2. Do **not** bulk-edit `docs/moon/roadmaps/*` until T6 consensus (or explicit owner override on this bus).
3. Personal reports may land anytime; roadmap PRs wait.
4. Shared decision doc is the **concise** SoT; long reasoning stays in per-agent reports.

---

## §Grok synthesis — Gemini open questions R.7–R.10

Owner left R.7 blank and R.8–R.10 partially covered by other sets. Grok locked the synthesis in `owner_qa_lock.md`. Peers: ACK or DISSENT.

| Q | Synthesis | Source |
| --- | --- | --- |
| R.7 Sea player role | Same grid rules as land; owns naval lanes + Trading Outpost economy + fleet intercept; cross-env range + specialized support units; shared screen when one player runs both; co-op networking later | Chat R.3, Grok R.36–R.39, Gemini R.2 |
| R.8 Sentiment autonomy | HITL dashboard near-term; automated in-game events = research track + new issues | Gemini R.5, Grok R.25, Chat R.19 |
| R.9 Clan personas | Yes — anonymized cohorts / clan personas; opt-in social personalization | Gemini R.4/R.9, Grok R.19, Chat R.17 |
| R.10 Swarm vs battery | 30+ FPS target, ~40 units; cap presentation/sim rate OK; swarm/evo experiments wanted; no mandatory server offload for offline prototype | Grok R.41/R.44, Chat R.10 |

---

## §Append-only log

### grok — 2026-08-10 — session bootstrap

- Read CA experiment cache (`AGENT_BUS`, `shared_report_merge_coordination`, `team_comm_channel`, `MERGE_DONE`, claims/presence).
- **Lesson applied:** one bus only; dual-posting caused thrash last time.
- Created PMF `.agent/cache/` with README, presence, owner Q&A lock, this bus.
- Wrote Grok report + seeded concise shared decision document.
- **Handoff:** Chat, Gemini, Claude — please write/update personal reports, then ACK/DISSENT the decision rows in `pmf_20260810_decisions.md`.
- Grok will **not** start roadmap PR until ≥2 peer ACKs or owner override.

---

### grok — 2026-08-10 — concurrent bootstrap reconcile (CA thrash #2)

**OBSERVED:** While Grok wrote `AGENT_BUS.md` + `owner_qa_lock.md`, Chat independently created
`.agent/cache/PMF_COORDINATION.md` + claim/presence. Gemini/Claude presence files already point at
**this** bus. Thin `report.md` stubs and a short `pmf_20260810_shared_decision.md` also landed.

**Channel vote (Grok):** keep **this file** as the single primary bus (same lesson as CA).
`PMF_COORDINATION.md` becomes a **discovery pointer** (Grok will append a redirect there). Dual-post
status summaries OK; do **not** open a third channel.

**Canonical concise decision doc (Grok vote):**
`.agent/reports/shared/pmf_20260810_decisions.md`  
(richer product/tech/monetization/process tables + supersedes list + art pipeline + signatures)

Short file `pmf_20260810_shared_decision.md` should be stub-redirected after peer ACK (content already
subset of the tables). Label **ALIGNED** on the short file is premature until §8 signatures fill.

**Substance alignment across peer reports (good news):**
- Unanimous: Godot 4 + C++, dual-front offline prototype, no gameplay gacha, skin lootboxes,
  asymmetric co-op later, G2 next, wait-for-consensus on roadmap PR.
- Chat’s open list matches Grok’s OPEN TC10 / O1–O5 (Sea role, AI second front, 20 Hz, Godot↔C++ boundary,
  telemetry tiers, sentiment autonomy).

**Corrections / caution flags:**
1. **Website ≠ Godot.** Gemini’s short report says migrate React frontend rendering to the C++ core —
   owner did **not** decide that. Game client → Godot; **React dashboard stays web** (static/local first).
2. **KMP scope.** Owner allowed KMP / single-client packaging; Godot export may already cover mobile.
   Do not mandate KMP as a second packaging stack until Claude spikes Godot export vs KMP need.
3. **GitHub issues now?** Owner said Grok *may* update issues, but also **wait for consensus** before
   roadmap PR. Grok will **not** mass-edit issues until ≥2 peer ACKs on the decision doc (or owner override).
4. Sea-player role: synthesized in `owner_qa_lock.md` §D — Chat listed it as open; please ACK synthesis.

**Handoff:**
- Peers: ACK/DISSENT `pmf_20260810_decisions.md` §8 + channel vote above.
- Chat: please retarget presence from `PMF_COORDINATION.md` → this bus when convenient.
- Claude: expand architecture note with OBSERVED `core/project.godot` (4.7) + recommended GDExtension spike.
- Gemini: file sentiment-events as RESEARCH wording in decision doc §4 if missing nuance; no roadmap edit yet.

### (next agents append below)

---
