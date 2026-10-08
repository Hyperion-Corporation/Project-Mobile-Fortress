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
## Testing

Every `tests/*_smoke.gd` is auto-discovered by the runner — a new smoke needs no
list to update here or in CI:

```bash
./scripts/run_godot_smokes.sh                       # every discovered smoke
./scripts/run_godot_smokes.sh simulation gameplay   # subset by name (any form)
ctest --test-dir game/build                          # native C++ sim tests (doctest)
./scripts/run_perf_bench.sh                          # manual perf gate — docs/BENCHMARKS.md
```

The runner invokes each smoke as `godot --path game --headless --script res://tests/<name>.gd`
with a per-smoke timeout and failure-text detection, and fails the suite if any smoke
exits non-zero or prints a known Godot failure (see `docs/TESTING.md` for the full
runner contract and the per-smoke coverage table). The native extension must be
built first (`BUILD_CPP.md`); the perf bench is a manual gate, never CI.

What the smokes cover, grouped (per-smoke table in `docs/TESTING.md`):

| Area | Smokes |
| --- | --- |
| C++ bridge / sim core | `simulation_smoke` (bridge contract), `flatbuffers_smoke` (S4 snapshot round-trip), `level_schema_smoke` (levels vs `src/level-schema.json`) |
| Battle loop & placement | `modular_battle_smoke` (battle_root + defenders), `gameplay_smoke` (end-to-end Slice-0 scene), `touch_placement_smoke` (G10 touch on both fronts), `placement_afford_smoke` (T61 UnitDefs placement rule), `hero_e_smoke` (multi-hero E), `unit_catalog_smoke` (G12 catalog + cross-front multipliers), `unit_token_smoke` (U9 procedural tokens) |
| Progression & persistence | `game_session_smoke` (VS8 run results), `offline_persistence_smoke` (VS8 snapshot), `progression_smoke` (G8 stars/prestige), `main_menu_smoke`, `settings_smoke` (U3 + telemetry consent) |
| Levels | `level_catalog_smoke` (G5 catalog), `level_picker_smoke` (DT6 overlay picker) |
| Dev tools (DT) | `dev_access_smoke` (DT8 unlock), `dev_diag_smoke` (DT5/DT4 overlay + time control), `debug_cheats_smoke` (DT1/DT2 cheats), `scenario_control_smoke` (DT3 spawn/jump-wave), `playtest_log_smoke` (DT7 log + sync shape) |
| DDA (A4) | `dda_smoke` (core toggle/intensity/wave scaling), `dda_battle_smoke` (battle hookup + DT5 readout + DT7 wave fields) |
| UI / a11y (U8/U10) | `accessibility_smoke` (targets, focus, contrast, large text, screen-reader metadata), `theme_tokens_smoke` (U10 tokens/transitions), `battle_hud_layout_smoke` (T59 HUD phone targets + rank) |

All commands above were run in this checkout on 2026-10-08: smokes 27/27 PASS,
`ctest` 1/1 PASS, perf bench PASS.

### FlatBuffers save/load (S4)

In modular battle: **S** writes `user://mf_slice0_snapshot.bin`, **L** restores.  
API: `SimulationCore.save_state()` / `load_state(PackedByteArray)` — schema `src/schema/simulation_state.fbs`.

## Next engineering steps

- Collaborator playtest gate (VS10).
- Richer EnTT combat systems / Flow Field presentation alignment.
