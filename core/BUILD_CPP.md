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
| `spawn_raider(front, path, hp, speed, damage)` | Lane raider |
| `damage_raider(id, amount)` | Combat |
| `tick(delta, income_enabled)` → events | Move raiders, income, HQ hits |
| `get_raiders()` | Render snapshot |

Next: FlatBuffers snapshots (S4), pathfinding systems, Godot module alternative.
