# Gameplay Roadmap

**Owner:** TBD

Scope: the Wōkòu-pirate-era tower-defense core loop and its meta-progression layer. See [`moon/ROADMAP.md`](../ROADMAP.md#game-concept-summary) and the Slice-0 definition in [`vertical_slice.md`](vertical_slice.md).

**2026-08-11 note (final multi-agent pass):** Primary client is **Godot 4** (isometric 2.5D). Dual land/sea fronts are **mandatory** in the first playable prototype. Hero **gameplay gacha is rejected** — heroes remain a core systems feature (G4) but are not monetized as power gacha (see [`monetization.md`](monetization.md)). Full Flow Field (G3) follows a fun dual-front loop (G2 / VS1), not the reverse.

| # | Item | Effort | Status | Milestone |
| --- | --- | --- | --- | --- |
| G1 | ~~Demo entity (`Ball`) with bounce physics~~ — template placeholder, superseded by G2+ | S | ✅ Done (superseded) | — |
| G2 | Dual-front grid fortress-defense core loop (land + sea): place Ming Garrison Spearmen, Fo-lang-ji Cannon Crews, Portuguese Arquebusiers, and Commander heroes along land/naval raid lanes; defend Main HQ; cross-front range interfaces and specialized support units | L | 🚧 **In progress** · **NEXT** | Slice-0; Godot implementation in `core/scenes/battle/battle.tscn` + `core/scripts/battle/` |
| G3 | Flow Field pathfinding for enemy raiders (land and naval); naive pathing acceptable in Slice-0 | L | 📋 Pending | Post Slice-0 polish |
| G4 | Hero-commander system: grid placement, nearby bonuses, active ability CD, reposition with travel time; mix of support / combat / global-resource heroes — **not** gacha-sourced for power | M | 📋 Pending | Slice-0 (minimal) → expand |
| G5 | Data-driven level/wave definitions (JSON, extending `core/src/level-schema.json`) | M | 📋 Pending | Slice-0 partial |
| G6 | Build vs combat phases: build/upgrade/position phase; combat/resource-management phase (day/night or equivalent) | M | 📋 Pending | Slice-0 |
| G7 | Resource Outpost / Trading Outpost economy: land vs naval currencies; outpost loss is economic only | L | 📋 Pending | Slice-0 minimal |
| G8 | Score/progression system (per-level stars, HQ prestige) | M | 📋 Pending | Launch path |
| G9 | Coastal-territory light-4X meta-map; settlement capture = later season | XL | 📋 Deferred | Post-launch seasons |
| G10 | Touch-input for dual-grid placement (Godot input) | S | 📋 Pending | Slice-0 |
| G11 | Sensor input (accelerometer/gyroscope) optional | M | 📋 Deferred | Nice-to-have |
| G12 | Cross-front specialized support units + environment-locked upgrade resources | M | 📋 Pending | Slice-0 |
| G13 | Clans as persistent social layer at launch (UI/meta; not required for Slice-0) | L | 📋 Deferred | Launch |

Effort key: S = days, M = 1–2 weeks, L = 3–6 weeks, XL = multi-month/cross-cutting.

See also: [`co_op_modes.md`](co_op_modes.md) for asymmetric land/sea co-op (design now, implement after Slice-0).
