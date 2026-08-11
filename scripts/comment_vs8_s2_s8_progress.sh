#!/usr/bin/env bash
# Comment Slice-0 VS8 / S2 / S8 progress on epic and related issues.
set -euo pipefail
cd "$(dirname "$0")/.."

gh issue comment 129 --body "## Progress 2026-08-11 — S2 / S4 / S8 + VS8

- **S2 dual-mode pathing**: waypoints primary; optional flow field (\`init_grids\`/\`set_cell_solid\`) — commit \`1837ccb\`
- **S4 FlatBuffers**: \`save_state\`/\`load_state\` + schema (already landed)
- **VS8 offline persistence**: \`OfflinePersistence\` (results + history + snapshot + classic JSON); main-menu resume — commit \`9ab1924\`
- **S8/VS9**: Android debug APK export verified on Linux; presets minSdk 33 / iOS 17 — commit \`53814d6\`
- Changelog expanded: commit \`7da9e83\`

Still open: NDK arm64 sim, signed store pipelines, macOS iOS IPA, VS10 playtest gate."

gh issue comment 29 --body "## Progress 2026-08-11 — FlatBuffers on Godot path (Slice-0)

\`SimulationCore.save_state\`/\`load_state\` uses FlatBuffers schema \`core/src/schema/simulation_state.fbs\`. Modular battle S/L + auto-snapshot on run end. JNI/Swift boundary for this issue remains future; Godot GDExtension path is live for desktop/export packaging."

gh issue comment 63 --body "## Progress 2026-08-11 — iOS export packaging

iOS preset (min 17.0) in \`core/export_presets.cfg\`. Android debug APK export verified on Linux. iOS IPA still needs macOS/Xcode. GDExtension \`ios.arm64\` path deferred until dylib build."

# Also refresh S8 script if present
if [[ -f scripts/comment_s8_mobile_export.sh ]]; then
  bash scripts/comment_s8_mobile_export.sh || true
fi

echo "Done commenting Project-Mobile-Fortress issues."
