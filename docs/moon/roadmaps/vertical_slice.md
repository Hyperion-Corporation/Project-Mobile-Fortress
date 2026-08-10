# Vertical Slice Roadmap (Slice-0)

**Owner:** TBD  
**Status:** 🚧 Immediate milestone  
**Authority:** Owner Q&A 2026-08-10 + admin report + canonical shared report  
**Sequencing:** This track is the dependency for multiplayer, LiveOps, ML automation, and live dashboards.

## Goal

Ship an **offline**, **dual-front** (land + sea) Wōkòu-era fortress-defense prototype on **Godot 4** that **shows promise** to the owner and two collaborators. Success is qualitative, not store-ready.

## Acceptance criteria

| ID | Criterion | Gate |
| --- | --- | --- |
| VS-A1 | One complete session with **both land and sea** fronts active | Hard |
| VS-A2 | Ming + Portuguese as the only playable civ pair | Hard |
| VS-A3 | Isometric **2.5D** presentation; **ukiyo-e-readable** art (not pure greyboxes) | Hard |
| VS-A4 | Build/position/upgrade phase + combat/resource phase | Hard |
| VS-A5 | HQ primary lose condition; outpost loss is **economic only** | Hard |
| VS-A6 | ≥1 hero (grid place, aura, active CD, reposition travel) | Hard |
| VS-A7 | ≥1 cross-front support unit with a meaningful trade-off | Hard |
| VS-A8 | 10–40 simultaneous units at **30+ FPS** on Android 13+ / iOS 17+ targets | Hard |
| VS-A9 | Offline play + local campaign state persistence | Hard |
| VS-A10 | Single-player controlling both fronts; shared camera/perspective | Hard |
| VS-A11 | No networked co-op, PvP, live services, or gameplay gacha required | Scope |

## Deliverables

| # | Item | Effort | Status | Notes |
| --- | --- | --- | --- | --- |
| VS0 | Godot 4 project as primary game client | M | 🚧 Scaffold playable | Open `core/` (`main.tscn`); Godot 4.7 smoke OK |
| VS1 | Dual-front grid core loop (G2) | L | 🚧 **Playable + C++ bridge** | `main.gd` + optional `SimulationCore` GDExtension |
| VS2 | Naive pathfinding (lane waypoints) | S | 🚧 | Paths drawn; C++ advances raiders |
| VS3 | Touch/click placement for dual grids | S | 🚧 | Build + combat placement |
| VS4 | Build vs combat phase shell | M | 🚧 | Build timer auto-starts combat |
| VS5 | Resource + Trading Outpost economy | M | 🚧 | Dual currency + income; economic outpost loss |
| VS6 | Hero + cross-front support | M | 🚧 | Aura, E ability, hero redeploy travel |
| VS7 | Ukiyo-e-readable art | M | 🚧 | Palette / isometric diamonds |
| VS8 | Offline save/load + results export | S | 🚧 | user:// saves + results JSON |
| VS9 | Android 13+ + iOS 17+ export smoke (Godot export templates) | M | 📋 | iOS CI when macOS collaborator joins |
| VS10 | Collaborator playtest + “shows promise” decision record | S | 📋 | Exit gate for Phase 1a |

## Explicitly out of scope for Slice-0

- Networked asymmetric co-op (design only — see [`co_op_modes.md`](co_op_modes.md))
- PvP, settlement capture, persistent seasonal map
- Live remote dashboards, Reddit/X productization
- RL/CMAB automation in production
- Gameplay-power gacha

## Dependencies

| Depends on | Produces for |
| --- | --- |
| Owner decisions (canonical shared report) | G3+, G9, backend B2+, monetization M*, AI A5+ |
| [`shared_core.md`](shared_core.md) spike (godot-cpp / modules) — may start in parallel after VS1 fun | Full shared sim packaging |

## Supersedes

The 2026-08-09 Android-first **single-lane**, placeholder-art, 2026-08-23 hard gate track in `ROADMAP.md` is **superseded** by this dual-front Godot Slice-0 definition.
