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
| U10 | UI/HUD visual design pass: cohesive icon set, typography system, menu/dialog transition animation, consistent chrome across menu/HUD/settings/dashboard | M | 📝 **DRAFT — 2026-08-14** — open for edit before final review |

Effort key: S = days, M = 1–2 weeks, L = 3–6 weeks, XL = multi-month/cross-cutting.

**2026-08-14 note:** U9/U10 are a draft from an owner + Claude brainstorm on visual polish + dev
tooling. See [`dev_tools.md`](dev_tools.md) for the companion god-mode/debug-tooling draft (kept
separate — dev-facing, not player-facing). Both are open for Grok/Gemini/Chat to edit before a
final owner + Claude review pass locks them in.
