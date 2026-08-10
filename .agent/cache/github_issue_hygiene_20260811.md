# GitHub issue hygiene plan — 2026-08-11 final pass

**Status:** Prepared by Grok final pass. **Not applied via `gh` in this session** (remote mutations require explicit owner run or elevated permissions).  
**Authority:** Owner Q&A R.47 + final-pass request; thin-pointer body policy (RA5).

## Title edits

| # | New title |
| --- | --- |
| 9 | `[G2] Dual-front (land+sea) fortress-defense core loop — Slice-0 NEXT` |
| 11 | `[G4] Hero-commander system (aura + active; NOT power-gacha sourced)` |
| 22 | `[U5] Cosmetic shop / skin lootbox UI (replaces power-gacha summon screen)` |
| 33 | `[M1] REJECTED: Hero-commander power gacha — replaced by cosmetics / skin lootboxes` |
| 34 | `[M2] Probability disclosure for cosmetic lootboxes (not power gacha)` |
| 46 | `[B4] Fleet provisioning (GameLift OR Nakama/PlayFab/self-host — provider open)` |
| 59 | `[Q9] Cosmetic lootbox probability audit tooling` |
| 62 | `[IOS2] SUPERSEDED: SpriteKit TD rebuild — use Godot export path` |
| 70 | `[S3] Wire Godot↔C++ via godot-cpp and/or C++ modules` |
| 72 | `[S5] Move dual-front logic into C++ sim; Godot remains presentation` |

## Comments (short)

- **#9:** G2 is next implementation focus; see `gameplay.md` + `vertical_slice.md`.
- **#33:** Power gacha rejected; cosmetics → battle pass → skin lootboxes.
- **#46:** GameLift not mandatory; no remote backend for Slice-0.
- **#70:** godot-cpp and/or C++ modules (owner C4); S0 spike.

## New issues to create

1. **Epic:** Slice-0 offline dual-front Godot vertical slice (children: #9, #10, #11, #13, #16, #85, #21, #60)
2. **Epic:** Godot 4 + C++ simulation (godot-cpp/modules) (children: #68–#74 + S0)
3. **Epic:** Monetization policy cosmetics-first / no power gacha
4. **Research A12:** Sentiment → dashboard HITL
5. **Research A13:** Sentiment-driven in-game events HITL
6. **Research A11:** Swarm / evo pathing experiments

## Apply script (owner or agent with network)

```bash
# From repo root after review
gh issue edit 9 --title "[G2] Dual-front (land+sea) fortress-defense core loop — Slice-0 NEXT"
# ... remaining edits from table ...
gh issue create --title "[Epic] Slice-0: Offline dual-front Godot vertical slice" \
  --label "enhancement,roadmap:gameplay" --body-file - <<'EOF'
See docs/moon/roadmaps/vertical_slice.md
EOF
```

Or re-run Grok with explicit permission: “apply the GitHub issue hygiene plan.”
