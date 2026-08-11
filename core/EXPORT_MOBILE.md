# Mobile export smoke (VS9 / S8)

Targets: **Android 13+** (API 33), **iOS 17+**.  
Godot project: this `core/` folder.

## Architecture

| Platform | Presentation | Simulation on device |
| --- | --- | --- |
| Desktop Linux | Modular + classic | `libmobile_fortress_core.linux.x86_64.so` |
| Android | Godot export APK | Optional GDExtension arm64 (NDK); else classic **GDScript fallback** |
| iOS | Godot export (macOS host) | Optional dylib; else classic fallback |

Slice-0 offline play does **not** require the native lib on mobile if the player uses the classic `main.gd` path. Modular battle prefers C++ when present.

## Prerequisites

### Shared
- Godot **4.7.1** (match export templates version)
- Export templates installed under  
  `~/.local/share/godot/export_templates/4.7.1.stable/`

Install templates (one-time, ~1.2 GB):

```bash
bash scripts/install_godot_export_templates.sh
```

The Gradle-backed Android preset also needs the per-project build template,
which is generated locally with:

```bash
$GODOT --headless --path core --install-android-build-template
```

The generated `core/android/` directory is local build infrastructure and is
ignored by Git.

### Android (Linux/macOS)
- Android SDK (`ANDROID_HOME` or `~/Android/Sdk`)
- Platforms **android-33+**, build-tools
- **JDK 17–21** (set in Godot Editor Settings → Export → Android → Java SDK Path; JDK 25 may break Android tooling)
- Godot debug keystore (auto-created on first export, or `~/.local/share/godot/keystores/debug.keystore`)
- Optional NDK for arm64 GDExtension

### iOS (macOS only)
- Xcode + iOS 17 SDK
- Apple Developer team / provisioning for device installs
- Collaborator owns CI when available (see `docs/moon/roadmaps/ios.md`)

## Export presets

Committed: `export_presets.cfg`

| Preset | Output | Notes |
| --- | --- | --- |
| **Android Debug** | `exports/android/MobileFortress-debug.apk` | Gradle build; minSdk **33**, targetSdk **35**, arm64 + x86_64 |
| **iOS** | `exports/ios/MobileFortress.ipa` | min iOS **17.0**; needs macOS |

Package: `com.acfharbinger.mobilefortress`.

**Verified 2026-08-11 (Linux):** config smoke + Android debug APK export (~159 MB) with Godot 4.7.1 templates. Missing `android.arm64` GDExtension is non-fatal — classic GDScript presentation still packages.

## Smoke script

```bash
# From repo root
export GODOT=/path/to/Godot_v4.7.1-stable_linux.x86_64
export ANDROID_HOME=~/Android/Sdk   # if not already set

# Config validation only
bash scripts/export_mobile_smoke.sh

# Also attempt Android debug APK export (needs templates)
bash scripts/export_mobile_smoke.sh --export-android

# Full check including template presence
bash scripts/export_mobile_smoke.sh --export-android --require-templates
```

Exit codes:
- `0` — smoke passed (config OK; export OK if requested)
- `1` — config failure
- `2` — export attempted but failed (templates/SDK/signing)

## Manual Godot CLI export

```bash
cd core
mkdir -p exports/android
$GODOT --headless --path . --export-debug "Android Debug" exports/android/MobileFortress-debug.apk
```

## Building Android GDExtension (optional)

Requires NDK r23+:

```bash
# Example — adjust NDK path and API
export ANDROID_NDK_HOME=$ANDROID_HOME/ndk/<version>
# Cross-compile godot-cpp + mobile_fortress_core for arm64-v8a
# Output: bin/libmobile_fortress_core.android.arm64.so
```

Documented as follow-up under shared_core S8 / ios IOS3; Slice-0 export smoke validates **packaging**, not NDK matrix.

## CI notes

- Linux CI: run `export_mobile_smoke.sh` config check; optional Android export if templates cached.
- iOS: `macos-latest` runner + secrets for signing when collaborator joins.
