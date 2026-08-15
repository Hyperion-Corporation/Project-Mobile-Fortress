# Dev & Debug Tools Roadmap

**Owner:** TBD
**Status:** 📋 **Final — 2026-08-14** (owner + Claude lock-in pass, after Grok/Gemini/Chat draft
review). Ready to be picked up as real tasks.

Scope: internal-only tooling for the owner and collaborators — a "god mode" cheat layer plus
diagnostics/scenario tooling to make VS10-style playtest sessions (and every session after it)
faster to run and easier to reason about. This is explicitly **not player-facing**; see
[Gating](#gating-locked) below.

**Relationship to other roadmaps:**
- Visual polish (art/asset depth, UI/HUD visual design) stays in [`ui_ux.md`](ui_ux.md) as U9/U10 —
  this file is dev-facing tooling only, kept separate on purpose.
- [`VS10_PLAYTEST_PROTOCOL.md`](../VS10_PLAYTEST_PROTOCOL.md)'s performance-recording table and
  session logs are direct consumers of DT5/DT7.
- [`internal_dashboard.md`](internal_dashboard.md)'s `PlaytestNotesView` is DT7's live-sync target
  (see DT7 below) — no longer a static seed once DT7 ships.

## Implementation order (locked)

Agreed unanimously by Grok/Gemini/Chat during draft review; supersedes the god-mode/diagnostics
table's row order:

1. **DT8** — nothing else is reachable without the dev-menu unlock.
2. **DT5 + DT4** — highest VS10 value: see the FPS/40-unit budget live, step a bad tick.
3. **DT1 + DT2** — speeds up sessions (skip build phase, force-lose to test G8 without playing a
   full loss).
4. **DT3** — without RNG-seed control (see DT3 notes).
5. **DT7** — after DT8's menu exists, so "mark event" has a UI home.
6. **DT6 last** — blocked on G5 growing a second level JSON; do not build a picker over one file.

## God mode

| # | Item | Effort | Status | Notes |
| --- | --- | --- | --- | --- |
| DT1 | Economy cheats: infinite/set resources on demand, instant outpost income, skip build-phase timer | S | 🚧 **Slice-0 wired (T28+T30)** — overlay FrontSelect land/sea/both for Fill / ∞ 兩 | Per-front toggle (land/sea/both). Implement as explicit `SimWorld` debug methods, not by poking fields from GDScript. |
| DT2 | Combat cheats: HQ/unit invincibility, one-shot kill raiders, force win/force lose a run instantly, disable wave spawning | S | 🚧 **Slice-0 wired (T28)** — invuln + kill-all + no-waves; force end via `_finish`/`end_run` | Force win/lose **must** route through `GameSession.end_run` so G8/VS8 persistence is what gets tested, not a fake overlay. "Unit invincibility" specifically can't be demonstrated yet — defenders have no damage/HP model in Slice-0; HQ/outpost invincibility is what's actually testable today. |
| DT3 | Spawn/scenario control: manually spawn any raider/unit type at a chosen cell, jump to a specific wave number, reload the current level | M | 🚧 **Slice-0 wired (T32)** — jump-wave + cell spawn + reload current JSON | **No RNG-seed control in v1** — `SimWorld` has no RNG today (BFS flow is deterministic); revisit once Q4/S7 grow a real seed. Jump-to-wave + cell spawn reuse existing `spawn_raider` / `spawn_defender`. |
| DT4 | Time control: pause/step simulation frame-by-frame, adjustable game speed (0.5x–10x) | S | 🚧 **Slice-0 wired (T26)** — pause/step/speed on `GameSession` clock | Frame-step is the highest-value piece — reuse T11's existing pause clock (`GameSession.set_paused`); do not add a second simulation clock. |

## Diagnostics & scenario tooling

| # | Item | Effort | Status | Notes |
| --- | --- | --- | --- | --- |
| DT5 | On-screen diagnostics overlay: FPS, raider/unit counts, sim tick time, memory — toggleable HUD layer | S | 🚧 **Slice-0 wired (T26)** — lives on the DT8 overlay | Feeds VS-A8's 30+ FPS / 10–40 unit acceptance check directly. FPS = `Engine.get_frames_per_second()`; tick = last `sim.tick` µs; memory = `Performance.MEMORY_STATIC` when the monitor exists. |
| DT6 | Level/scenario picker: jump straight to any level or wave setup from a dev menu instead of always starting `slice0_dual_front` | S | ⏸ Blocked | Blocked on G5 having ≥2 level JSONs. Until then, "reload current JSON + jump wave" lives under DT3 — no picker UI over a single file. |
| DT7 | Playtest session logging: structured event/action log matching `VS10_PLAYTEST_PROTOCOL.md`'s session template, plus a one-press **"Sync to Dashboard"** pipeline action (owner decision — see [DT7 data path](#dt7-data-path-locked)) | M | 🚧 **Slice-0 wired (T34)** — `user://playtest_sessions.json` + overlay Mark/Sync + `scripts/sync_playtest_session.sh` | One-tap `[📝 Mark Session Event]` button timestamps notable moments during a session; separate "Sync to Dashboard" button runs the pipeline. |
| DT8 | Dev-menu access/unlock mechanism | S | 🚧 **Slice-0 wired (T25)** — `~`/F12, 5-tap version label, Settings Developer Mode (not telemetry) | Foundational — DT1–DT7 hang off this. See [Gating](#gating-locked). |

## Gating (locked)

**Runtime unlock, not a compile-time flag** — Slice-0 has no release export pipeline yet, and the
owner/collaborators need this on the same build they're already running:

- **Desktop:** `~` (tilde) or `F12` opens the developer console/overlay.
- **Mobile/touch:** 5-tap sequence on the main-menu version label, or a **"Developer Mode"** toggle
  in Settings (U3) — a *separate* preference from the existing Tier 0/1/2 telemetry-consent
  selector. **Consent controls data collection; developer mode controls privileged simulation
  mutations — do not conflate the two**, both to avoid a category error and to keep playtest notes
  legible.
- **Future release gate:** once a store-signed export pipeline exists, add a second gate that
  compiles out or hard-disables DT1–DT4 (the cheats) from release/store builds — a hidden gesture
  alone is not a release-safety boundary. DT5's overlay may stay available in debug builds. Not
  needed yet; noted here so it isn't forgotten when export packaging (S8/IOS5) starts.

## DT7 data path (locked)

**Owner decision (overrides both the agents' "manual export/import" draft recommendation and a
fully-automatic live sync):** DT7 stays **event-triggered, not continuous** — session events are
always recorded locally, and a dev presses a **"Sync to Dashboard"** action that runs a
**pre-programmed pipeline**, never a hand-edited file copy:

- **Recording (all builds):** every session always writes to `user://playtest_sessions.json` via
  the DT7 logger — this is the single source of truth on-device, mobile included.
- **Desktop/editor builds** (same checkout as `docs/website/`): the dev-menu's "Sync to Dashboard"
  button runs a small pipeline step (a script or an in-engine file op — implementation's choice,
  not a hand-edit) that reads `user://playtest_sessions.json` and writes it into
  `docs/website/public/dashboard-data/playtest_sessions.json` in the shape `PlaytestNotesView`
  already expects. One press, no manual JSON surgery.
- **Mobile/collaborator builds** (sandboxed storage, no filesystem access to the website checkout):
  the same "Sync to Dashboard" action exports `user://playtest_sessions.json` via the platform share
  sheet / save-to-downloads. The owner then runs the **same pipeline script** (e.g.
  `scripts/sync_playtest_session.sh <exported-file>`) locally to merge it into
  `docs/website/public/dashboard-data/playtest_sessions.json` — one command, not hand-editing JSON.
  This half stays two steps (export on the phone, run the script on the owner's machine) because
  there is no backend (`backend.md` B7 is deferred) to receive a direct upload from a sandboxed
  mobile app.
- If/when `backend.md` B7 (leaderboards/analytics REST API) lands, DT7 should be revisited to post
  mobile sessions there directly instead of the share-sheet + script handoff — flagged as a forward
  pointer, not committed scope now.

Effort key: S = days, M = 1–2 weeks, L = 3–6 weeks, XL = multi-month/cross-cutting.
