# Building `SimulationCore` (godot-cpp GDExtension)

Slice-0 can run **without** the native library (GDScript fallback). When
`bin/libmobile_fortress_core.so` is present and loads, `main.gd` uses the C++
sim for HQ/resources/raider motion.

## Prerequisites

- CMake ≥ 3.22, C++20 compiler, Git
- Godot 4.x matching the godot-cpp tag in `CMakeLists.txt` as closely as practical

## Build

```bash
cd core
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j$(nproc)
cp -f build/libmobile_fortress_core.so bin/libmobile_fortress_core.so
```

`mobile_fortress_core.gdextension` points Godot at `res://bin/libmobile_fortress_core.so`.

## API (Slice-0)

| Method | Purpose |
| --- | --- |
| `reset_run(land, sea, hq)` | New raid |
| `spend` / `gain` | Dual currencies |
| `spawn_raider` / `spawn_defender` | Entities |
| `set_lane_path` / `load_level_json` / `start_combat` | Waves |
| `tick(delta, income_enabled)` → events | Sim step |
| `save_state()` → `PackedByteArray` | FlatBuffers snapshot (S4) |
| `load_state(bytes)` | Restore snapshot |
| `get_raiders()` / `get_defenders()` | Render snapshots |

Schema: `src/schema/simulation_state.fbs` (generated into build dir by `flatc`).

```bash
# FlatBuffers contract test
godot --path core --headless --script res://tests/flatbuffers_smoke.gd
```

Next: Flow Field (S2/G3), async bridge (S6), mobile export (S8).
