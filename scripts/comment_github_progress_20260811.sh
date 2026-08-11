#!/usr/bin/env bash
# Post progress comments after c6e55b3 (C++-owned waves).
set -euo pipefail
cd "$(dirname "$0")/.."

gh issue comment 128 --body "## Progress update 2026-08-11 (post-script)

Further Slice-0 progress on modular path:

- **C++ owns waves** via \`load_level_json\` + \`set_lane_path\` + \`start_combat\` (\`SimulationCore\`)
- Modular \`battle_root\` is presentation-only for combat spawn/victory
- Hero cast via \`cast_hero_ability(id)\` with cooldown
- Headless smokes: \`simulation_smoke\`, \`modular_battle_smoke\`, \`gameplay_smoke\`, \`main_menu_smoke\` — all PASS
- Commit: \`c6e55b3\`

Entry: \`core/scenes/main_menu.tscn\` → Modular Battle."

gh issue comment 129 --body "## Progress update 2026-08-11

S5 advancing — C++ now owns:
- Level JSON load (\`load_level_json\`)
- Wave schedule + spawn (\`start_combat\` / \`tick\`)
- Defenders auto-combat, hero ability, outposts, dual currency

Still open: FlatBuffers S4, Flow Field S2/G3, async S6, mobile export S8.

Smokes green. Commit: \`c6e55b3\`."

gh issue comment 72 --body "S5 progress: wave management + level JSON moved into SimulationCore (c6e55b3). Presentation remains Godot modular/classic."
gh issue comment 12 --body "G5 progress: C++ \`load_level_json\` reads \`slice0_dual_front.json\` (waves, currencies, build/victory timers). Schema expansion still open."
gh issue comment 9 --body "G2: modular path now uses C++-owned waves (c6e55b3). Still polish remaining."

echo "Comments posted."
