# Gameplay Roadmap

**Owner:** TBD

Scope: the Wōkòu-pirate-era tower-defense core loop and its meta-progression layer. See [`moon/ROADMAP.md`](../ROADMAP.md#game-concept-summary) for the overall concept and [`reports/Tower Defense Market Research.md`](../reports/Tower%20Defense%20Market%20Research.md) for the design rationale.

**2026-08-09 note:** G2/G3/G10 below are the full-scope versions of this loop. A cut-down, timeboxed slice of these three items (naive pathfinding instead of full Flow Field, one lane, no meta-progression) is being built first as the **Playable Vertical Slice** track in [`moon/ROADMAP.md`](../ROADMAP.md#track-playable-vertical-slice-in-progress-2026-08-09--2026-08-23) (VS1–VS5, target 2026-08-23, Android first) — see that section before starting G2/G3/G10 directly.

| # | Item | Effort | Status |
| --- | --- | --- | --- |
| G1 | ~~Demo entity (`Ball`) with bounce physics~~ — template placeholder, superseded by G2+ | S | ✅ Done (superseded) |
| G2 | Grid-based fortress-defense core loop: place Ming Garrison Spearmen, Fo-lang-ji Cannon Crews, Portuguese Arquebusiers, and Veteran Commander heroes along land/naval raid lanes, defend the Main HQ from HP depletion | L | 📋 Pending |
| G3 | Flow Field (vector field) pathfinding for enemy raiders (land and naval), replacing per-unit A\*: single Dijkstra-map recompute per tower placement, O(1) per-enemy lookup thereafter | L | 📋 Pending |
| G4 | Hero-commander system: rarity-tiered units (gacha-sourced, see [`monetization.md`](monetization.md)) with unique abilities, distinct from generic towers | M | 📋 Pending |
| G5 | Data-driven level/wave definitions (JSON, extending `core/src/level-schema.json`) — no hardcoded waves | M | 📋 Pending |
| G6 | Day/Night structure: daytime frictionless menu-based fortress upgrades and unit assignment; nighttime raid defense — explicitly avoid the "manual villager-running" tedium noted as *Kunitsu-Gami*'s core UX flaw | M | 📋 Pending |
| G7 | Resource Outpost / Trading Outpost economy: Resource Outposts generate land-unit currency, Trading Outposts generate naval-unit currency, both independently defendable and separate from the HQ loss condition | L | 📋 Pending |
| G8 | Score/progression system (per-level stars, HQ prestige) | M | 📋 Pending |
| G9 | Coastal-territory light-4X meta-map: persistent world map, faction-owned strongholds, alliance-vs-alliance contested zones | XL | 📋 Pending |
| G10 | Touch-input handling for tower/unit placement (drag/tap, lane-aware) | S | 📋 Pending |
| G11 | Sensor input (accelerometer/gyroscope) as an optional control scheme | M | 📋 Pending |

Effort key: S = days, M = 1–2 weeks, L = 3–6 weeks, XL = multi-month/cross-cutting.
