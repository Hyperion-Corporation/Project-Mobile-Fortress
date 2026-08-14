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
| U9 | Art/asset polish: deeper tile-atlas variety, unit/hero sprite silhouette distinctness, HQ/outpost visual damage/upgrade tiers, ukiyo-e background detail pass | M | 📝 **DRAFT — 2026-08-14** — open for edit before final review |
| U10 | UI/HUD visual design pass: cohesive icon set, typography system, menu/dialog transition animation, consistent chrome across **Godot** menu/HUD/settings/results (not the React dashboard) | M | 📝 **DRAFT — 2026-08-14** — open for edit before final review |

Effort key: S = days, M = 1–2 weeks, L = 3–6 weeks, XL = multi-month/cross-cutting.

**2026-08-14 note:** U9/U10 are a draft from an owner + Claude brainstorm on visual polish + dev
tooling. See [`dev_tools.md`](dev_tools.md) for the companion god-mode/debug-tooling draft (kept
separate — dev-facing, not player-facing). Both are open for Grok/Gemini/Chat to edit before a
final owner + Claude review pass locks them in.

### Gemini Design & Art Lead Notes (2026-08-14 Draft Input)

- **U9 (Art / Asset Polish breakdown):**
  - **Tile Atlas Variety:** 2.5D isometric tiles for land coast, tidal marsh, elevation bastions, and ocean shoals with ukiyo-e wave foam.
  - **Silhouette Distinctness:** High-contrast silhouettes for unit readability during swarm combat — Qi Jiguang (crimson plume + command banner), Ming Spearmen (bamboo pike), Portuguese Arquebusiers (morion helm + matchlock posture), Wōkòu Rōnin (straw kasa hat + nodachi), Raider Junks (matting sails + ram prow).
  - **Building Damage & Upgrade Tiers:** Visual states for HQ and Outposts (Full HP, Damaged with smoke/cracked stonework, Ruined/Pillaged with scorched timber, and Upgraded with swivel gun emplacements).
- **U10 (UI / HUD Visual Design breakdown):**
  - **Iconography System:** Dedicated vector glyphs for Land Currency (兩), Naval Currency (海關兩), Outpost status badges, Wave threat skulls, and Unit ability cooldown rings.
  - **Typography & Transitions:** Harmonized serif titles (Ming/Age-of-Sail historical aesthetic) and clean high-legibility sans-serif metrics. Smooth modal slide/fade transitions for pause overlay, settings dialog, and combat victory/defeat screens.

### Grok (main dev) draft edit — 2026-08-14

- **U9 split the M, don't ship all four terrains in one pass.** VS7 is still a single palette + iso tile mockup. Suggested order: **(1) silhouette pass on the current roster** (spearman, cannon, arquebusier, junk, Qi, cross-support, land/sea raider) — this is VS-A3 / playtest readability; **(2) HQ/outpost visual tiers mapped to states that already exist** (G7 HP ratio + `upgrade_defender`, plus lost/economic-only — do not invent new sim flags); **(3) tile-atlas variety** (coast / marsh / shoal) after (1)–(2).
- **Hold U9 hero art for T23.** If T23 adds a second commander, drawing Qi-only then redrawing is waste. U9 v1 = current `UnitDefs` only until T23 lands or is explicitly "Qi-only."
- **U10: cut dashboard from the Godot ticket.** React dashboard chrome is Gemini/`internal_dashboard.md`. U10 should be **menu + pause + HUD + settings + results** only. Shared tokens (paper/indigo/cinnabar) can be documented once and copied; do not couple Godot theme resources to the website build.
- **Out of scope ACK:** juice/particles and day-night lighting stay out unless the owner adds them back.
- **U10 effort:** "icon set + type system + transitions + all chrome" is closer to L than M if it includes unique art for every control. Prefer M = token sheet + HUD icon set + one transition language; unique illustrated panels wait on U9.
