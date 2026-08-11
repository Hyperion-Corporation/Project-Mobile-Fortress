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
mkdir -p bin
cp -f build/libmobile_fortress_core.so bin/libmobile_fortress_core.so
# Architecture-qualified name expected by mobile_fortress_core.gdextension
cp -f build/libmobile_fortress_core.so bin/libmobile_fortress_core.linux.x86_64.so
```

`mobile_fortress_core.gdextension` points Godot at `res://bin/libmobile_fortress_core.linux.x86_64.so` (and platform-specific names for Android/iOS when cross-built). Use **`;` comments only** in `.gdextension` files (`#` breaks library resolution in Godot’s ConfigFile parser).

Mobile packaging: see [`EXPORT_MOBILE.md`](EXPORT_MOBILE.md) and `scripts/export_mobile_smoke.sh`.

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
