# UI/UX Roadmap

**Owner:** TBD

Scope: menus, HUD, and social/meta UI for Mobile Fortress on **Godot** (isometric 2.5D) plus any thin native chrome if needed.

**2026-08-11 note:** Historical aesthetics for HUD/UI; large touch targets. **No hero power-gacha summon screen** — cosmetic lootbox/shop UI instead when monetization lands.

| # | Item | Effort | Status |
| --- | --- | --- | --- |
| U1 | Main menu — Wōkòu-era coastal theme (East Asian + Age-of-Sail motifs) | S | 🚧 **Slice-0 theme** — paper/indigo/cinnabar + 倭寇 subtitle |
| U2 | Pause overlay | S | ✅ **Slice-0 done** — Esc overlay (Resume / Save / Menu); sim frozen |
| U3 | Settings (audio, controls, notifications, **telemetry consent tiers**) | S | ✅ **Slice-0 done** — SettingsDialog (Audio sliders, Controls toggles, Notifications, Telemetry Tier 0/1/2 consent); persisted via OfflinePersistence; wired to MainMenu |
| U4 | In-game HUD (HQ HP, Resource/Trading Outpost strip, dual-front resource counters, phase indicator) | M | 🚧 **Slice-0** — HQ, dual 兩, Resource/Trading OP HP, phase, wave, status |
| U5 | Cosmetic shop / skin lootbox UI (probability disclosure) — **replaces** power-gacha summon screen | M | 📋 Deferred after cosmetics |
| U6 | Clan/alliance UI: map, roster, contribution board | L | 📋 Deferred (clans at launch, not Slice-0) |
| U7 | Battle pass / seasonal LiveOps UI | M | 📋 Deferred |
| U8 | Accessibility pass (large targets, screen reader where applicable) | M | 📋 Pending |
| U9 | Art/asset polish (sequenced sub-passes, see below) | M | 🚧 **Partial — 2026-08-14** — Sub-pass 1 shipped (`unit_token.gd` procedural silhouettes for roster + hero badges + outpost HP ratio) | Sub-passes: **(1)** silhouette/readability on the current roster — spearman, cannon, arquebusier, junk, Qi, Dias, cross-support, land/sea raider (VS-A3-relevant, can precede VS10); **(2)** HQ/outpost visual tiers driven **only** by state that already exists in the sim — G7 HP ratio (full/damaged/lost) — no promised "upgraded building" tier until a building-upgrade sim flag exists (`upgrade_defender` is unit-only today); **(3)** tile-atlas variety (coast/marsh/shoal) last. Silhouette pass may land before VS10 if current art fails VS-A3; tiles and full illustrated polish are Phase-1 follow-up, not a gate. |
| U10 | UI/HUD visual design pass — **Godot-only** (menu, pause, HUD, settings, results); the React dashboard keeps its own independent chrome under `internal_dashboard.md` | M | 📋 **Final — 2026-08-14** | Scope: a shared token sheet (paper/indigo/cinnabar, documented once) + HUD icon set (兩/海關兩 currencies, outpost status badges, wave-threat markers, ability cooldown rings) + **one** transition language (modal slide/fade for pause/settings/results). Unique illustrated panels wait on U9. Contrast/touch-target checks route through U8 rather than duplicating an accessibility pass. |

Effort key: S = days, M = 1–2 weeks, L = 3–6 weeks, XL = multi-month/cross-cutting.

**Out of scope (confirmed):** juice/particle effects and day/night lighting were not picked in the
owner's 2026-08-14 visual-polish brainstorm — stay cut unless explicitly added back.

See [`dev_tools.md`](dev_tools.md) for the companion god-mode/debug-tooling roadmap (kept separate —
dev-facing, not player-facing).
