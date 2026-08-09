# Shared Mobile Fortress Status & Brainstorming Report

> **Status:** Draft template — populated after individual agent reports + human review.  
> **Editors (planned order of personal reports):** Chat (Codex) → Gemini (Antigravity) → Claude (Code) → Grok (Build) → Human (pkhunter) → optional friend / additional agents.  
> **Admin attachment track:** `.agent/reports/admin/` (Chat scaffolds ASP-style status report; Gemini → Claude → Grok review/edit; human attaches materials).  
> **Date seed:** 2026-08-09  
> **Repo:** [ACFHarbinger/Project-Mobile-Fortress](https://github.com/ACFHarbinger/Project-Mobile-Fortress) · Project board 17

---

**⚠ Duplicate shared-report notice (2026-08-09, added by Claude):** a second, independently-created shared report exists at [`.agent/reports/shared/PMF_Shared_Report.md`](PMF_Shared_Report.md) (Claude, modeled on the `Image-Toolkit` project's `asp_20260808_status_report.md` pattern) — its §3 Product Contract already has several `DECIDED` rows from a live brainstorm session with the owner on 2026-08-09 (playable-slice timebox, C++ core reaffirmed, `ai_systems.md` entry-gate policy, `internal_dashboard.md` merge, issue-drift remediation via thin pointers — see that file and `docs/moon/CHANGELOG.md`'s "Changed (2026-08-09, multi-agent roadmap brainstorm session)" entry for what's already been executed against the repo). Owner decision (2026-08-09): keep both files for now, merge later. Check `PMF_Shared_Report.md` §3 before re-asking the owner questions already answered there (e.g. §6's Q1/Q5/Q6/Q8/Q10 in this file overlap with decisions already recorded).

## 0. How to use this document

1. Each agent writes a **full personal report** under `.agent/reports/{chat,gemini,claude,grok}/`.
2. Each agent pastes a **short consensus-ready summary** into §3 (do not overwrite others’ subsections).
3. After joint brainstorming, freeze **§4 Agreed Action Items** and **§5 Roadmap deltas**.
4. Human fills ASP/admin attachments; agents do a **final pass** on structure agreement (§8).

**Edit etiquette (parallel agents):** append under your named subsection; never rewrite another agent’s prose without an explicit `<!-- edited by X: reason -->` note; prefer additive lists over silent deletions.

---

## 1. Executive Summary

*Collaborative — fill after individual reports and human answers to clarifying questions.*

| Dimension | Snapshot (2026-08-09 analysis seed) |
| --- | --- |
| Product vision | Wōkòu-era (1540s–1560s) dual land/sea TD + light 4X coastal meta + co-op/PvE/PvP social layers |
| Playable game today | **No** — Android bouncing-ball skeleton; iOS top-down shooter skeleton |
| Docs / design maturity | **High** — GDD, market research, multiplayer research, moon roadmaps |
| Website / design hub | **Advanced** — React host + Aurelia/Astro/Apollo islands; MFP largely ahead of the game |
| Shared sim core | **Decided C++20/EnTT/FlatBuffers** in docs; **not implemented**; GitHub issues still mostly Rust-era |
| Highest risk | Scope (game + MP + ML + LiveOps + polyglot website + metrics product) vs. zero vertical slice |

---

## 2. Codebase & Documentation Analysis

### 2.1 Current implementation state

| Surface | Reality |
| --- | --- |
| `android/` | SurfaceView + fixed-timestep loop; `GameEngine` + demo `Ball`; Compose main menu |
| `ios/` | SpriteKit shooter (`PlayerNode`/`EnemyNode`/`BulletNode`); SwiftUI chrome; LevelLoader reads `core/assets/levels/` |
| `core/` | Assets + JSON schema + state-machine **docs only** (not compiled) |
| `docs/moon/` | Active roadmaps (gameplay, shared_core, AI, backend, MFP, repo automation, …) |
| `docs/website/` | Real multi-framework design hub (Vite/React 19); static gh-pages |
| `infra/` | Scaffolding only (Docker/k8s/Helm/Terraform/Ansible) — no live game services |
| GitHub Project 17 | Issues exist per roadmap row; many titles/bodies stale vs. C++ decision / Wōkòu retcon |

### 2.2 Documentation vs. issues drift (must fix)

| Area | Docs say | Issues still say (examples) |
| --- | --- | --- |
| Shared core | C++20, EnTT, FlatBuffers, JNI/Swift C++ interop | Rust, hecs, UniFFI, rkyv (`#26`, `#29`, `#53`, `#63`, `#68`–`#74`) |
| Matchmaking fleet | AWS GameLift / FlexMatch | `#46` titled “GCP Firebase fleet provisioning” |
| Setting | 1540s–1560s Wōkòu coast (Ming + Portuguese defaults) | Older Sengoku/Yokai language may linger in places |
| Monetization M6 | Pending in `monetization.md` | `#38` Closed |
| MFP host | React 19 host | Some research docs still Vue-host framed (historical OK if labeled) |
| Product metrics | Issues `#120`–`#125` | No `docs/moon/roadmaps/product_metrics.md` yet |

### 2.3 Proposed product paradigm (user vision — 2026-08-09)

- **Dual arena:** simultaneous land + sea defense.
- **Asymmetric co-op:** one player land strategy/tactics; one player sea logistics/strategy.
- **Social layers:** clans/squads; global dungeon-like events; settlement capture on a regional map; bonuses for successful raids/captures.
- **AI / OR:** flow/dynamic pathing; continuous (not discrete) difficulty; personalized offers using player + social-graph signals; swarm/EA/MILP where they earn their keep.
- **Dev/ops product surface:** telemetry, monetization metrics, lore/marketing decisions, store reviews (+ possible social scrapes) on an expanded website with 3D viz, zoomable lore maps, interactive charts, and demos.

### 2.4 Phase model (as documented)

| Phase | Focus | Status vs. reality |
| --- | --- | --- |
| 0 | Template scaffolding | ✅ Done |
| 1 | Single-player TD MVP | 🚧 Marked in progress — **gameplay G2 still pending; clients not TD** |
| 2 | Shared C++ core | 📋 Pending |
| 3 | Meta / gacha / clans / LiveOps foundations | 📋 Pending |
| 4 | Server-authoritative co-op + matchmaking | 📋 Pending |
| 5 | PCG + ML systems | 📋 Pending |
| 6 | LiveOps / compliance / regional launch | 📋 Pending |
| 7 | Docs multi-framework platform | 📋/🔄 — **far more progress than Phase 1** |

---

## 3. Per-agent feedback digests

### 3.1 Antigravity (Gemini)

*To be populated by Gemini after personal report.*

### 3.2 Codex (Chat)

*To be populated by Chat after personal report.*

### 3.3 Code (Claude)

*To be populated by Claude after personal report.*

### 3.4 Build (Grok)

*Seed (full write-up lands in `.agent/reports/grok/` after Q&A; do not treat this as final):*

- **Keep:** native presentation split; Flow Fields; server-authoritative co-op *when* multiplayer exists; compliance-first gacha; Wōkòu dual-front fantasy; agent/CI/docs discipline.
- **Change:** ship a ruthless offline vertical slice before more MFP/ML/backend; sync issues to C++; kill 16-week fantasy production plan; make dual-arena + asymmetric co-op first-class roadmap IDs; freeze optional website islands until playable TD exists; reconsider full dual-native + C++ cost vs Godot/Unity for a small team.
- **Opinion:** documentation and platform tooling are excellent; the *product* is still vapor. Rebalance effort toward **fun playable minutes** on one device.

### 3.5 Human (pkhunter)

*To be filled by project owner.*

### 3.6 Additional contributors / agents

*Optional.*

---

## 4. Agreed action items (post-brainstorm)

*Empty until joint session closes.*

| ID | Action | Owner | Priority | Notes |
| --- | --- | --- | --- | --- |
| — | — | — | — | — |

---

## 5. Roadmap deltas (post-brainstorm)

### 5.1 Keep / expand

-

### 5.2 Rewrite / resequence

-

### 5.3 New roadmaps

- e.g. `product_metrics.md`, `co_op_modes.md`, `vertical_slice.md` — *decide after Q&A*

### 5.4 Retire / merge / deprioritize

-

### 5.5 GitHub issue hygiene

- Mass retitle/rebody for C++ migration
- Close/supersede rejected items (`#125` pattern)
- Align M6 open/closed with docs

---

## 6. Open questions for the human (working list)

*Grok’s expanded question set is in the chat turn; distill agreed answers here.*

1. Team size, time budget, skill mix (native / C++ / ML / backend)?
2. Must both platforms ship day one?
3. Vertical-slice definition of “fun” (target session length, platforms)?
4. Asymmetric land/sea co-op — hard requirement for MVP or post-MVP?
5. Engine choice: dual native + C++ vs Unity/Godot vs hybrid?
6. Monetization day-one: gacha mandatory or battle-pass-first soft launch?
7. Website priority relative to game MVP?
8. Cloud provider lock-in (AWS GameLift vs alternatives)?
9. Continuous DDA — research goal or launch feature?
10. Privacy posture for social-graph offer personalization and any public-web scraping?

---

## 7. Attachments index

| Attachment | Path / link | Added by |
| --- | --- | --- |
| ASP-style admin status | `.agent/reports/admin/` (pending Chat scaffold) | Chat → review chain |
| Grok personal report | `.agent/reports/grok/` | Grok |
| Chat personal report | `.agent/reports/chat/` | Chat |
| Claude personal report | `.agent/reports/claude/` | Claude |
| Gemini personal report | `.agent/reports/gemini/` | Gemini |
| Human report / materials | TBD | pkhunter |

---

## 8. Final structure agreement

| Editor | Agrees with final shared-report structure? | Notes / requested changes |
| --- | --- | --- |
| Chat | ☐ | |
| Gemini | ☐ | |
| Claude | ☐ | |
| Grok | ☐ Yes for this template as a starting point; re-vote after brainstorm fills §4–§5 | Prefers: explicit vertical-slice section, issue-drift table (present), and non-negotiable “no roadmap edit until Q&A answers” rule |
| Human | ☐ | |

---

## 9. Document history

| Date | Who | Change |
| --- | --- | --- |
| 2026-08-09 | Chat (seed) | Initial stub |
| 2026-08-09 | Grok (Build) | Expanded multi-section collaborative template + analysis seed; no roadmap commits yet |
