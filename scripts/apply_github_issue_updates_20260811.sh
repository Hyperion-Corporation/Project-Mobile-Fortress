#!/usr/bin/env bash
# Apply GitHub issue updates for Slice-0 / Godot+C++ progress (2026-08-11).
# Run from repo root:
#   bash scripts/apply_github_issue_updates_20260811.sh
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== Titles =="
gh issue edit 9  --title "[G2] Dual-front land+sea core loop — Slice-0 PLAYABLE (polish remains)" || true
gh issue reopen 9 2>/dev/null || true
gh issue edit 68 --title "[S1] Stand up C++ workspace with EnTT (DONE — CMake + SimulationCore)"
gh issue edit 70 --title "[S3] Wire Godot↔C++ via godot-cpp GDExtension (DONE)"
gh issue edit 72 --title "[S5] Move dual-front logic into C++ sim; Godot presentation (IN PROGRESS)"
gh issue reopen 72 2>/dev/null || true
gh issue edit 73 --title "[S6] Async bridging sim thread ↔ Godot main thread (TSan)"
gh issue edit 71 --title "[S4] FlatBuffers state snapshots (save / net / tools)"
gh issue edit 63 --title "[IOS3] Godot iOS export consumes shared C++ sim (was Swift C++ interop)"
gh issue edit 10 --title "[G3] Flow Field pathfinding (naive lane pathing done in Slice-0)"
gh issue reopen 10 2>/dev/null || true
gh issue edit 13 --title "[G6] Build vs combat phases (Slice-0 shell done; day/night polish later)"
gh issue edit 16 --title "[G10] Dual-grid placement input (Slice-0 mouse/click done)"
gh issue edit 85 --title "[G7] Resource/Trading Outpost economy (Slice-0 partial — C++ outpost HP)"
gh issue edit 11 --title "[G4] Hero-commander system (Slice-0 minimal; expand later)"
gh issue edit 12 --title "[G5] Data-driven level/wave JSON (Slice-0 partial)"
gh issue edit 21 --title "[U4] In-game HUD (Slice-0 partial — modular + classic)"
gh issue edit 128 --title "[Epic] Slice-0: Offline dual-front Godot vertical slice (IN PROGRESS)"
gh issue edit 129 --title "[Epic] Godot 4 + C++ simulation (S0/S1/S3 done; S5 in progress)"

echo "== Close completed shared-core items =="
gh issue close 68 --comment "## Status 2026-08-11 — DONE

