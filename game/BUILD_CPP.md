# Building `SimulationCore` (godot-cpp GDExtension)

Slice-0 can run **without** the native library (GDScript fallback). When
`bin/libmobile_fortress_core.so` is present and loads, `main.gd` uses the C++
sim for HQ/resources/raider motion.

## Prerequisites

- CMake ≥ 3.22, C++20 compiler, Git
- Godot 4.x matching the godot-cpp tag in `CMakeLists.txt` as closely as practical

## Build

```bash
cd game
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j$(nproc)
mkdir -p bin
cp -f build/libmobile_fortress_core.so bin/libmobile_fortress_core.so
# Architecture-qualified name expected by mobile_fortress_core.gdextension
cp -f build/libmobile_fortress_core.so bin/libmobile_fortress_core.linux.x86_64.so
```

Native C++ tests (Q3/S7, no Godot process):

```bash
cmake --build game/build --target sim_world_tests -j$(nproc)
ctest --test-dir game/build --output-on-failure
```

`mobile_fortress_core.gdextension` points Godot at `res://bin/libmobile_fortress_core.linux.x86_64.so` (and platform-specific names for Android/iOS when cross-built). Use **`;` comments only** in `.gdextension` files (`#` breaks library resolution in Godot’s ConfigFile parser).

Mobile packaging: see [`EXPORT_MOBILE.md`](EXPORT_MOBILE.md) and `scripts/export_mobile_smoke.sh`.

## Android arm64 (S8)

One command from the repo root:

```bash
bash scripts/build_android_gdextension.sh
```

It cross-compiles godot-cpp and `mobile_fortress_core` with the NDK toolchain (`ANDROID_ABI=arm64-v8a`, `ANDROID_PLATFORM=android-33`, `ANDROID_STL=c++_shared`) into `game/build-android-arm64` and copies the shared object to `bin/libmobile_fortress_core.android.arm64.so`. That file is gitignored (`game/.gitignore` ignores `bin/` and `build-android-arm64/`). The desktop `game/build` tree is not configured or overwritten.

NDK lookup order: `ANDROID_NDK_HOME`, then the newest `$ANDROID_HOME/ndk/<revision>` (or `sdk.dir` from `local.properties` when `ANDROID_HOME` is unset). Verified here with **NDK r27c, Pkg.Revision 27.2.12479018**, installed at `/home/pkhunter/Android/Sdk/ndk/27.2.12479018`. The zip SHA1 `090e8083a715fdb1a3e402d0763c388abb03fb4e` matches the r27c release. A host `flatc` is required (the desktop build's `game/build/_deps/flatbuffers-build/flatc`, or `MF_HOST_FLATC`). Doctest and `sim_world_tests` are not part of the Android build.

**16 KB page size.** Android 15 and Play require native arm64 libraries to load on 16 KB page devices. The script passes `ANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES=ON`. On NDK r27 that adds `-Wl,-z,max-page-size=16384` for `arm64-v8a` and `x86_64` (`build/cmake/flags.cmake`). `CMakeLists.txt` also sets `LINKER:-z,max-page-size=16384` on `mobile_fortress_core`, so the shared object stays 16 KB-aligned even if that NDK option is omitted. `common-page-size` is left at the NDK default (4 KB): the LOAD segments are aligned to 16 KB, and the library still runs on 4 KB-page devices. That is the NDK r27 flexible-page-size choice, not a 16 KB-only binary.

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
godot --path game --headless --script res://tests/flatbuffers_smoke.gd
```

When `init_grids` has been called, `start_combat` / wave spawn uses **empty-path flow-field** raiders on **staggered entry rows**. Flow steps refuse solid cells. Lane waypoints remain the fallback when flow is inactive.

Next: async bridge (S6), richer EnTT systems. Android arm64 GDExtension is `scripts/build_android_gdextension.sh` (S8). Signed store pipelines and the iOS dylib are still open.
