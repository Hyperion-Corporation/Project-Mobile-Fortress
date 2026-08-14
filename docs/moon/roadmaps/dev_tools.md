# Dev & Debug Tools Roadmap

**Owner:** TBD
**Status:** 📝 **DRAFT — 2026-08-14** — Claude + owner brainstorm. Open for Grok/Chat/Gemini to
edit before a final owner + Claude review pass locks it. Do not treat any item below as assigned
work until it leaves draft.

Scope: internal-only tooling for the owner and collaborators — a "god mode" cheat layer plus
diagnostics/scenario tooling to make VS10-style playtest sessions (and every session after it)
faster to run and easier to reason about. This is explicitly **not player-facing**; see
[`gating`](#gating-open-question) below.

**Relationship to other roadmaps:**
- Visual polish (art/asset depth, UI/HUD visual design) stays in [`ui_ux.md`](ui_ux.md) as U9/U10 —
  this file is dev-facing tooling only, kept separate on purpose.
- [`VS10_PLAYTEST_PROTOCOL.md`](../VS10_PLAYTEST_PROTOCOL.md)'s performance-recording table and
  session logs are direct consumers of DT5/DT7.
- [`internal_dashboard.md`](internal_dashboard.md)'s `PlaytestNotesView` currently reads a static
  `playtest_sessions.json` seed (ID2/ID3) — DT7 is what would make that live-authored.

## God mode

| # | Item | Effort | Status | Notes |
| --- | --- | --- | --- | --- |
| DT1 | Economy cheats: infinite/set resources on demand, instant outpost income, skip build-phase timer | S | 📋 Draft | Per-front toggle (land/sea/both) |
| DT2 | Combat cheats: HQ/unit invincibility, one-shot kill raiders, force win/force lose a run instantly, disable wave spawning | S | 📋 Draft | Force-lose matters for testing the results/persistence path (G8) without playing a full loss |
| DT3 | Spawn/scenario control: manually spawn any raider/unit type at a chosen cell, jump to a specific wave number, reload the current level with a chosen RNG seed | M | 📋 Draft | Seed control pairs with Q4/S7's fixed-seed determinism work |
| DT4 | Time control: pause/step simulation frame-by-frame, adjustable game speed (0.5x–10x) | S | 📋 Draft | Frame-step is the highest-value one for debugging a specific tick |

## Diagnostics & scenario tooling

| # | Item | Effort | Status | Notes |
| --- | --- | --- | --- | --- |
| DT5 | On-screen diagnostics overlay: FPS, raider/unit counts, sim tick time, memory — toggleable HUD layer | S | 📋 Draft | Feeds VS-A8's 30+ FPS / 10–40 unit acceptance check directly |
| DT6 | Level/scenario picker: jump straight to any level or wave setup from a dev menu instead of always starting `slice0_dual_front` | S | 📋 Draft | Needs more than one level/JSON to be genuinely useful — currently only one Slice-0 level exists (G5) |
| DT7 | Playtest session logging: structured event/action log matching `VS10_PLAYTEST_PROTOCOL.md`'s session template, auto-captured into `playtest_sessions.json` | M | 📋 Draft | Replaces the manual note-taking the protocol currently assumes; dashboard `PlaytestNotesView` (ID3) already reads this file's shape |
| DT8 | Dev-menu access/unlock mechanism | S | 📋 Draft | Foundational — DT1–DT7 hang off whatever this is. See [Gating](#gating-open-question). |

## Gating (open question)

How these tools are exposed is **not yet decided** — flagging for the final review pass rather than
guessing:

- **Compile-time flag:** dev tools only exist in dev/debug exports, stripped entirely from release
  builds. Safest, but means playtest collaborators need a special build.
- **Runtime unlock:** shipped in all builds but hidden behind a gesture/key-combo/tap-sequence (à la
  classic dev consoles). Simpler pipeline, small risk of a curious player finding it.
- **Settings-menu toggle gated by the existing telemetry consent tiers (U3):** reuse the Tier 0/1/2
  selector's pattern — a "Developer Mode" toggle that unlocks DT1–DT7 in a submenu once enabled.

Recommendation from this draft: **runtime unlock + settings-menu toggle**, since Slice-0 has no
release export pipeline yet and the owner/collaborators need this on the same build they're already
running — but this is exactly the kind of call that should get owner sign-off, not be assumed.

Effort key: S = days, M = 1–2 weeks, L = 3–6 weeks, XL = multi-month/cross-cutting.
