# Project Mobile Fortress — Canonical Shared Report

**Date:** 2026-08-10  
**Purpose:** Concise synthesis of the four prior files in this directory.  
**Authority:** Owner decisions are binding; agent recommendations remain proposals.  
**Sources merged:** `PMF_Shared_Report.md`, `shared_report.md`, `pmf_20260810_decisions.md`, and `pmf_20260810_shared_decision.md`.

## 1. Product decision

Mobile Fortress is a Wōkòu-era cooperative tower-defense game whose first
concrete deliverable is an offline playable vertical slice that shows promise
to the owner and two collaborators. The slice is a mandatory dual-front land
and sea experience in isometric 2.5D, using Ming and Portuguese as the initial
civilization pair and an ukiyo-e-readable visual bar.

The core loop has a build/position/upgrade phase and a combat/resource phase.
Land and sea use related grid rules but have distinct spaces, resources, and
specialized support units; heroes provide local/global/resource effects and
active cooldown abilities. Outpost loss is an economic penalty, not an automatic
loss condition. The first prototype is single-player; the intended model is one
player controlling both fronts for now.

## 2. Delivery and scope

| Area | Decision | Status |
| --- | --- | --- |
| First slice | Offline dual-front vertical slice | DECIDED |
| 90-day success | Playable slice that shows promise | DECIDED |
| Platforms | Android 13+ and iOS 17+; aim to ship together | DECIDED |
| Performance | 30+ FPS; initially 10–40 units | DECIDED |
| Co-op | Asymmetric land/sea is a launch pillar; local Wi-Fi first, networked later | DECIDED |
| PvP | Later than launch | DECIDED |
| Clans | Persistent from launch | DECIDED |
| Settlement capture | Later season | DECIDED |
| Offline mode | Main campaign offline; online-only social/leaderboard features may be absent | DECIDED |
| Audience | Owner plus two collaborators establish the first quality bar | DECIDED |
| Team | Three humans, 3–5 hours/day, six days/week | DECIDED |
| Priority | Approximately 75% game, 25% website | DECIDED |

## 3. Technical direction

Godot 4 is the primary game client; `game/project.godot` is present and targets
Godot 4.7. C++ is the firm systems/simulation language, using both `godot-cpp`
and dedicated C++ modules to run native C/C++ code. The prior
SurfaceView/SpriteKit presentation plan is superseded as the primary client
direction, and separate native Kotlin/Swift game clients are not required.

The eventual online model is server-authoritative state replication rather than
deterministic lockstep. The Godot/C++ integration approach is **DECIDED**, but
the exact module/API boundary, ownership rules, and build arrangement remain
**OPEN** and need a small design spike. A
future multiplayer tick around 20 Hz is **PROVISIONAL**.

Swarm/evolutionary pathing experiments are in scope, with battery-aware frame
rate constraints acceptable. RL difficulty adjustment and swarm/evo systems are
identity research; CMAB is important for monetization research; WFC and TGNN
are lower-priority research.

## 4. Monetization, privacy, and ML

- Gameplay-impacting hero/unit gacha is **REJECTED** as pay-to-win risk.
- Cosmetics come first, followed by a battle pass; cosmetic skin lootboxes may
  be added after or alongside the battle pass.
- Ads are rewarded-only.
- Social personalization is in scope only as an opt-in feature using anonymized
  cohorts or clan personas rather than individual PII.
- Players who opt out contribute no telemetry; graduated consent options should
  still allow less-sensitive signals.
- Difficulty begins with player-selected baseline intensity while RL fine-tunes
  invisibly. A/B testing may later compare hidden adaptation with visible
  customization.
- Reddit/X/App Store sentiment ingestion is a later research and developer-
  dashboard feature. Automated gameplay responses are roadmap research and
  require explicit human-approval safeguards before production use.

## 5. Website, dashboard, and art

The website is currently React, not Vue. The dashboard is developer-first,
mainly local and static/batch-exported at first; a custom Docker deployment can
be added when live data is needed. A 3D lore map is marketing-important but not
mission-critical. MkDocs may remain if it feeds the React site; otherwise it can
be removed. The art pipeline should prioritize readable isometric silhouettes,
historical Ming/Portuguese cues, functional outposts, and accessible touch UI;
dedicated audio is optional for the first slice.

## 6. Roadmap and process

Next implementation focus is **G2**. Roadmaps and GitHub issues should be
reorganized into milestones composed of epics and smaller related sub-issues.
Rust-era issues should be edited in place when only terminology changes and
replaced when scope or architecture changes materially. Roadmap application
waits for multi-agent consensus; the owner closes the work and Grok performs
the final review. Commits should remain fine-grained and conventional. Older
Sengoku/Vue history in changelogs may remain as history.

The main sequencing rule is to validate fun dual-front gameplay before
multiplayer networking, live dashboards, ML automation, settlement capture,
PvP, or broad LiveOps. Those systems should remain represented as later
interfaces, research, or roadmap hooks rather than blocking the first slice.

## 7. Open items and conflicts

1. Sea-player role — **schema-ready** (same grid rules; naval lanes + Trading Outposts + fleet intercept; cross-front synergy). SP vs AI second front remains **PROVISIONAL**.
2. Godot/C++ — approach selected (`godot-cpp` + modules); exact module/API boundary and tick ownership remain **OPEN** (S0 spike).
3. Telemetry consent tiers / retention legal copy — **OPEN**.
4. Sentiment-driven events without human approval — **default HITL** (A13); autonomy only after explicit later decision.
5. Stale AGENTS.md / README native wording — roadmaps updated 2026-08-11; full prose scrub may continue.

## 8. Canonicalization note

This file is the concise working synthesis. The four source reports were merged
into it; their prior content remains recoverable from repository history if
needed. Future consensus changes should be appended to this report's changelog
and reflected in the owner/admin report.

## 9. Final-pass status (2026-08-11)

| Role | Status |
| --- | --- |
| Owner / Chat / Claude / Gemini / Grok | AGREE (admin §9) |
| Roadmaps | Applied (`docs/moon/ROADMAP.md` v5.0 + topic files) |
| Next implementation | **G2 / VS1** offline dual-front Godot prototype |

## Changelog

| Date | Contributor | Change |
| --- | --- | --- |
| 2026-08-10 | Chat / Codex | Merged the four existing shared-report files into this concise canonical synthesis. |
| 2026-08-11 | Chat / Codex | Final pass: incorporated the owner's `godot-cpp` plus C++ modules clarification and separated the selected approach from its remaining implementation details. |
| 2026-08-11 | Grok | Final reviewer: open items refreshed; §9 status; roadmaps + GitHub hygiene. |
