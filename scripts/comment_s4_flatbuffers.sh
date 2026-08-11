#!/usr/bin/env bash
# Comment/close S4 FlatBuffers progress on GitHub.
set -euo pipefail
cd "$(dirname "$0")/.."

gh issue edit 71 --title "[S4] FlatBuffers state snapshots (DONE — save_state/load_state)"
gh issue close 71 --comment "## Status 2026-08-11 — DONE

FlatBuffers snapshot API is live on \`SimulationCore\`:

- Schema: \`core/src/schema/simulation_state.fbs\`
- \`save_state() -> PackedByteArray\`
- \`load_state(bytes) -> bool\` (verifier)
- Modular battle: **S**/**L** → \`user://mf_slice0_snapshot.bin\`
- Smoke: \`core/tests/flatbuffers_smoke.gd\` (PASS)
- CMake generates header via \`flatc\`

Epic #129. Roadmap: \`shared_core.md\` S4."

gh issue comment 129 --body "S4 FlatBuffers snapshots done (\`save_state\`/\`load_state\`, schema + smoke). Remaining: S2 Flow Field, S5 polish, S6 async, S8 export."

echo "S4 issue updated."
