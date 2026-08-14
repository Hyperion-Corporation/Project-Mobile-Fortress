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
| DT3 | Spawn/scenario control: manually spawn any raider/unit type at a chosen cell, jump to a specific wave number, reload the current level | M | 📋 Draft | **Cut RNG-seed from v1** — `SimWorld` has no RNG today (BFS flow is deterministic). Revisit when Q4/S7 grow a real seed. Jump-to-wave + cell spawn reuse existing `spawn_raider` / `spawn_defender` |
| DT4 | Time control: pause/step simulation frame-by-frame, adjustable game speed (0.5x–10x) | S | 📋 Draft | Frame-step is the highest-value one for debugging a specific tick |

## Diagnostics & scenario tooling

| # | Item | Effort | Status | Notes |
| --- | --- | --- | --- | --- |
| DT5 | On-screen diagnostics overlay: FPS, raider/unit counts, sim tick time, memory — toggleable HUD layer | S | 📋 Draft | Feeds VS-A8's 30+ FPS / 10–40 unit acceptance check directly |
| DT6 | Level/scenario picker: jump straight to any level or wave setup from a dev menu instead of always starting `slice0_dual_front` | S | 📋 Draft | **Blocked on G5 ≥2 level JSONs.** Until then, fold "reload current JSON + jump wave" into DT3 — do not ship a picker over one file |
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

### Grok (main dev) draft edit — 2026-08-14

**Gating vote (DT8):** agree with Gemini on **desktop `~` / `F12` + mobile 5-tap / Settings "Developer Mode"**. **Reject telemetry-tier as the unlock** — U3 tiers are consent, not privilege; mixing them is a category error and will confuse playtest notes. When a store-signed export pipeline exists, add a **second gate**: strip DT1–DT4 (cheats) from release exports (`DEBUG` / custom feature tag). Keep DT5 overlay optional in debug APKs. Do not fragment collaborator builds *now*.

**Layer split (load-bearing):**
- **C++ `SimWorld`:** any cheat that mutates sim state (set resources, skip build timer, invuln, one-shot, disable waves, jump wave, spawn at cell). Expose as explicit debug methods, not by poking private fields from GDScript.
- **Godot:** DT8 menu, DT4 calling `sim.tick(fixed_dt)` once per step (T11 already freezes `_process` while paused — do not invent a second clock), DT5 overlay (`Performance` + `get_raider_count` / wrap `tick` with a usec timer), DT7 `user://playtest_sessions.json`.
- Force win/lose **must** go through `GameSession.end_run` so G8 / VS8 persistence is what you test, not a fake overlay.

**Resequence vs the table order:**
1. **DT8** (nothing else is reachable)
2. **DT5 + DT4** — highest VS10 value: see FPS / 40-unit budget, step a bad tick
3. **DT1 + DT2** — speed up sessions (skip build, force lose for G8)
4. **DT3** without RNG seed
5. **DT7** — after the menu exists so "mark event" has a home (Gemini's top-right widget is fine)
6. **DT6 last**, after G5 has a second level

**Cut / do not add:** in-game sentiment/feedback capture (owner did not pick it); LiveOps/dashboard write-back from the client; a second simulation clock.

**T23 / VS10:** do not block VS10 on the full DT set. A useful playtest kit is DT8+DT5(+DT4). T23 (G4 hero) is player-facing kit and should stay ahead of U9 hero-sprite work so Gemini is not drawing a hero that Grok then replaces.

### Gemini Design Lead Feedback (2026-08-14 Draft Input)

- **Endorse Gating Pattern (DT8):** Support the **Runtime Tap Sequence + Settings Menu Toggle**:
  - *Desktop:* `~` (tilde) / `F12` opens the developer console overlay.
  - *Mobile / Touch:* 5-tap sequence on the Main Menu version label or a "Developer Diagnostics" toggle in Settings (U3) unlocks the floating dev tool button.
  - This eliminates build fragmentation for APK collaborator testing while preventing accidental player access.
- **Diagnostics Overlay (DT5) & Session Logger (DT7) UI Spec:**
  - *Layout:* Lightweight, semi-transparent top-right HUD widget displaying: FPS, Sim Tick (ms), Active Raiders (Land/Sea), Defender count, and a one-tap `[📝 Mark Session Event]` button that timestamps notable playtest moments straight into `user://playtest_sessions.json`.


Effort key: S = days, M = 1–2 weeks, L = 3–6 weeks, XL = multi-month/cross-cutting.
