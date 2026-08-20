#!/usr/bin/env bash
# Comment S8 / VS9 / iOS mobile export packaging progress.
set -euo pipefail
cd "$(dirname "$0")/.."

gh issue comment 129 --body "## S8 progress 2026-08-11 — export packaging + Android APK

- \`game/export_presets.cfg\`: **Android Debug** (Gradle, minSdk 33, target 35, package \`com.acfharbinger.mobilefortress\`) + **iOS** (min 17.0)
- Docs: \`game/EXPORT_MOBILE.md\`
- Smoke: \`bash scripts/export_mobile_smoke.sh\` (config); \`--export-android --require-templates\`
- Templates: \`bash scripts/install_godot_export_templates.sh\` (~1.2GB) → \`~/.local/share/godot/export_templates/4.7.1.stable/\`
- **Verified:** Android debug APK export on Linux (~159MB under \`game/exports/android/\`, gitignored)
- GDExtension paths declared for android.arm64 / ios.arm64 (binaries optional; classic GDScript fallback packages without them)
- Note: \`.gdextension\` must use \`;\` comments (not \`#\`) or Godot fails to resolve libraries

Still open: NDK cross-build of SimulationCore for device, on-device install smoke, signed Play/App Store pipelines, macOS iOS CI."

# S8 has no dedicated issue number historically — comment on epic and IOS1 if present
if gh issue list --search "in:title S8" --json number --jq '.[0].number' | grep -q .; then
  N=$(gh issue list --search "in:title S8" --json number --jq '.[0].number')
  gh issue comment "$N" --body "See epic #129 S8 progress comment (export_presets + smoke script)."
fi

gh issue comment 63 --body "IOS3/export: iOS preset min 17.0 in \`game/export_presets.cfg\`. GDExtension path \`ios.arm64\` declared. Actual dylib + Xcode export still needs macOS collaborator."

echo "Done."