CMake + FetchContent godot-cpp/EnTT workspace is in \`game/\`. \`SimulationCore\` GDExtension builds and loads in Godot 4.7.

- Build: \`game/BUILD_CPP.md\`, \`game/CMakeLists.txt\`
- Smoke: \`game/tests/simulation_smoke.gd\`

Roadmap: \`docs/moon/roadmaps/shared_core.md\` S1. Epic #129."

gh issue close 70 --comment "## Status 2026-08-11 — DONE

Godot presentation calls into C++:

- Classic: \`game/main.gd\` → \`SimulationCore\`
- Modular: \`game/scripts/battle/battle_root.gd\` → \`SimulationCore\`
- Extension: \`game/mobile_fortress_core.gdextension\`

Roadmap: \`docs/moon/roadmaps/shared_core.md\` S3. Epic #129."

echo "== Progress comments =="
gh issue comment 128 --body "## Progress 2026-08-11

### Done / playable
- Dual-front offline loop (classic + modular)
- Build vs combat, click placement both fronts
- Naive lane pathing + C++ raider motion
- Minimal hero (aura, E pulse, travel) + cross-front support
- Outpost economy (C++ mid-path HP; economic-only loss)
- Headless smokes: \`simulation_smoke\`, \`gameplay_smoke\`, \`modular_battle_smoke\`

### Still open under this epic
- #11 G4 expand beyond Slice-0 minimal
- #12 G5 richer JSON schema
- #13 G6 day/night UX polish
- #85 G7 deeper economy
- #16 G10 touch polish (mobile)
- #21 U4 full HUD polish
- #60 Q10 collaborator playtest (exit gate)

### Code entry
- Menu: \`game/scenes/main_menu.tscn\`
- Modular: \`game/scenes/battle/battle.tscn\`
- Classic: \`game/main.tscn\`
- Roadmap: \`docs/moon/roadmaps/vertical_slice.md\`"

gh issue comment 129 --body "## Progress 2026-08-11

| ID | Item | Status |
| --- | --- | --- |
| S0 | GDExtension spike | **DONE** |
| S1 | CMake + EnTT workspace | **DONE** (#68 close) |
| S2 | Pathfinding | Partial — lane paths; Flow Field still #69/G3 |
| S3 | Godot↔C++ wire-up | **DONE** (#70 close) |
| S4 | FlatBuffers | Open (#71) |
| S5 | Logic in C++ | **IN PROGRESS** — defenders/raiders/outposts/combat |
| S6 | Async bridge | Open (#73 retargeted Godot) |
| S7 | Regression suite | Partial — \`game/tests/*_smoke.gd\` |
| S8 | Mobile export | Open |

Build: \`game/BUILD_CPP.md\`."

gh issue comment 9 --body "## Progress 2026-08-11 — Slice-0 baseline playable

Dual-front land+sea fortress defense runs offline in Godot 4.7 with C++ \`SimulationCore\` (or GDScript fallback in classic path).

- Modular presentation: \`battle_root.gd\` + TileMaps
- Classic presentation: \`main.gd\`
- Remaining work: feel polish, Flow Field (G3), export, playtest gate (#60)

Epic: #128. Roadmap: \`gameplay.md\` G2 / \`vertical_slice.md\`."

gh issue comment 72 --body "## Progress 2026-08-11 — IN PROGRESS

In C++ today: raiders, defenders (auto combat), outpost HP/loss, dual currency, HQ, hero pulse/travel APIs.

Still Godot-side: HUD chrome, menu, tile visuals, wave table loading (JSON), unit catalog presentation.

Do not close until major dual-front combat/economy is majority-C++ with presentation-only Godot."

gh issue comment 11 --body "Slice-0 minimal hero is implemented (aura, active pulse, redeploy travel) in both classic and modular paths. Keep open for expanded hero roster/abilities post-slice."
gh issue comment 85 --body "Slice-0 partial: dual land/sea currencies, income while outposts alive, C++ mid-path outpost damage and economic-only loss. Keep open for richer economy."
gh issue comment 12 --body "Partial: \`game/assets/levels/slice0_dual_front.json\` drives waves/build timer/start resources. Full schema alignment with \`level-schema.json\` still open."
gh issue comment 13 --body "Slice-0 shell done (BUILD timer → COMBAT). Full day/night UX polish and cognitive-load design remain."
gh issue comment 16 --body "Mouse/click dual-front placement works in classic and modular views. Mobile touch polish still open."
gh issue comment 21 --body "Partial HUD in modular battle (phase, resources, outpost HP, HQ) and classic canvas HUD. Full ukiyo-e chrome still open."
gh issue comment 10 --body "Naive lane waypoint pathing ships in Slice-0 (C++ advances raiders). This issue tracks **full Flow Field** post-slice — keep open."

# Create S0 tracking issue if missing
if ! gh issue list --search "in:title S0 GDExtension" --json number --jq 'length' | grep -q '^[1-9]'; then
  gh issue create --title "[S0] Godot↔C++ GDExtension boundary spike (DONE)" \
    --label "enhancement" \
    --label "roadmap:shared-core" \
    --body "Completed 2026-08-11. \`SimulationCore\` via godot-cpp. See shared_core.md S0 and game/BUILD_CPP.md. Parent epic #129."
fi

# Create G12 if missing
if ! gh issue list --search "in:title [G12]" --json number --jq '.[].number' | grep -q .; then
  gh issue create --title "[G12] Cross-front specialized support units (Slice-0 partial)" \
    --label "enhancement" \
    --label "roadmap:gameplay" \
    --body "See gameplay.md G12. Slice-0 has Signal Battery / cross_env_mult. Expand post-slice. Parent epic #128."
fi

echo "== Done =="
gh issue list --limit 25 --search "Slice-0 OR Simulation OR Dual-front OR S1 OR S3 OR S5 OR PLAYABLE"
