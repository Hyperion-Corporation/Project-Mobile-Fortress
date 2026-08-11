# core/ — Mobile Fortress (Godot 4 Slice-0)

Playable **offline dual-front** prototype for Mobile Fortress.

| Path | Role |
| --- | --- |
| **`main.tscn` + `main.gd`** | **Primary playable** — isometric dual land/sea loop |
| `scenes/`, `scripts/` | Modular scene/script split (menu + battle) for next iteration |
| `assets/levels/` | Level JSON |
| `src/` | Historical shared-spec docs (pre-Godot) |

## Run

1. Install [Godot 4.3+](https://godotengine.org/download).
2. **Import / open this `core/` folder** as the project.
3. Press **F5** (main scene is `main.tscn`).

```text
Godot → Import → select core/project.godot → Run
```

## Controls

| Input | Action |
| --- | --- |
| **1–4** or top unit buttons | Garrison / Arquebus / Support / Commander |
| **Click** a diamond cell on **land or sea** | Place unit (build phase) |
| **Space** or START COMBAT | Begin raid |
| **E** | Hero active ability (cooldown) |
| **S** / **L** | Offline save / load (`user://mobile_fortress_slice0.json`) |

## Loop (Slice-0)

1. **Build** — place Ming/Portuguese units on both fronts.
2. **Combat** — raiders approach each front; hold **HQ**.
3. Outpost loss is **economic only** (income drops).
4. Survive ~45s with field clear → victory. Results also go to `user://last_run_results.json`.

## Simulation backend

- **Preferred:** `SimulationCore` GDExtension (`bin/libmobile_fortress_core.so`) — HQ, dual currencies, raider pathing.
- **Fallback:** pure GDScript if the `.so` is missing.
- Build native lib: see [`BUILD_CPP.md`](BUILD_CPP.md).
- Run the C++ bridge contract test: `godot --path core --headless --script res://tests/simulation_smoke.gd`.
- Run the active scene gameplay smoke test: `godot --path core --headless --script res://tests/gameplay_smoke.gd`.

## Next engineering steps

- Promote modular `scenes/battle` when structure helps (or keep `main.gd` as Slice-0).
- FlatBuffers snapshots (S4); richer EnTT combat systems.
- Export smoke Android/iOS (VS9).
