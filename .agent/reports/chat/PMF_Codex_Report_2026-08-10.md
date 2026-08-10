# Project Mobile Fortress — Codex report

**Date:** 2026-08-10  
**Owner:** Chat / Codex  
**Status:** Initial synthesis after owner Q&A; roadmap and issue edits intentionally pending  
**Coordination:** [`.agent/cache/PMF_COORDINATION.md`](../../cache/PMF_COORDINATION.md)

## Executive assessment

The immediate product goal is a playable offline, single-player Wōkòu-era
vertical slice. It must demonstrate both land and sea fronts in an isometric
2.5D presentation, with Ming and Portuguese as the initial civilization pair,
heroes/commanders, specialized cross-front support, distinct resources, and a
build/combat phase loop. Asymmetric local-Wi-Fi co-op is a launch pillar, but
networking and multiplayer UX should follow the offline gameplay prototype.

The current repository is still largely a platform-template and documentation
foundation: `.agent/AGENTS.md` describes native SurfaceView/SpriteKit clients and
a planned C++ core, while the owner has now confirmed Godot 4 as the direction
for the game client and C++ as firm for the simulation. This creates a required
documentation/architecture reconciliation task before implementation begins.

## Owner decisions captured

| Area | Decision | Label |
| --- | --- | --- |
| First deliverable | Playable offline prototype | DECIDED |
| Presentation | Isometric 2.5D | DECIDED |
| Engine | Godot 4; `core/project.godot` exists and targets Godot 4.7 | DECIDED / OBSERVED |
| Simulation | C++ firm decision; server-authoritative replicated state is sufficient later | DECIDED |
| MVP fronts | Land and sea are mandatory; initial prototype is single-player | DECIDED |
| Core loop | Land/sea have distinct combat areas, cross-front exchanges, resources, specialized support units, heroes, and civilization strengths/weaknesses | DECIDED |
| Co-op | Asymmetric land/sea co-op is core identity and launch pillar; local Wi-Fi first, but deferred from initial prototype | DECIDED |
| Offline | Main campaign works offline; online-only clans/leaderboards and similar features may be unavailable | DECIDED |
| Targets | Android 13+, iOS 17+, 30+ FPS target, 10–40 units initially | DECIDED |
| PvP | Later than launch | DECIDED |
| Clans / capture | Persistent clans from launch; settlement capture later season | DECIDED |
| Monetization | Cosmetics first; skin lootboxes only for gacha-style mechanics; no gameplay-impacting hero/unit gacha; rewarded ads only | DECIDED |
| ML difficulty | Baseline intensity levels tuned invisibly by RL initially; A/B test visible customization later | PROVISIONAL |
| Telemetry | No telemetry after opt-out; provide graduated consent options | DECIDED |
| Website | React is current, dashboard is mainly internal, static/local first, dynamic Docker deployment later | DECIDED / OBSERVED |
| Team priority | Game 75%, website 25%; first audience is owner plus two collaborators | DECIDED |
| Research ingestion | Reddit/X/App Store sentiment is later research/dev-dashboard work, not core product; automated game effects are roadmap exploration only | DECIDED / PROVISIONAL |

## Recommended first prototype contract

The prototype should answer one question: does the dual-front loop show promise
in a complete session? The minimum slice should therefore include:

- one Wōkòu-era vertical-slice scenario using Ming + Portuguese;
- simultaneous land and sea grids with same fundamental placement/combat rules;
- a build/position/upgrade phase and a combat/resource-management phase;
- resource and trading outposts whose loss harms the economy but does not
  automatically end the level;
- at least one hero with grid placement, nearby bonuses, cooldown ability, and
  timed repositioning;
- ordinary units plus at least one cross-front support unit with a meaningful
  local trade-off;
- readable ukiyo-e-inspired placeholder art;
- offline save/load and a local static results export for the internal dashboard;
- enough units to validate a 10-unit floor and a 40-unit target on low-end
  target hardware.

Networking, clans, leaderboards, PvP, RL, personalized offers, scraping, live
dashboards, and persistent settlement capture should remain interfaces or
roadmap hooks until this slice is fun and measurable.

## Open decisions to preserve

These were asked by the other agents but were not answered in the supplied Q&A:

1. Exact Sea-player mechanics: convoy logistics, naval interception, geography
   control, or another role.
2. Whether a single player controls both fronts in the final mode versus an AI
   controlling one front. Current preference is player-controlled both fronts,
   with shared perspective for implementation simplicity.
3. Whether the first simulation tick rate should be 20 Hz; this remains an
   informed placeholder rather than a binding decision.
4. The final Godot/C++ integration boundary and whether Kotlin Multiplatform is
   needed for non-game platform services once Godot owns rendering.
5. The exact consent tiers and retention policy for optional telemetry and
   opt-in social-personalization cohorts.
6. Whether sentiment-driven game events should ever leave an explicitly
   human-approved experimentation mode.

## Synchronization and implementation risks

- The owner’s current React/Godot/C++ direction conflicts with older wording in
  `.agent/AGENTS.md`, `README.md`, ADRs, and research files that describe
  native Kotlin/Swift rendering and Vue-era website architecture. Treat those
  as historical or stale until reconciled; do not infer implementation from
  roadmap prose alone.
- The scope contains several deferred systems that can obscure whether the
  core loop works. Every roadmap item should identify whether it is prototype,
  launch, later season, or research-only.
- The shared report has multiple existing candidates. Keep them intact during
  this coordination pass and choose a canonical synthesis only after the other
  agents review them.
- No agent should silently turn an owner preference (“leaning”, “interesting”,
  or “for now”) into an irreversible architecture decision.

## Handoff

Gemini should append product/roadmap prioritization and unresolved design
questions to the coordination channel. Claude should verify the current tree
and identify the smallest safe Godot/C++ migration boundary. Grok should wait
for those reviews before proposing roadmap or GitHub issue changes. The owner
retains final authority over roadmap edits, issue state, and canonical report
selection.

## Changelog

| Date | Contributor | Change |
| --- | --- | --- |
| 2026-08-10 | Chat / Codex | Created initial report from owner Q&A and repository orientation; no roadmap or issue edits. |
