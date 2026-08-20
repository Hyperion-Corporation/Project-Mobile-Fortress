# game/ — Mobile Fortress (Godot 4 Slice-0)

Playable **offline dual-front** prototype for Mobile Fortress.

| Path | Role |
| --- | --- |
| **`scenes/main_menu.tscn`** | **Entry** — choose modular or classic |
| **`scenes/battle/battle.tscn`** | **Modular view** — TileMap grids + HUD over `SimulationCore` |
| **`main.tscn` + `main.gd`** | Classic single-file canvas prototype |
| `scripts/battle/battle_root.gd` | Presentation + input for modular battle |
| `assets/levels/` | Level JSON |
| `src/cpp/` | GDExtension `SimulationCore` (raiders, defenders, outposts) |

## Run

1. Install [Godot 4.3+](https://godotengine.org/download) (tested 4.7).
2. Build the extension if needed: see [`BUILD_CPP.md`](BUILD_CPP.md).
3. **Import / open this `game/` folder** → **F5**.

```text
Godot → Import → select game/project.godot → Run
# menu: Modular Battle (C++ view)  |  Classic main.gd prototype
```

## Controls (modular battle)

| Input | Action |
| --- | --- |
| Sidebar / **1–5** | Spearman / Cannon / Qi / Cross-support / Capitão Dias |
| **Click** land or sea grid | Place unit (build or combat) |
| Click hero, then empty cell | Redeploy (travel; no fire while moving) |
| **Space** / Start Combat | Begin raid |
| **E** / Hero Ability | Qi flare + Dias cross-front salvo |
| **Esc** | Pause overlay (Resume / Save / Menu) |

## Loop (Slice-0)

1. **Build** — place Ming/Portuguese units on both fronts.
2. **Combat** — raiders approach each front; hold **HQ**.
3. Outpost loss is **economic only** (income drops).
4. Survive ~45s with field clear → victory. Results also go to `user://last_run_results.json`.

## Offline persistence (VS8)

| Path | Contents |
| --- | --- |
| `user://last_run_results.json` | Last run outcome (schema v1; includes G8 `stars` / prestige) |
| `user://run_history.json` | Last 20 runs (`runs[]`) |
| `user://progression.json` | G8 per-level best stars + cumulative HQ prestige |
| `user://mf_slice0_snapshot.bin` | Modular FlatBuffers mid-run snapshot |
| `user://mobile_fortress_slice0.json` | Classic main.gd placement save |

Shared helpers: `scripts/data/offline_persistence.gd` (`OfflinePersistence`).  
Modular: **S** / Save button snapshot; **L** / Load; run end auto-saves snapshot + results.  
Main menu shows last-run summary and **Resume last snapshot** when a bin exists.

## Simulation backend

- **Preferred:** `SimulationCore` GDExtension (`bin/libmobile_fortress_core.so`) — HQ, dual currencies, raider pathing.
- **Fallback:** pure GDScript if the `.so` is missing.
- Build native lib: see [`BUILD_CPP.md`](BUILD_CPP.md).
- Native C++ (no Godot): `cmake --build game/build --target sim_world_tests && ctest --test-dir game/build --output-on-failure`
- C++ bridge: `godot --path game --headless --script res://tests/simulation_smoke.gd`
- Modular battle: `godot --path game --headless --script res://tests/modular_battle_smoke.gd`
- Multi-hero E: `godot --path game --headless --script res://tests/hero_e_smoke.gd`
- DT8 unlock: `godot --path game --headless --script res://tests/dev_access_smoke.gd`
- DT5/DT4 overlay: `godot --path game --headless --script res://tests/dev_diag_smoke.gd`
- DT1/DT2 cheats: `godot --path game --headless --script res://tests/debug_cheats_smoke.gd`
- DT3 spawn / jump-wave: `godot --path game --headless --script res://tests/scenario_control_smoke.gd`
- DT7 playtest log: `godot --path game --headless --script res://tests/playtest_log_smoke.gd`
- G5 level catalog: `godot --path game --headless --script res://tests/level_catalog_smoke.gd`
- DT6 overlay picker: `godot --path game --headless --script res://tests/level_picker_smoke.gd`
- FlatBuffers S4: `godot --path game --headless --script res://tests/flatbuffers_smoke.gd`
- VS8 offline: `godot --path game --headless --script res://tests/game_session_smoke.gd`  
  and `res://tests/offline_persistence_smoke.gd`
- G8 progression: `godot --path game --headless --script res://tests/progression_smoke.gd`
- Menu entry: `godot --path game --headless --script res://tests/main_menu_smoke.gd`

### FlatBuffers save/load (S4)

In modular battle: **S** writes `user://mf_slice0_snapshot.bin`, **L** restores.  
API: `SimulationCore.save_state()` / `load_state(PackedByteArray)` — schema `src/schema/simulation_state.fbs`.

## Next engineering steps

- Collaborator playtest gate (VS10).
- Richer EnTT combat systems / Flow Field presentation alignment.
