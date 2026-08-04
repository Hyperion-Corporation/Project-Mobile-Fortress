# Gameplay Roadmap

Scope: the Sengoku-Japan tower-defense core loop and its meta-progression layer. See [`moon/ROADMAP.md`](../ROADMAP.md#game-concept-summary) for the overall concept and [`reports/Tower Defense Market Research.md`](../../reports/Tower%20Defense%20Market%20Research.md) for the design rationale.

| # | Item | Effort | Status |
| --- | --- | --- | --- |
| G1 | ~~Demo entity (`Ball`) with bounce physics~~ — template placeholder, superseded by G2+ | S | ✅ Done (superseded) |
| G2 | Grid-based castle-defense core loop: place Ashigaru spearmen, Matchlock gunners, and Samurai hero-commanders along a siege lane, defend the Daimyo's keep from HP depletion | L | 📋 Pending |
| G3 | Flow Field (vector field) pathfinding for enemy hordes, replacing per-unit A\*: single Dijkstra-map recompute per tower placement, O(1) per-enemy lookup thereafter | L | 📋 Pending |
| G4 | Hero-commander system: rarity-tiered units (gacha-sourced, see [`monetization.md`](monetization.md)) with unique abilities, distinct from generic towers | M | 📋 Pending |
| G5 | Data-driven level/wave definitions (JSON, extending `core/src/level-schema.json`) — no hardcoded waves | M | 📋 Pending |
| G6 | Day/Night structure: daytime frictionless menu-based castle upgrades and unit assignment; nighttime siege defense — explicitly avoid the "manual villager-running" tedium noted as *Kunitsu-Gami*'s core UX flaw | M | 📋 Pending |
| G7 | Score/progression system (per-level stars, castle prestige) | M | 📋 Pending |
| G8 | Clan/territory light-4X meta-map: persistent world map, clan-owned strongholds, alliance-vs-alliance contested zones | XL | 📋 Pending |
| G9 | Touch-input handling for tower/unit placement (drag/tap, lane-aware) | S | 📋 Pending |
| G10 | Sensor input (accelerometer/gyroscope) as an optional control scheme | M | 📋 Pending |

Effort key: S = days, M = 1–2 weeks, L = 3–6 weeks, XL = multi-month/cross-cutting.
