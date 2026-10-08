# Dual-Front Simulation State Schema

*Last updated: 2026-10-08. Reference for the dual-front simulation state as implemented in the Slice-0 C++ core (`SimWorld`), plus a clearly separated proposal for the C2 local Wi‑Fi asymmetric co-op.*

**Status:** Part 1 is a source-accurate description of what exists today ([`game/src/cpp/`](../../game/src/cpp/) + FlatBuffers snapshot [`simulation_state.fbs`](../../game/src/schema/simulation_state.fbs)). Part 2 is a **proposal — nothing in it is implemented**. Line references are stable as of commit `e248146`.

## Contents

- [Part 1 — As implemented](#part-1--as-implemented)
  - [1. Architecture and front convention](#1-architecture-and-front-convention)
  - [2. Land-front-only state](#2-land-front-only-state)
  - [3. Sea-front-only state](#3-sea-front-only-state)
  - [4. Shared state (HQ, phase, clock, waves)](#4-shared-state-hq-phase-clock-waves)
  - [5. Entity collections (per-entity front tag)](#5-entity-collections-per-entity-front-tag)
  - [6. Cross-front modifiers (as implemented)](#6-cross-front-modifiers-as-implemented)
  - [7. Level-JSON → runtime-state mapping](#7-level-json--runtime-state-mapping)
  - [8. FlatBuffers snapshot coverage (S4)](#8-flatbuffers-snapshot-coverage-s4)
  - [9. Presentation-only state (not simulation state)](#9-presentation-only-state-not-simulation-state)
- [Part 2 — Co-op proposal (NOT implemented)](#part-2--co-op-proposal-not-implemented)

## Part 1 — As implemented

### 1. Architecture and front convention

All authoritative simulation state lives in the Godot-free C++ class `mf::SimWorld` (`game/src/cpp/sim_world.h:119`), a plain value object with no engine dependencies. `SimulationCore` (`game/src/cpp/simulation_core.h:16`) is the GDExtension façade that Godot calls into; it owns one `SimWorld` instance and translates `Vector2`/`PackedVector2Array`/`Dictionary` at the boundary (`game/src/cpp/simulation_core.cpp`). GDScript (`game/scripts/battle/battle_root.gd`, `game/scripts/autoload/game_session.gd`) is presentation and input only.

**Front convention:** `front` is an `int` throughout the core — `0` = land, `1` = sea. The GDScript layer uses `"land"` / `"sea"` strings and converts at call sites.

The two fronts are separate 8×5 isometric grids (fixed at `battle_root.gd:101`/`107`, `sim.init_grids(Vector2i(8, 5))` at `battle_root.gd:112`), with world-space origins 400 px apart vertically: land tiles are centered near `(300, 200)`, sea tiles near `(300, 600)` (`SimWorld::map_to_local`, `sim_world.cpp:788`). Both fronts share one grid *size* (`grid_size_`); they do not share cells.

```mermaid
flowchart LR
    subgraph Land["Land front (front=0)"]
        LR["land_resources_"]
        LO["land outpost (hp/max/alive)"]
        LF["land_flow_ (cost/dir/solid)"]
        LP["land_path_"]
    end
    subgraph Sea["Sea front (front=1)"]
        SR["sea_resources_"]
        SO["sea outpost (hp/max/alive)"]
        SF["sea_flow_ (cost/dir/solid)"]
        SP["sea_path_"]
    end
    subgraph Shared["Shared (one SimWorld)"]
        HQ["hq_hp_ / hq_max_hp_"]
        CLK["in_combat_ · combat_time_ · current_wave_"]
        WAVES["waves_ (land_count + sea_count per wave)"]
        INC["income_acc_ · build_phase_seconds_ · victory_time_"]
        IDS["next_raider_id_ · next_defender_id_"]
        ENT["raiders_ / defenders_ (per-entity front tag)"]
    end
    ENT -- "front tag" --> Land
    ENT -- "front tag" --> Sea
    WAVES -- "land_count" --> Land
    WAVES -- "sea_count" --> Sea
    HQ -. "raiders from either front hit one HQ" .-> Land
    HQ -. .-> Sea
```

Everything below lists each piece of state with: C++ type, location, snapshot coverage (field in `game/src/schema/simulation_state.fbs`), units/range, and mutators. "GD" means the mutation originates from a Godot call through `SimulationCore`.

### 2. Land-front-only state

| Field (symbol) | Type | Lives at | In snapshot? | Units / range | Mutated by |
| --- | --- | --- | --- | --- | --- |
| `land_resources_` | `int` | `sim_world.h:215` (default 14) | yes — `land_resources` (`.fbs:59`) | currency (兩), ≥ 0 | `spend(0,·)` (`sim_world.cpp:45`), `gain(0,·)` (`:85`), income in `tick` (`:460`), `debug_set_resources` (`:1013`), `debug_apply_income` (`:1042`), `reset_run` (`:9`), `load_state` (`:877`); GD: unit placement, DT1 cheats |
| `land_outpost_hp_` | `int` | `sim_world.h:221` (default 40) | yes — `land_outpost_hp` (`.fbs:63`) | HP, 0..`land_outpost_max_` | `damage_outpost(0,·)` from a land raider crossing mid-path (`sim_world.cpp:615`), `set_outpost_alive` (`:103`), `reset_run`, `load_state` |
| `land_outpost_max_` | `int` | `sim_world.h:223` (default 40) | yes — `land_outpost_max` (`.fbs:65`, default 40) | HP; not settable from level JSON — hardcoded default | `load_state` (only if snapshot value > 0); initialized at construction/`reset_run` |
| `land_outpost_alive_` | `bool` | `sim_world.h:225` (default true) | yes — `land_outpost_alive` (`.fbs:67`) | — | `damage_outpost` (false when hp reaches 0), `set_outpost_alive`, `reset_run`, `load_state` |
| `land_flow_` | `std::vector<FlowCell>` | `sim_world.h:234` | **no** (see §8.3) | `FlowCell` = `{int cost = 9999; Vec2i dir{0,0}; bool solid = false;}` (`sim_world.h:112`) — 8×5 = 40 cells | `init_grids` (`sim_world.cpp:654`), `set_cell_solid(0,·)` (`:738`, triggers `update_flow_field`), `update_flow_field` (`:750`); GD: placement/redeploy solidify cells, outpost cell (4,2) |
| `land_path_` | `std::vector<Vec2>` (px) | `sim_world.h:237` | yes — `land_path` (`.fbs:88`) | world-space px polyline | `set_lane_path(0,·)` (`sim_world.cpp:121`), `load_state`; GD: `battle_root.gd:53` sets it from the land `GridFront` |

Land outpost income rule: `outpost_income(hp, max, alive)` (`sim_world.cpp:76`) returns 0 if dead, else `max(1, 2*hp/max)` — i.e. a standing outpost pays 1–2 兩 per income tick. Outpost loss is economic only (loss event carries `economic_only = true`, `sim_world.cpp:649`).

### 3. Sea-front-only state

Exact mirror of §2 with `sea` names — no structural asymmetry in the core:

| Field | Type | Lives at | In snapshot? | Notes |
| --- | --- | --- | --- | --- |
| `sea_resources_` | `int` | `sim_world.h:216` (default 14) | yes — `sea_resources` (`.fbs:60`) | same mutators as land, front=1; `infinite_sea_` guards `spend` |
| `sea_outpost_hp_` / `_max_` / `_alive_` | `int`/`int`/`bool` | `sim_world.h:222`/`224`/`226` | yes — `.fbs:64`/`66`/`68` | sea raider crossing mid-path damages the Trading Outpost |
| `sea_flow_` | `std::vector<FlowCell>` | `sim_world.h:235` | **no** | same 8×5 shape, rebuilt by `init_grids` |
| `sea_path_` | `std::vector<Vec2>` | `sim_world.h:238` | yes — `sea_path` (`.fbs:89`) | set from the sea `GridFront` (`battle_root.gd:54`) |

If neither grid nor lane path exists, wave spawning falls back to `default_lane_path(front)` (`sim_world.cpp:129`): land y = 150, sea y = 250, x from −20 to 400.

### 4. Shared state (HQ, phase, clock, waves)

One HQ serves both fronts — a raider from *either* front that reaches the right edge (flow mode, `sim_world.cpp:576`) or the last lane waypoint (path mode, `:539`) damages the same `hq_hp_`.

| Field | Type | Lives at | In snapshot? | Units / range | Mutated by |
| --- | --- | --- | --- | --- | --- |
| `hq_hp_` | `int` | `sim_world.h:217` (default 100) | yes — `hq_hp` (`.fbs:61`) | HP, 0..`hq_max_hp_` | `damage_hq` (`sim_world.cpp:96`, guarded by `invincible_`), raiders arriving from either front (`advance_raider_along_path`/`_flow`), `reset_run`, `load_state` |
| `hq_max_hp_` | `int` | `sim_world.h:218` (default 100) | yes — `hq_max_hp` (`.fbs:62`) | HP | `reset_run` (from level JSON `hqMaxHp`), `load_state` |
| `enemies_killed_` | `int` | `sim_world.h:219` | yes — `enemies_killed` (`.fbs:69`) | count, ≥ 0 | `damage_raider` (`:175`), defender fire (`run_defender_combat`, `:335`), hero casts (`cast_hero_ability`, `:247`), `debug_kill_all_raiders` (`:1055`) |
| `units_placed_` | `int` | `sim_world.h:220` | yes — `units_placed` (`.fbs:70`) | count, ≥ 0 | `spawn_defender` (`:188`) and `note_unit_placed` (`sim_world.h:151`) |
| `in_combat_` | `bool` | `sim_world.h:242` | yes — `in_combat` (`.fbs:73`) | — | `start_combat` (`:431`), `debug_jump_wave` (`:1067`), `reset_run`, `load_state`; GD: Start Combat / phase machine |
| `combat_time_` | `float` | `sim_world.h:241` | yes — `combat_time` (`.fbs:74`) | seconds since combat start | `tick` (`:460`), `start_combat`, `debug_jump_wave` (set to wave delay), `load_state` |
| `current_wave_` | `int` | `sim_world.h:240` | yes — `current_wave` (`.fbs:75`) | 0-based index into `waves_` | `check_and_spawn_waves` (`:414`), `start_combat`, `debug_jump_wave`, `load_state` |
| `build_phase_seconds_` | `float` | `sim_world.h:243` (default 40) | yes — `build_phase_seconds` (`.fbs:76`, default 40) | seconds, > 0 | `set_build_phase_seconds` (`:448`, ignores ≤ 0), from level JSON; `load_state` (only if > 0) |
| `victory_time_` | `float` | `sim_world.h:244` (default 55) | yes — `victory_time` (`.fbs:77`, default 55) | seconds, > 0 | `set_victory_time` (`:454`, ignores ≤ 0), from level JSON; `load_state` (only if > 0) |
| `income_acc_` | `float` | `sim_world.h:227` | yes — `income_acc` (`.fbs:78`) | seconds, 0..4 | `tick` — accumulates delta, pays out and resets at 4.0 s (`sim_world.cpp:466`–`467`) |
| `next_raider_id_` | `int` | `sim_world.h:228` (starts 1) | yes — `next_raider_id` (`.fbs:79`) | count; raiders use 1.., defenders 10001.. | `spawn_raider` (`:134`) |
| `next_defender_id_` | `int` | `sim_world.h:229` (starts 10001) | yes — `next_defender_id` (`.fbs:80`) | — | `spawn_defender` |
| `waves_` | `std::vector<Wave>` | `sim_world.h:233` | yes — `waves` (`.fbs:84`) | `Wave` = `{float delay; int land_count; int sea_count; bool fired}` (`sim_world.h:105`) — delay in combat seconds | `add_wave` (`:444`), `clear_waves` (`:440`), `check_and_spawn_waves` (fires), `start_combat`/`reset_run` (clear `fired`), `debug_jump_wave`, `load_state`; GD: `load_level_json` builds from level JSON |
| `grid_size_` | `Vec2i` | `sim_world.h:236` | **no** (see §8.3) | cells; 8×5 today | `init_grids` only |

Victory condition (all shared): `in_combat_ && combat_time_ >= victory_time_ && raider_count() == 0 && all waves fired` (`tick`, `sim_world.cpp:508`). Defeat is `hq_hp_ <= 0` (emitted as `hq_destroyed`).

### 5. Entity collections (per-entity front tag)

`raiders_` (`sim_world.h:231`) and `defenders_` (`sim_world.h:232`) are single shared vectors; each element carries its `front` (0/1). Dead entities are pruned at the end of every `tick` (`sim_world.cpp:499`–`507`), so between ticks the vectors can still contain `alive = false` entries.

**Raider** (`sim_world.h:65`, defaults per wave spawn in `spawn_wave_raiders` `sim_world.cpp:389`):

| Member | Type | In snapshot (`.fbs` Raider)? | Units / values today | Mutated by |
| --- | --- | --- | --- | --- |
| `id` | `int` | yes (`.fbs:36`) | 1.. (raider id space) | assigned at `spawn_raider` |
| `front` | `int` | yes (`.fbs:37`) | 0 land / 1 sea; fixed at spawn — raiders never change front | spawn |
| `path` | `std::vector<Vec2>` | yes (`.fbs:38`) | world px; empty ⇒ flow-field mode | spawn (lane) or left empty (flow) |
| `hp` / `max_hp` | `float` | yes (`.fbs:39`/`40`) | wave spawn: `50 + 3*wave_index` | defender fire, hero casts, `damage_raider` |
| `speed` | `float` | yes (`.fbs:41`) | px/s; wave spawn: `26 + 2*(wave_index % 4)` | spawn only |
| `damage` | `float` | yes (`.fbs:42`) | damage per HQ/outpost strike; wave spawn: 6.0 | spawn only |
| `path_i` | `int` | yes (`.fbs:43`) | index into `path`, lane mode only | `advance_raider_along_path` |
| `outpost_path_i` | `int` | yes (`.fbs:44`) | −1 (flow) or ≥ 1; default `max(1, path.size()/2)` | spawn |
| `struck_outpost` | `bool` | yes (`.fbs:45`) | one-shot outpost strike flag | advance (lane: `path_i >= outpost_path_i`; flow: `cell.x >= grid_size_.x/2`) |
| `alive` | `bool` | yes (`.fbs:46`) | — | combat/hero/debug kills, HQ arrival |
| `position` | `Vec2` | yes (`.fbs:47`) | world px | advance functions per tick |
| `entry_row` | `int` | **no** | grid row (0..height−1) or −1 | `spawn_raider`/`pick_entry_row`/`debug_spawn_raider_at` |

Spawn cap: `spawn_raider` refuses when `raiders_.size() >= 40` (`sim_world.cpp:136`).

**Defender** (`sim_world.h:81`):

| Member | Type | In snapshot (`.fbs` Defender)? | Units / values today | Mutated by |
| --- | --- | --- | --- | --- |
| `id` | `int` | yes (`.fbs:12`) | 10001.. | assigned at `spawn_defender` |
| `front` | `int` | yes (`.fbs:13`) | 0/1 — **can change** via redeploy | spawn; `start_defender_travel` (`sim_world.cpp:232`) sets the target front immediately |
| `type` | `std::string` | yes (`.fbs:14`) | `spearman`, `cannon`, `hero_qi`, `hero_dias`, … (`game/scripts/data/unit_defs.gd`) | spawn only |
| `position` | `Vec2` | yes (`.fbs:15`) | world px | `run_travel` (`sim_world.cpp:320`) |
| `hp` | `float` | yes (`.fbs:17`) | 100 at spawn | **nothing ever reduces it in Slice-0** — raiders do not attack defenders |
| `range_px`, `damage`, `cooldown` | `float` | yes (`.fbs:18`–`20`) | range px / damage per shot / seconds between shots | `upgrade_defender` (`sim_world.cpp:221`: damage ×1.25, range +12) |
| `cooldown_left`, `ability_cooldown`, `ability_cooldown_left` | `float` | yes (`.fbs:21`–`23`) | seconds; ability CD 8 s (Qi) / 10 s (Dias) | `run_defender_combat`, `cast_hero_ability` |
| `own_env_mult` / `cross_env_mult` | `float` | yes (`.fbs:31`/`32`) | multipliers, see §6 | spawn only |
| `aura_radius` / `aura_bonus` | `float` | yes (`.fbs:29`/`30`) | px / additive damage bonus | spawn only |
| `traveling`, `travel_from`, `travel_to`, `travel_t`, `travel_duration` | `bool`/`Vec2`×2/`float`×2 | yes (`.fbs:24`–`28`) | duration default 1.6 s, min 0.2 s | `start_defender_travel`, `run_travel` |
| `alive` | `bool` | yes (`.fbs:16`) | always true today — nothing kills a defender | (none in Slice-0) |

Hero uniqueness: `spawn_defender` rejects a second living hero of the same type (`sim_world.cpp:192`), so at most one `hero_qi` and one `hero_dias` exist.

### 6. Cross-front modifiers (as implemented)

These are the only mechanisms by which one front's state affects the other's simulation:

1. **Single shared HQ.** Raiders from both fronts drain the same `hq_hp_` (§4). The sea player losing their lane eventually kills the land player — this is the core shared resource.
2. **`cross_env_mult` targeting.** `run_defender_combat` (`sim_world.cpp:335`) picks `own_env_mult` when `raider.front == defender.front`, else `cross_env_mult` (skipped if ≤ 0), subject to `range_px`. Because the land/sea world origins are 400 px apart, cross-front auto-fire only occurs for long-range units or after a hero redeploy changes its `front`; the per-type values (e.g. Qi 0.35, cannon 0.65 vs. own 1.0, per `game/scripts/data/unit_defs.gd`) are what makes it meaningful when it happens.
3. **Aura (front-agnostic).** `total_aura_at` (`sim_world.cpp:307`) sums `aura_bonus` of any living defender within `aura_radius` px, regardless of front. In the default layout the 400 px origin gap makes cross-front aura overlap effectively impossible, but the code has no front check.
4. **Dias cross-front salvo.** `cast_hero_ability` for `hero_dias` (`sim_world.cpp:278`) deals 22 damage to every living raider on the *opposite* front, ignoring distance — the one truly distance-free cross-front interaction (comment at `:280` explains why: no world radius, the grids are hundreds of px apart by design).
5. **Qi pulse (front-agnostic radius).** `hero_qi`/`hero` ability (`sim_world.cpp:258`) deals 35 damage to all raiders within 250 px of the hero, on either front.
6. **Hero redeploy across fronts.** `start_defender_travel(id, to, new_front)` lets a hero change `front` mid-run; travel takes ~1.6 s with no firing while moving (`run_travel`).
7. **Per-wave counts.** Each `Wave` carries both `land_count` and `sea_count`, fired atomically by the single shared clock (`check_and_spawn_waves`) — the two fronts' raid pressure is scheduled together, not independently.

### 7. Level-JSON → runtime-state mapping

`SimulationCore::load_level_json` (`game/src/cpp/simulation_core.cpp:263`) parses the level file (e.g. `game/assets/levels/slice0_dual_front.json`) and maps it onto `SimWorld`:

| Level JSON key | Runtime state | Mutator |
| --- | --- | --- |
| `startingLandCurrency` | `land_resources_` | `reset_run(land, …)` |
| `startingSeaCurrency` | `sea_resources_` | `reset_run(…, sea, …)` |
| `hqMaxHp` | `hq_hp_`, `hq_max_hp_` | `reset_run(…, hq)` (sets both) |
| `buildPhaseSeconds` | `build_phase_seconds_` | `set_build_phase_seconds` |
| `victoryTimeSeconds` | `victory_time_` | `set_victory_time` |
| `waves[i].delaySeconds` | `Wave.delay` | `add_wave` |
| `waves[i].landCount` (fallback `enemyCount`) | `Wave.land_count` | `add_wave` |
| `waves[i].seaCount` | `Wave.sea_count` | `add_wave` |

If the JSON has no `waves` array (or it parses empty), `load_level_json` installs four built-in waves (delays 2/12/24/38 s, counts 2/2 → 5/5).

**Not consumed by the C++ core:** `id`, `displayName`, `civPrimary`, `civSupport`, `enemySpawnIntervalSeconds`, `spawnPattern`. `id`/`displayName` are used by the GDScript `LevelCatalog` (`game/scripts/data/level_catalog.gd`) for the level picker; the rest are inert in `SimulationCore`. Outpost HP/max is *not* level-configurable — it is the hardcoded 40 default from `sim_world.h:223`/`224`.

**Finding — stale JSON schema:** `game/src/level-schema.json` still describes the legacy single-front level shape (waves require `enemyCount` + `spawnPattern` ∈ {`row`,`scattered`}). The dual-front levels (`slice0_dual_front.json`, `night_tide_dual_front.json`) use `landCount`/`seaCount` and `spawnPattern: "lane"`, so they do **not** validate against it. The enforcement that actually gates dual-front levels today is the GDScript `LevelCatalog` check that every wave carries both `landCount` and `seaCount` (`level_catalog.gd:48`).

### 8. FlatBuffers snapshot coverage (S4)

`SimWorld::save_state` (`sim_world.cpp:820`) serializes to the schema in `game/src/schema/simulation_state.fbs` (`root_type SimulationState`, `schema_version:int = 1`); `SimulationCore.save_state()`/`load_state()` expose it to Godot, and `OfflinePersistence.write_snapshot`/`read_snapshot` (`game/scripts/data/offline_persistence.gd`) persist the bytes at `user://mf_slice0_snapshot.bin`. `BattleRoot` saves on **S**/Save, auto-saves at run end (`battle_root.gd:492`), and resumes via `GameSession.resume_snapshot_on_next_battle` (`battle_root.gd:70`). The schema header comment already names its second purpose: "Used for offline save/load and later net replication."

### 8.1 What the snapshot covers

Every scalar and collection in §2–§5 marked "yes" — i.e. the full `SimulationState` table: both economies, HQ, both outposts, kill/place counters, phase/clock/wave index, build/victory timers, income accumulator, both id allocators, all defenders (including travel and cross-front multiplier state), all raiders (including lane paths and the strike flag), the wave schedule, both lane paths, and `schema_version`.

### 8.2 Load-time guards in `load_state` (`sim_world.cpp:877`)

FlatBuffers verification runs first (`VerifySimulationStateBuffer`); then: `land/sea_outpost_max` kept only if > 0, `build_phase_seconds`/`victory_time` only if > 0, `next_raider_id`/`next_defender_id` only if > 0 (else 1 / 10001), raider `max_hp` falls back to `hp`, defender `travel_duration` falls back to 1.6 s. All other fields overwrite unconditionally.

### 8.3 In runtime state but NOT in the snapshot — real findings

These pieces of `SimWorld` state exist at runtime and are lost (or rebuilt by fixed setup) across save/load:

1. **`land_flow_` / `sea_flow_` and `grid_size_` (flow-field grids).** Not serialized. After `load_state`, flow is whatever the caller last initialized. `BattleRoot.load_snapshot` relies on `_setup_grids()` having run earlier in `_ready` (fixed 8×5, both outpost cells solid at `(4,2)`, `battle_root.gd:111`–`114`), then best-effort re-solidifies defender cells from positions via `_rebuild_placement_from_sim` — mid-travel defenders are skipped (`battle_root.gd`), so a snapshot taken while a hero travels restores with its origin cell walkable. A save made outside the modular battle scene (no `init_grids` call) would load with `flow_active() == false` and raiders would fall back to lane/default paths.
2. **`Raider.entry_row`.** Not serialized (no field in the `.fbs` Raider table, not written by `save_state`, not restored by `load_state` — it keeps the struct default −1). A flow-mode raider that is still off-grid (left of column 0) when saved will, after load, steer toward the mid row fallback instead of its assigned row (`advance_raider_along_flow`, `sim_world.cpp:597`). Minor today (spawns enter at column 0 quickly) but it is a genuine schema gap.
3. **Debug/cheat flags: `infinite_land_`, `infinite_sea_` (`sim_world.h:245`/`246`), `invincible_` (`:247`), `waves_disabled_` (`:248`).** Not serialized. A cheated run saved mid-combat and reloaded in a fresh process resumes with cheats off (in-session loads keep current values because `load_state` does not touch these members). Deliberate for shipped saves, but it means the snapshot alone does not fully reconstruct observed behavior.
4. **No snapshot for `SimulationCore`'s EnTT registry** (`simulation_core.h:21`) — its `Position`/`Velocity`/`Health` components are legacy scaffolding (`spawn_entity`/`_process`, unused by the dual-front battle) and carry no game state. Listed only to preempt "is anything else alive in C++?" questions.

### 9. Presentation-only state (not simulation state)

These mirror or wrap `SimWorld` and must not be treated as authority — they are what C2 needs to classify as "presentation-only":

- `GameSession` (`game/scripts/autoload/game_session.gd`) keeps `land_currency`, `sea_currency`, `hq_hp`, `hq_max_hp`, `enemies_killed`, `units_placed`, `outposts_lost` as GDScript copies, re-synced from the sim by `BattleRoot._sync_session_from_sim` (`battle_root.gd`); they drive HUD and the end-of-run results JSON (`user://last_run_results.json`, schema v1, written by `OfflinePersistence.write_results`).
- `BattleRoot` phase/timer mirrors: `build_time_left`, `combat_time`, `wave_index`, `run_over` — rebuilt from the sim after a snapshot load.
- `GridFront` occupants and `cell_by_defender` (which defender sits on which cell) — GDScript placement bookkeeping, rebuilt from `sim.get_defenders()` positions after load.
- Dev-overlay mirrors: `time_scale`, `last_sim_tick_ms`, `last_raider_land`/`sea`, `last_defender_count` (`game_session.gd`) — diagnostics only.
- The classic `main.gd` prototype keeps its own unrelated JSON save (`user://mobile_fortress_slice0.json`); it is not dual-front state.

## Part 2 — Co-op proposal (NOT implemented)

> **Everything below is a design proposal for roadmap item C2 (local Wi‑Fi asymmetric co-op: one player owns land, one owns sea). Nothing here is built.** It builds on [`co_op_modes.md`](../moon/roadmaps/co_op_modes.md) C2 and the "Sea-player role" section there.

### Authority split

Under the land/sea split, the natural ownership of the Part-1 state is:

| State | Owner | Rationale (from Part 1) |
| --- | --- | --- |
| `land_resources_` | Land player | Only mutated via land-front `spend`/`gain` (§2) |
| `sea_resources_` | Sea player | Mirror |
| `land_flow_` solids (placement locks on the land grid) | Land player | `set_cell_solid(0,·)` today comes only from land placements/redeploys |
| `sea_flow_` solids | Sea player | Mirror |
| Land-front defender placements/upgrades | Land player | `spawn_defender(0,·)`, `upgrade_defender` |
| Sea-front defender placements/upgrades | Sea player | Mirror |
| `hq_hp_` / `hq_max_hp_` | **Single authority (host)** | One HQ drained by both fronts (§6.1) — two writers must not race |
| `in_combat_`, `combat_time_`, `current_wave_`, `waves_`, `income_acc_`, `build_phase_seconds_`, `victory_time_` | **Single authority (host)** | One shared clock fires both fronts' wave counts atomically (§6.7) |
| `next_raider_id_`, `next_defender_id_` | **Single authority (host)** | One id space per entity kind; splitting per front would need a front bit in ids |
| Raider vectors, per-front | Raid director (host sim), informed by wave schedule | Raiders are hostile state; no player "owns" them |
| `enemies_killed_`, `units_placed_` | Host (derived) | Aggregates over both fronts |
| Outpost HP/alive, per-front | Host sim (combat outcome), *economically* attributed to that front's player | Damage comes from that front's raiders; income flows to that front's wallet |

Concretely: the host runs one authoritative `SimWorld` exactly as today; the guest runs a second `SimWorld` as a dumb presentation vessel whose state is overwritten by deltas (it already supports wholesale replacement via `load_state`). `SimulationCore` needs no structural change for that model — the delta format is the new work.

### Cross-front interactions needing host adjudication

The Part-1 cross-front modifiers (§6) are exactly the calls that cannot be resolved by one player alone:

- **Dias salvo** damages the *other* front's raiders — must execute on the host, or be a request the front-owner confirms. Proposed: host-authoritative, with an event echoed to both players.
- **Hero redeploy across fronts** (`start_defender_travel` with a new front) transfers a unit between ownership domains. Proposed: allowed, but the receiving player's client must be told the incoming occupant so its grid bookkeeping stays consistent.
- **Aura / Qi pulse radius** are front-agnostic in code; with the current 400 px origin gap they are same-front in practice, but the host should evaluate them so a future tighter layout needs no protocol change.
- **HQ damage** from either front is host-mutated; both players see the same number.

### Minimal per-tick delta

A per-tick delta does not need new concepts — it is a diff over the existing `SimulationState` fields (§8.1), plus the §8.3 gaps closed. Minimal contents:

- **Per front:** spawned raider records (id, front, hp, speed, damage, entry_row, position), raider removals (ids), raider position updates (or client-side dead-reckoned positions with periodic host correction), outpost hp/alive changes, resource balance changes (`land`/`sea` amounts, including income payouts), defender additions/upgrades/ redeploy-start events.
- **Shared:** hq_hp changes, wave-fired index, `in_combat`/`current_wave`/clock transitions, victory/defeat.
- **On join or resync:** the full snapshot (already implemented and verified by `flatbuffers_smoke.gd`) is the state-transfer primitive; deltas only need to cover the gap between snapshots.

Schema work this implies (a `schema_version` bump, not a change to the shipped v1 file): add the flow grids (or their solid masks + `grid_size_`) and `Raider.entry_row` so a snapshot truly reconstructs the run (§8.3), and decide whether cheat flags belong in a dev-only snapshot variant.

### Open questions

1. **Income timing.** The 4 s income tick is part of the shared clock; should payout events be host-emitted events (both wallets settle at the same tick) or per-front local timers? Host-emitted matches today's `income` event.
2. **Build phase negotiation.** Today one player starts combat; in 2P, does starting combat require both players to ready, or is it the host's call? Not a state-schema question, but the schema must record *who* transitioned `in_combat_`.
3. **Save format in co-op.** One snapshot on the host, or per-player? The single-`SimWorld` model argues for host-only, with the guest rebuilding from the same delta stream.
4. **ID namespaces.** Raider ids 1.. and defender ids 10001.. are shared across fronts. Keeping host allocation avoids collisions; per-front allocation would need a front discriminator added to ids.
5. **Guest autonomy for presentation.** Whether the guest's `SimWorld` ticks locally (drift-corrected) or is a pure replay vessel. Pure replay is simpler and matches the "server-authoritative replication is sufficient" non-goal stance in [`co_op_modes.md`](../moon/roadmaps/co_op_modes.md) (no lockstep requirement).
6. **Cross-front resource gifts.** The roadmap mentions upgrades requiring land-only or sea-only resources; today there is no transfer API (`gain` is host-internal). A `transfer(from_front, to_front, amount)` operation would be the first genuinely new state transition C2 needs.
