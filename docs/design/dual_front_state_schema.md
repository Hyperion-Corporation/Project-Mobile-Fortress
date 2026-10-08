# Dual-Front Simulation State Schema

*Last updated: 2026-10-08. Reference for the dual-front simulation state as implemented in the Slice-0 C++ core (`SimWorld`), plus a clearly separated proposal for the C2 local Wi‑Fi asymmetric co-op.*

**Status:** Part 1 is a source-accurate description of what exists today ([`game/src/cpp/`](https://github.com/Hyperion-Corporation/Project-Mobile-Fortress/tree/main/game/src/cpp) + FlatBuffers snapshot [`simulation_state.fbs`](https://github.com/Hyperion-Corporation/Project-Mobile-Fortress/blob/main/game/src/schema/simulation_state.fbs)). Part 2 is a **proposal — nothing in it is implemented**. Line references are stable as of commit `e248146`.

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
  - [9. GDScript state: presentation and gameplay orchestration](#9-gdscript-state-presentation-and-gameplay-orchestration)
- [Part 2 — Co-op proposal (NOT implemented)](#part-2--co-op-proposal-not-implemented)

## Part 1 — As implemented

### 1. Architecture and front convention

Core combat/economy state lives in the Godot-free C++ class `mf::SimWorld` (`game/src/cpp/sim_world.h:119`), a plain value object with no engine dependencies. `SimulationCore` (`game/src/cpp/simulation_core.h:16`) is the GDExtension façade that Godot calls into; it owns one `SimWorld` instance and translates `Vector2`/`PackedVector2Array`/`Dictionary` at the boundary (`game/src/cpp/simulation_core.cpp`). GDScript (`game/scripts/battle/battle_root.gd`, `game/scripts/autoload/game_session.gd`) also owns gameplay orchestration: build countdown, pause/time scaling, placement validation, and terminal phase. These are not all presentation-only or captured by the C++ snapshot (see §9).

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

Everything below lists each piece of state with: C++ type, location, snapshot coverage (field in `game/src/schema/simulation_state.fbs`), units/range, and mutators. "GD" means the mutation originates from a Godot call through `SimulationCore`. Ranges below describe normal gameplay, not a validated input contract: most numeric spawn/JSON/snapshot values are not range-checked. `load_state` replaces all serialized fields subject to §8.2, including entity members described as spawn-only below. `reset_run` resets wallets/HQ/counters/ids/clock/cheats, clears entities and wave fired flags, and recomputes flow costs/directions while retaining solids, grid size, paths, wave definitions, timers and outpost maxima (`SimWorld::reset_run`).

### 2. Land-front-only state

| Field (symbol) | Type | Lives at | In snapshot? | Units / range | Mutated by |
| --- | --- | --- | --- | --- | --- |
| `land_resources_` | `int` | `sim_world.h:215` (default 14) | yes — `land_resources` (`.fbs:59`) | currency (兩), ≥ 0 | `spend(0,·)` (`sim_world.cpp:45`), `gain(0,·)` (`:85`), income in `tick` (`:460`), `debug_set_resources` (`:1013`), `debug_apply_income` (`:1042`), `reset_run` (`:9`), `load_state` (`:877`); GD: unit placement, DT1 cheats |
| `land_outpost_hp_` | `int` | `sim_world.h:221` (default 40) | yes — `land_outpost_hp` (`.fbs:63`) | HP, 0..`land_outpost_max_` | `damage_outpost(0,·)` from a land raider crossing mid-path (`sim_world.cpp:615`), `set_outpost_alive` (`:103`), `reset_run`, `load_state` |
| `land_outpost_max_` | `int` | `sim_world.h:223` (default 40) | yes — `land_outpost_max` (`.fbs:65`, default 40) | HP; not settable from level JSON — hardcoded default | `load_state` (only if snapshot value > 0); initialized at construction; `reset_run` retains the maximum and restores HP to it |
| `land_outpost_alive_` | `bool` | `sim_world.h:225` (default true) | yes — `land_outpost_alive` (`.fbs:67`) | — | `damage_outpost` (false when hp reaches 0), `set_outpost_alive`, `reset_run`, `load_state` |
| `land_flow_` | `std::vector<FlowCell>` | `sim_world.h:234` | yes — `land_flow` (schema v2; see §8) | `FlowCell` = `{int cost = 9999; Vec2i dir{0,0}; bool solid = false;}` (`sim_world.h:112`) — 8×5 = 40 cells; cost is BFS steps (9999 unreachable), dir is a cardinal cell step or zero, solid blocks traversal | `init_grids` (`sim_world.cpp:654`), `set_cell_solid(0,·)` (`:738`, triggers `update_flow_field`), `update_flow_field` (`:750`); GD: placement/redeploy solidify cells, outpost cell (4,2) |
| `land_path_` | `std::vector<Vec2>` (px) | `sim_world.h:237` | yes — `land_path` (`.fbs:88`) | world-space px polyline | `set_lane_path(0,·)` (`sim_world.cpp:121`), `load_state`; GD: `battle_root.gd:53` sets it from the land `GridFront` |

Land outpost income rule: `outpost_income(hp, max, alive)` (`sim_world.cpp:76`) returns 0 if dead, HP ≤ 0, or max HP ≤ 0, else `max(1, 2*hp/max)` — i.e. a standing outpost pays 1–2 兩 per income tick. Outpost loss is economic only (loss event carries `economic_only = true`, `sim_world.cpp:649`).

### 3. Sea-front-only state

Exact mirror of §2 with `sea` names — no structural asymmetry in the core:

| Field | Type | Lives at | In snapshot? | Notes |
| --- | --- | --- | --- | --- |
| `sea_resources_` | `int` | `sim_world.h:216` (default 14) | yes — `sea_resources` (`.fbs:60`) | same mutators as land, front=1; `infinite_sea_` guards `spend` |
| `sea_outpost_hp_` / `sea_outpost_max_` / `sea_outpost_alive_` | `int`/`int`/`bool` | `sim_world.h:222`/`224`/`226` | yes — `.fbs:64`/`66`/`68` | sea raider crossing mid-path damages the Trading Outpost |
| `sea_flow_` | `std::vector<FlowCell>` | `sim_world.h:235` | yes — `sea_flow` (schema v2; see §8) | same 8×5 shape, rebuilt by `init_grids` |
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
| `current_wave_` | `int` | `sim_world.h:240` | yes — `current_wave` (`.fbs:75`) | 0-based next wave index; 0..`waves_.size()` (size means exhausted) | `check_and_spawn_waves` (`:414`), `start_combat`, `debug_jump_wave`, `load_state` |
| `build_phase_seconds_` | `float` | `sim_world.h:243` (default 40) | yes — `build_phase_seconds` (`.fbs:76`, default 40) | seconds, > 0 | `set_build_phase_seconds` (`:448`, ignores ≤ 0), from level JSON; `load_state` (only if > 0) |
| `victory_time_` | `float` | `sim_world.h:244` (default 55) | yes — `victory_time` (`.fbs:77`, default 55) | seconds, > 0 | `set_victory_time` (`:454`, ignores ≤ 0), from level JSON; `load_state` (only if > 0) |
| `income_acc_` | `float` | `sim_world.h:227` | yes — `income_acc` (`.fbs:78`) | seconds, normally 0 ≤ value < 4 after tick | `tick` — accumulates delta, pays out and resets at 4.0 s (`sim_world.cpp:466`–`467`) |
| `next_raider_id_` | `int` | `sim_world.h:228` (starts 1) | yes — `next_raider_id` (`.fbs:79`) | count; raiders use 1.., defenders 10001.. | `spawn_raider` (`:134`) |
| `next_defender_id_` | `int` | `sim_world.h:229` (starts 10001) | yes — `next_defender_id` (`.fbs:80`) | — | `spawn_defender` |
| `waves_` | `std::vector<Wave>` | `sim_world.h:233` | yes — `waves` (`.fbs:85`) | `Wave` = `{float delay; int land_count; int sea_count; bool fired}` (`sim_world.h:105`) — delay in combat seconds; counts normally ≥ 0, not validated; `fired` is a flag, initially false (`.fbs:51`–`54`) | `add_wave` (`:444`), `clear_waves` (`:440`), `check_and_spawn_waves` (fires), `start_combat`/`reset_run` (clear `fired`), `debug_jump_wave`, `load_state`; GD: `load_level_json` builds from level JSON |
| `grid_size_` | `Vec2i` | `sim_world.h:236` | yes — `grid_width` / `grid_height` (schema v2; 0 means uninitialized) | cells; 8×5 today | `init_grids` only |

Victory condition (all shared): `in_combat_ && combat_time_ >= victory_time_ && raider_count() == 0 && all waves fired` (`tick`, `sim_world.cpp:508`). Defeat is `hq_hp_ <= 0` (emitted as `hq_destroyed`).

### 5. Entity collections (per-entity front tag)

`raiders_` (`std::vector<Raider>`, `sim_world.h:231`, snapshot `raiders`, `.fbs:84`) and `defenders_` (`std::vector<Defender>`, `sim_world.h:232`, snapshot `defenders`, `.fbs:83`) are single shared vectors, populated by their spawn methods, cleared by `reset_run`, and replaced by `load_state`; each element carries its `front` (0/1). Dead entities are pruned at the end of every `tick` (`sim_world.cpp:499`–`507`), so explicit kills between ticks can leave `alive = false` entries until the next tick.

**Raider** (`sim_world.h:65`, defaults per wave spawn in `spawn_wave_raiders` `sim_world.cpp:389`):

| Member | Type | In snapshot (`.fbs` Raider)? | Units / values today | Mutated by |
| --- | --- | --- | --- | --- |
| `id` | `int` | yes (`.fbs:36`) | 1.. (raider id space) | assigned at `spawn_raider` |
| `front` | `int` | yes (`.fbs:37`) | 0 land / 1 sea; fixed at spawn — raiders never change front | spawn |
| `path` | `std::vector<Vec2>` | yes (`.fbs:38`) | world px; empty ⇒ flow-field mode | spawn (lane) or left empty (flow) |
| `hp` / `max_hp` | `float` | yes (`.fbs:39`/`40`) | wave spawn: `50 + 3*wave_index`; HP may become ≤ 0 on death | spawn sets both; only `hp` changes under defender fire, hero casts, `damage_raider` |
| `speed` | `float` | yes (`.fbs:41`) | px/s; wave spawn: `26 + 2*(wave_index % 4)` | spawn only |
| `damage` | `float` | yes (`.fbs:42`) | damage per HQ/outpost strike; wave spawn: 6.0 | spawn only |
| `path_i` | `int` | yes — `path_index` (`.fbs:43`) | index into `path`, lane mode only | `advance_raider_along_path` |
| `outpost_path_i` | `int` | yes — `outpost_path_index` (`.fbs:44`) | −1 (flow) or ≥ 1; default `max(1, path.size()/2)` | spawn |
| `struck_outpost` | `bool` | yes (`.fbs:45`) | one-shot outpost strike flag | advance (lane: `path_i >= outpost_path_i`; flow: `cell.x >= grid_size_.x/2`) |
| `alive` | `bool` | yes (`.fbs:46`) | — | combat/hero/debug kills, HQ arrival |
| `position` | `Vec2` | yes (`.fbs:47`) | world px | advance functions per tick |
| `entry_row` | `int` | yes — `entry_row` (schema v2, default −1) | grid row (0..height−1) or −1 | `spawn_raider`/`pick_entry_row`/`debug_spawn_raider_at` |

Spawn cap: `spawn_raider` refuses when `raiders_.size() >= 40` (`sim_world.cpp:136`).

**Defender** (`sim_world.h:81`):

| Member | Type | In snapshot (`.fbs` Defender)? | Units / values today | Mutated by |
| --- | --- | --- | --- | --- |
| `id` | `int` | yes (`.fbs:12`) | 10001.. | assigned at `spawn_defender` |
| `front` | `int` | yes (`.fbs:13`) | 0/1 — **can change** via redeploy | spawn; `start_defender_travel` (`sim_world.cpp:232`) sets the target front immediately |
| `type` | `std::string` | yes (`.fbs:14`) | `spearman`, `cannon`, `hero_qi`, `hero_dias`, … (`game/scripts/data/unit_defs.gd`) | spawn only |
| `position` | `Vec2` | yes (`.fbs:15`) | world px | `run_travel` (`sim_world.cpp:320`) |
| `hp` | `float` | yes (`.fbs:17`) | 100 at spawn | **nothing ever reduces it in Slice-0** — raiders do not attack defenders |
| `range_px`, `damage`, `cooldown` | `float` | yes (`.fbs:18`–`20`) | range px / damage per shot / seconds between shots (≥ 0.1 at spawn) | spawn sets all; only damage/range change under `upgrade_defender` (`sim_world.cpp:221`: damage ×1.25, range +12) |
| `cooldown_left`, `ability_cooldown`, `ability_cooldown_left` | `float` | yes (`.fbs:21`–`23`) | seconds; cooldown min 0.1 s at spawn; remaining cooldowns can undershoot zero; ability CD 8 s (Qi) / 10 s (Dias) | `run_defender_combat`, `cast_hero_ability` |
| `own_env_mult` / `cross_env_mult` | `float` | yes (`.fbs:31`/`32`) | multipliers, see §6 | spawn only |
| `aura_radius` / `aura_bonus` | `float` | yes (`.fbs:29`/`30`) | px / additive damage bonus | spawn only |
| `traveling`, `travel_from`, `travel_to`, `travel_t`, `travel_duration` | `bool`/`Vec2`×2/`float`×2 | yes (`.fbs:24`–`28`) | positions in world px; `travel_t` dimensionless progress (can exceed 1 on final tick, interpolation clamps); duration in seconds, default 1.6 s, min 0.2 s at travel start | `start_defender_travel`, `run_travel` |
| `alive` | `bool` | yes (`.fbs:16`) | always true today — nothing kills a defender | (none in Slice-0) |

Hero uniqueness: `spawn_defender` rejects a second living hero of the same type (`sim_world.cpp:192`), so at most one `hero_qi` and one `hero_dias` exist through normal spawning (the legacy `hero` alias is a separate exact type string; snapshots do not enforce uniqueness).

### 6. Cross-front modifiers (as implemented)

Core cross-front interactions and shared scheduling:

1. **Single shared HQ.** Raiders from both fronts drain the same `hq_hp_` (§4). The sea player losing their lane eventually kills the land player — this is the core shared resource.
2. **`cross_env_mult` targeting.** `run_defender_combat` (`sim_world.cpp:335`) picks `own_env_mult` when `raider.front == defender.front`, else `cross_env_mult` (skipped if ≤ 0), subject to `range_px`. Because the land/sea world origins are 400 px apart, cross-front auto-fire still requires actual world-space range; changing a hero’s front does not bypass this check, and traveling defenders do not fire; the per-type values (e.g. Qi 0.5, cannon 0.35 vs. own 1.0, per `game/scripts/data/unit_defs.gd`) are what makes it meaningful when it happens.
3. **Aura (front-agnostic).** `total_aura_at` (`sim_world.cpp:307`) sums `aura_bonus` of any living defender within `aura_radius` px, regardless of front. Stationary units on the default grids are farther apart than current aura radii, but the code has no front check and includes traveling aura providers; a redeploy can change overlap.
4. **Dias cross-front salvo.** `cast_hero_ability` for `hero_dias` (`sim_world.cpp:278`) deals 22 damage to every living raider on the *opposite* front, ignoring distance — a distance-free cross-front attack (comment at `:280` explains why: no world radius, the grids are hundreds of px apart by design).
5. **Qi pulse (front-agnostic radius).** `hero_qi`/`hero` ability (`sim_world.cpp:258`) deals 35 damage to all raiders within 250 px of the hero, on either front.
6. **Hero redeploy across fronts.** `start_defender_travel(id, to, new_front)` lets a hero change `front` mid-run; travel takes ~1.6 s with no firing while moving (`run_travel`). The C++ method accepts any living, non-traveling defender; the normal UI restricts selection for redeploy to heroes.
7. **Per-wave counts.** Each `Wave` carries both `land_count` and `sea_count`, fired atomically by the single shared clock (`check_and_spawn_waves`) — at most one wave fires per tick, land spawns first, and both share the 40-raider cap, so land spawning can limit sea spawning.

8. **Placement currency policy (GDScript).** `BattleRoot._on_cell_clicked` spends the unit definition’s preferred wallet first and may fall back to the destination front’s wallet. Placement on one front can therefore spend the other front’s funds; co-op must authorize this policy explicitly.

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

Missing currency/HQ keys retain the current wallet balances/HQ maximum; missing or nonpositive timer keys retain existing timers. Wave defaults are delay 0, land count `enemyCount` or 2, and sea count 2. Non-dictionary wave entries are skipped. Counts/delays are passed through without range checks.

If the JSON has no `waves` array (or yields no dictionary entries), `load_level_json` installs four built-in waves (delays 2/12/24/38 s, counts 2/2 → 5/5).

**Not consumed by the C++ core:** `id`, `displayName`, `civPrimary`, `civSupport`, `enemySpawnIntervalSeconds`, `spawnPattern`. `id`/`displayName` are used by the GDScript `LevelCatalog` (`game/scripts/data/level_catalog.gd`) for the level picker; the rest are inert in `SimulationCore`. Outpost HP/max is *not* level-configurable — it is the hardcoded 40 default from `sim_world.h:223`/`224`.

**Finding — stale JSON schema:** `game/src/level-schema.json` still describes the legacy single-front level shape (waves require `enemyCount` + `spawnPattern` ∈ {`row`,`scattered`}). The dual-front levels (`slice0_dual_front.json`, `night_tide_dual_front.json`) use `landCount`/`seaCount` and `spawnPattern: "lane"`, so they do **not** validate against it. The catalog filter checks only the **first** wave for both `landCount` and `seaCount` (`LevelCatalog::parse_level`, `level_catalog.gd:48`). It does not validate later waves or numeric ranges, and direct `SimulationCore::load_level_json` calls bypass this filter.

### 8. FlatBuffers snapshot coverage (S4)

`SimWorld::save_state` serializes to the schema in `game/src/schema/simulation_state.fbs` (`root_type SimulationState`). New snapshots write `schema_version` 2. `SimulationCore.save_state()`/`load_state()` expose it to Godot, and `OfflinePersistence.write_snapshot`/`read_snapshot` (`game/scripts/data/offline_persistence.gd`) persist the bytes at `user://mf_slice0_snapshot.bin`. `BattleRoot` saves on **S**/Save, auto-saves at run end, and resumes via `GameSession.resume_snapshot_on_next_battle`. The schema header comment already names its second purpose: "Used for offline save/load and later net replication." File:line cites elsewhere in this doc are the T41 baseline and are not renumbered here.

### 8.1 What the snapshot covers

Every scalar and collection in §2–§5 marked "yes", plus the schema v2 fields: `grid_width` / `grid_height`, both `land_flow` and `sea_flow` (`FlowCell` cost, direction, solid), `Raider.entry_row`, and the DDA inputs `dda_enabled`, `dda_wave_open`, `dda_wave_spawn_time`, `dda_last_clear_seconds`, and `dda_purse_baseline`. That is both economies, HQ, both outposts, kill/place counters, phase/clock/wave index, build/victory timers, income accumulator, both id allocators, all defenders (including travel and cross-front multiplier state), all raiders (including lane paths, the strike flag, and entry row), the wave schedule, both lane paths, and `schema_version`.

DDA inputs are the scalars `dda_intensity()` does not recompute from HQ, outposts, and currency. With them stored, a v2 resume makes the same next-wave count and HP decision as the run that was saved.

### 8.2 Load-time guards in `load_state`

FlatBuffers verification runs first (`VerifySimulationStateBuffer`); then: `land/sea_outpost_max` kept only if > 0, `build_phase_seconds`/`victory_time` only if > 0, `next_raider_id`/`next_defender_id` only if > 0 (else 1 / 10001), raider `max_hp` falls back to `hp`, defender `travel_duration` falls back to 1.6 s. Other serialized scalars are copied without semantic validation; missing vectors become empty, missing entity strings become empty, and missing Vec2 structs retain zero defaults on the newly constructed entities. `schema_version` is a snapshot-only `int`. There is no corresponding `SimWorld` member. FlatBuffers verification checks buffer structure, not HP/count/front/range invariants.

`schema_version` selects the flow and DDA rules:

- **Version ≥ 2.** `grid_width` and `grid_height` replace `grid_size_`. Both must be 0 (grids cleared) or both positive and each flow vector must be exactly `width * height` cells (otherwise `load_state` returns false before mutating). Each cell's cost, direction, and solid bit are copied, not recomputed. DDA enable, wave-open, spawn time, last clear, and purse baseline are copied. A baseline of 0 is stored as 1, matching `dda_intensity()`. `entry_row` is copied (older raiders that omit the field read as −1).
- **Version 1 (snapshots written before these fields existed).** Flow grids and `grid_size_` on the receiver are left alone. The DDA enable flag is left alone. The clear sample is dropped and the purse baseline rebases to the loaded land+sea total. A pre-change fixture in `game/tests/native/fixtures/s4_v1_midcombat.bin` locks this.

Either version, on success, clears the four cheat flags. A failed verification or a rejected v2 grid does not clear them, because `load_state` returns before mutating.

### 8.3 Findings from T41 / T38 — resolution (T47)

1. **`land_flow_` / `sea_flow_` and `grid_size_`.** Resolved for schema v2: both grids and the size are stored and restored exactly, including solids. A fresh core that never called `init_grids` can advance flow raiders after load. v1 snapshots still leave the receiver's grids in place, so an old save loaded into a core that has not set up grids still cannot move pathless raiders. GDScript placement mirrors (`GridFront.occupants`, `BattleRoot.cell_by_defender` in §9) are still outside this snapshot. C++ solids no longer depend on `_rebuild_placement_from_sim` to exist after a v2 load; that GDScript rebuild can still disagree with the restored solids until it is taught to trust them.
2. **`Raider.entry_row`.** Resolved for schema v2. An off-grid flow raider keeps its assigned row across save/load. v1 raiders still load as −1 and steer to the mid-row fallback until they are on a cell.
3. **Debug/cheat flags: `infinite_land_`, `infinite_sea_`, `invincible_`, `waves_disabled_`.** Deliberately not persisted. They are dev-session toggles, not raid state, and a saved run must not resume god mode in a fresh process or after an in-session load. Every successful `load_state` sets all four to false. `reset_run` still clears them too.
4. **DDA enable flag and its inputs (T38).** Resolved for schema v2, as listed in §8.1. v1 keeps the old session-flag / rebase behavior described in §8.2, so resumed decisions from an old snapshot can still differ from uninterrupted play until the next clear.
5. **No snapshot for `SimulationCore`'s EnTT registry** (`simulation_core.h`) — its `Position`/`Velocity`/`Health` components are legacy scaffolding (`spawn_entity`/`_process`, unused by the dual-front battle) and carry no game state. Still omitted on purpose.

### 9. GDScript state: presentation and gameplay orchestration

GDScript contains both derived display data and state that affects gameplay; none of these fields is stored directly in `SimulationState`:

- **Mirrors:** `GameSession.land_currency`, `sea_currency`, `hq_hp`, `hq_max_hp`, `enemies_killed`, `units_placed` are refreshed by `BattleRoot._sync_session_from_sim`. `combat_time` and `wave_index` similarly mirror core values. Visual nodes, selected-unit/defender UI, status messages and diagnostic counts/timings are presentation data.
- **Build/terminal orchestration:** `BattleRoot.phase` (`Phase` enum), `build_time_left` (`float`, seconds), and `run_over` (`bool`) control whether simulation advances. `_advance_sim` decrements the build countdown; `_start_combat` requires a defender; `_finish` sets RESULT and stops ticking. Snapshot load resets `run_over` to false and derives only BUILD/COMBAT from `in_combat_`; it resets build time to the full configured duration. Remaining build time and terminal phase are not restored. The legacy native-client spec in `game/src/game-state-machine.md` is not the modular battle state machine.
- **Pause/speed:** `GameSession.is_paused` (`bool`), `time_scale` (`float`, clamped 0.5..10 by its setter), `_step_pending` (`bool`) govern ticking (`BattleRoot._process`); stepping uses `STEP_DT = 1/30` s. These are gameplay controls, not diagnostics, and are not restored by the snapshot.
- **Placement:** `GridFront.occupants` and `BattleRoot.cell_by_defender` are dictionaries used to reject occupied destinations and clear origin cells. Their reconstruction is best-effort (§8.3), so they cannot be treated as display-only in co-op.
- **Run metadata/results:** `GameSession.outposts_lost` is an event-counted `int`, incremented by `_process_events`, not re-synced by `_sync_session_from_sim` and not restored by snapshot. Selected level path/id, `_run_recorded`, and `last_result` also live outside the snapshot. `end_run` writes separate results/history/progression JSON through `OfflinePersistence` and `Progression`; a snapshot does not identify its source level or restore those results. Resume can therefore retain the currently selected level metadata.
- The classic `main.gd` prototype keeps its own unrelated JSON save (`user://mobile_fortress_slice0.json`); it is not dual-front state.

## Part 2 — Co-op proposal (NOT implemented)

> **Everything below is a design proposal for roadmap item C2 (local Wi‑Fi asymmetric co-op: one player owns land, one owns sea). Nothing here is built.** It builds on [`co_op_modes.md`](../moon/roadmaps/co_op_modes.md) C2 and the "Sea-player role" section there.

### Authority split

Under the land/sea split, the natural ownership of the Part-1 state is:

| State | Owner | Rationale (from Part 1) |
| --- | --- | --- |
| `land_resources_` | Land player | Player requests spending; host applies spend/gain/income/debug changes (§2), including cross-wallet placement policy (§6.8) |
| `sea_resources_` | Sea player | Mirror |
| `land_flow_` solids (placement locks on the land grid) | Land player | Host validates placement/redeploy requests; setup/load also mutate solids |
| `sea_flow_` solids | Sea player | Mirror |
| Land-front defender placements/upgrades | Land player | `spawn_defender(0,·)`, `upgrade_defender` |
| Sea-front defender placements/upgrades | Sea player | Mirror |
| `hq_hp_` / `hq_max_hp_` | **Single authority (host)** | One HQ drained by both fronts (§6.1) — two writers must not race |
| `in_combat_`, `combat_time_`, `current_wave_`, `waves_`, `income_acc_`, `build_phase_seconds_`, `victory_time_` | **Single authority (host)** | One shared clock fires both fronts' wave counts atomically (§6.7) |
| `next_raider_id_`, `next_defender_id_` | **Single authority (host)** | One id space per entity kind; splitting per front would need a front bit in ids |
| Raider vectors, per-front | Raid director (host sim), informed by wave schedule | Raiders are hostile state; no player "owns" them |
| `enemies_killed_`, `units_placed_` | Host (derived) | Aggregates over both fronts |
| Outpost HP/alive, per-front | Host sim (combat outcome), *economically* attributed to that front's player | Damage comes from that front's raiders; income flows to that front's wallet |

Concretely: the host runs one authoritative `SimWorld` exactly as today; the guest runs a second `SimWorld` as a dumb presentation vessel whose state is overwritten by deltas (it already supports wholesale replacement via `load_state`). Whether `SimulationCore` needs additional apply-delta APIs depends on the chosen protocol; it currently exposes only wholesale snapshot load. The proposal must also cover the GDScript gameplay state in §9.

### Cross-front interactions needing host adjudication

The host must adjudicate cross-front effects and spending (§6), including:

- **Cross-wallet placement** must validate spending authority for both wallets before accepting the command.
- **Dias salvo** damages the *other* front's raiders — must execute on the host, or be a request the front-owner confirms. Proposed: host-authoritative, with an event echoed to both players.
- **Hero redeploy across fronts** (`start_defender_travel` with a new front) transfers a unit between ownership domains. Proposed: allowed, but the receiving player's client must be told the incoming occupant so its grid bookkeeping stays consistent.
- **Aura / Qi pulse radius** are front-agnostic and must be evaluated by the host using world positions. The 400 px origin gap is not the minimum distance between cells; it does not guarantee same-front-only effects.
- **HQ damage** from either front is host-mutated; both players see the same number.

### Minimal per-tick delta

A per-tick delta does not need new concepts — it is a diff over the existing `SimulationState` fields (§8.1), plus the §8.3 gaps closed. Candidate contents (not a finalized wire contract):

- **Per front:** spawned raider records (id, front, hp, speed, damage, entry_row, position), raider removals (ids), raider HP/position updates (or client-side dead-reckoned positions with periodic host correction), outpost hp/alive changes, resource balance changes (`land`/`sea` amounts, including income payouts), defender additions/removals/upgrades, cooldown/ability changes, and travel progress/completion or equivalent replayable events; changed solids/placement reservations.
- **Shared:** hq_hp changes, wave-fired index, `in_combat`/`current_wave`/clock transitions, victory/defeat, build countdown, pause/speed/step decisions and level identity (§9); any other snapshot field that changes must be replicated or explicitly derived.
- **On join or resync:** the full snapshot (already implemented and verified by `flatbuffers_smoke.gd`) is the state-transfer primitive; deltas only need to cover the gap between snapshots.

Schema v2 (appended fields; v1 buffers still load) now carries the flow grids, `grid_size_`, `Raider.entry_row`, and the DDA inputs. Cheat flags stay out of the snapshot and reset on load. Exact reconstruction still also needs the gameplay orchestration and placement mirrors in §9.

### Open questions

1. **Income timing.** The 4 s income tick is part of the shared clock; should payout events be host-emitted events (both wallets settle at the same tick) or per-front local timers? Host-emitted matches today's `income` event.
2. **Build phase negotiation.** Today one player starts combat; in 2P, does starting combat require both players to ready, or is it the host's call? Not a state-schema question, but the schema must record *who* transitioned `in_combat_`.
3. **Save format in co-op.** One snapshot on the host, or per-player? The single-`SimWorld` model argues for host-only, with the guest rebuilding from the same delta stream.
4. **ID namespaces.** Raider ids 1.. and defender ids 10001.. are shared across fronts. Keeping host allocation avoids collisions; per-front allocation would need a front discriminator added to ids.
5. **Guest autonomy for presentation.** Whether the guest's `SimWorld` ticks locally (drift-corrected) or is a pure replay vessel. Pure replay is simpler and matches the "server-authoritative replication is sufficient" non-goal stance in [`co_op_modes.md`](../moon/roadmaps/co_op_modes.md) (no lockstep requirement).
6. **Cross-front resource gifts.** The roadmap mentions upgrades requiring land-only or sea-only resources; today there is no atomic transfer API (`gain` is exposed to Godot). A proposed `transfer(from_front, to_front, amount)` operation would require host validation of both wallets.
