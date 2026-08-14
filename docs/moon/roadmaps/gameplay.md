# Gameplay Roadmap

**Owner:** TBD

Scope: the Wōkòu-pirate-era tower-defense core loop and its meta-progression layer. See [`moon/ROADMAP.md`](../ROADMAP.md#game-concept-summary) and the Slice-0 definition in [`vertical_slice.md`](vertical_slice.md).

**2026-08-11 note (final multi-agent pass):** Primary client is **Godot 4** (isometric 2.5D). Dual land/sea fronts are **mandatory** in the first playable prototype. Hero **gameplay gacha is rejected** — heroes remain a core systems feature (G4) but are not monetized as power gacha (see [`monetization.md`](monetization.md)). Full Flow Field (G3) follows a fun dual-front loop (G2 / VS1), not the reverse.

**2026-08-11 implementation note:** Slice-0 dual-front loop is playable in `core/` (classic `main.gd` + modular `scenes/battle/battle.tscn` over `SimulationCore` GDExtension).

| # | Item | Effort | Status | Milestone |
| --- | --- | --- | --- | --- |
| G1 | ~~Demo entity (`Ball`) with bounce physics~~ — template placeholder, superseded by G2+ | S | ✅ Done (superseded) | — |
| G2 | Dual-front grid fortress-defense core loop (land + sea): place units, defend HQ, cross-front support | L | 🚧 **Playable** — polish remaining | Slice-0; epic #128 |
| G3 | Flow Field pathfinding for enemy raiders (land and naval); naive lane pathing ships in Slice-0 | L | 🚧 **Partial** — waves use staggered-row flow + solid detour; lanes if grids off | Post Slice-0 polish |
| G4 | Hero-commander system: grid place, aura, active CD, reposition travel — **not** power-gacha | M | 🚧 **Slice-0 pair** — Qi pulse + Capitão Dias cross-front salvo; one of each type | Expand post-slice |
| G5 | Data-driven level/wave definitions (JSON) | M | 🚧 **Partial** — `assets/levels/slice0_dual_front.json` | Slice-0 |
| G6 | Build vs combat phases | M | 🚧 **Partial** — build timer + combat (day/night UX polish later) | Slice-0 |
| G7 | Resource / Trading Outpost economy; outpost loss economic only | L | 🚧 **Partial** — income 1–2 / tick scaled by remaining OP HP; 0 after loss | Slice-0 |
| G8 | Score/progression system (per-level stars, HQ prestige) | M | 🚧 **Slice-0 wired** — stars + HQ prestige persist via `Progression` / `end_run`; no 4X meta | Launch path |
| G9 | Coastal-territory light-4X meta-map; settlement capture later season | XL | 📋 Deferred | Post-launch |
| G10 | Touch/click placement for dual grids (Godot) | S | 🚧 **Partial** — mouse/click placement both fronts | Slice-0 |
| G11 | Sensor input optional | M | 📋 Deferred | Nice-to-have |
| G12 | Cross-front specialized support units + environment-locked resources | M | 🚧 **Partial** — Signal Battery / cross mults | Slice-0 |
| G13 | Clans as persistent social layer at launch | L | 📋 Deferred | Launch |

Effort key: S = days, M = 1–2 weeks, L = 3–6 weeks, XL = multi-month/cross-cutting.

See also: [`co_op_modes.md`](co_op_modes.md) for asymmetric land/sea co-op (design now, implement after Slice-0).
