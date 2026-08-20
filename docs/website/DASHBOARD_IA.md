# Dashboard Information Architecture & Wireframes (ID2)

**Status:** 🚧 In Progress (Gemini, 2026-08-14)  
**Depends on:** ID1 ✅ ([`DashboardRequirementsView.tsx`](src/frameworks/react/views/DashboardRequirementsView.tsx))  
**Produces for:** ID3 (skeleton view implementation)  
**Roadmap source:** [`docs/moon/roadmaps/internal_dashboard.md`](../moon/roadmaps/internal_dashboard.md) §ID2  

---

## 1 — Design Principles

The dashboard follows the same design rules as the rest of `docs/website/`:

1. **Static-first.** All P0/P1 metrics read from committed JSON batch files — no live API calls until `backend.md B7` ships.
2. **React host, native component.** The dashboard is a new `views/DashboardView.tsx` mounted as a standard React route — **not** a foreign-root island. It does not need Aurelia/Astro mounting because it's a plain React feature, per the [Authoring guide](APP.md).
3. **Same design tokens.** Reuse `.panel`, `.panel-dark`, `.glass`, CSS custom properties (`--accent-gold`, `--text-muted`, etc.) and button classes (`btn btn-primary`, `btn btn-sm`) from `src/styles/`.
4. **Sidebar on `/dashboard/*` routes.** The dashboard is a documentation-adjacent surface — it should show the sidebar (like doc routes), not hide it (like the home hero).
5. **Progressive disclosure.** Lead with the P0 gate-status summary; P1 detail is one click deeper; P2 items are clearly deferred.

---

## 2 — Route & Navigation Structure

```
/                           → HomeView (hero, existing)
/docs                       → DocPage (existing)
/dashboard/requirements     → DashboardRequirementsView (ID1 ✅)
/dashboard                  → DashboardView (ID3 — this IA)
  /dashboard/runs           → RunHistoryView (ID3 sub-view)
  /dashboard/ci             → CiStatusView (ID3 sub-view)
  /dashboard/playtest       → PlaytestNotesView (ID3 sub-view)
```

**Topbar:** "Dashboard" link already added in `App.tsx` (T14). It links to `/dashboard/requirements` today; redirect to `/dashboard` once ID3 lands.

**Sidebar additions** (add to `nav.generated.ts` or a static sidebar entry when ID3 ships):

```
Dashboard
  ├── Requirements     /dashboard/requirements
  ├── Overview         /dashboard
  ├── Run History      /dashboard/runs
  ├── CI Status        /dashboard/ci
  └── Playtest Notes   /dashboard/playtest
```

---

## 3 — Page-level Wireframes

### 3.1 — `/dashboard` — Overview (the P0 gate status at a glance)

```
┌──────────────────────────────────────────────────────────────────┐
│ TOPBAR  🏯 Mobile Fortress  [Docs] [Dashboard▲] [🔍] [🌙] [GH]  │
├────────────┬─────────────────────────────────────────────────────┤
│            │  📊 Dashboard                                        │
│  SIDEBAR   │  ─────────────────────────────────────────────────  │
│            │                                                      │
│  Dashboard │  ┌─────────────────────────────────────────────┐    │
│  ▶ Overvw  │  │  GATE STATUS                         [?]    │    │
│    Runs    │  │  VS10 Playtest  ○ 0 / 2 sessions done       │    │
│    CI      │  │  Phase 1a       ○ Awaiting gate decision     │    │
│    Notes   │  └─────────────────────────────────────────────┘    │
│            │                                                      │
│            │  ┌──────────────┐ ┌──────────────┐ ┌────────────┐  │
│            │  │  CI Status   │ │  Last Run    │ │ Sessions   │  │
│            │  │  ✅ PASS     │ │  Victory     │ │  0 logged  │  │
│            │  │  godot-core  │ │  5 waves     │ │            │  │
│            │  │  ci workflow │ │  62 HQ HP    │ │  [+ Add]   │  │
│            │  └──────────────┘ └──────────────┘ └────────────┘  │
│            │                                                      │
│            │  Run History (last 5)                               │
│            │  ┌──────────────────────────────────────────────┐   │
│            │  │  run_id          victory  waves  dur   HQ HP  │   │
│            │  │  2026-08-12…     ✅       5      523s  45     │   │
│            │  │  2026-08-11…     ❌       3      312s  0      │   │
│            │  │  2026-08-11…     ✅       5      487s  62     │   │
│            │  │                          [View all runs →]    │   │
│            │  └──────────────────────────────────────────────┘   │
│            │                                                      │
│            │  [→ View Requirements]  [→ Playtest Protocol]        │
└────────────┴─────────────────────────────────────────────────────┘
```

**Key behaviours:**
- Gate status card reads from a static `public/dashboard-data/playtest_sessions.json`
- CI status card reads from a static `public/dashboard-data/ci_status.json` (written by a CI step or manually)
- Last Run pulls from `public/dashboard-data/run_history.json` (devs export after playing)
- All three cards show a muted "No data yet — see setup guide" state when the JSON files are absent

---

### 3.2 — `/dashboard/runs` — Run History

```
┌──────────────────────────────────────────────────────────────────┐
│ TOPBAR                                                           │
├────────────┬─────────────────────────────────────────────────────┤
│  SIDEBAR   │  📈 Run History                                      │
│            │  ─────────────────────────────────────────────────  │
│  Dashboard │                                                      │
│    Overvw  │  Summary bar: [3 runs] [2 victories 67%]            │
│  ▶ Runs    │              [Avg dur: 441s] [Avg HQ: 36 HP]        │
│    CI      │                                                      │
│    Notes   │  ┌─── Wave survival histogram (sparkline) ───────┐  │
│            │  │    W1 W2 W3 W4 W5                             │  │
│            │  │    ██ ██ ██ ▒▒ ██  (bars = sessions reaching) │  │
│            │  └────────────────────────────────────────────────┘  │
│            │                                                      │
│            │  ┌─── Session duration distribution ─────────────┐  │
│            │  │  < 5m  5-8m  8-10m  10m+                      │  │
│            │  │  ░░░░  ████  ████   ░░░░                      │  │
│            │  └────────────────────────────────────────────────┘  │
│            │                                                      │
│            │  Full run table (sortable)                           │
│            │  run_id | victory | reason | waves | dur | HQ | civ  │
│            │  ───────────────────────────────────────────────     │
│            │  ...rows...                                          │
│            │                                                      │
│            │  [📋 Export batch JSON guide]                        │
└────────────┴─────────────────────────────────────────────────────┘
```

**Key behaviours:**
- All derived metrics (wave survival %, avg duration, HQ HP histogram) computed client-side from `run_history.json`
- Sparkline bars are simple `<div>` elements sized by percentage — no charting library needed for P0/P1 scale
- Export guide links to `game/README.md` export section

---

### 3.3 — `/dashboard/ci` — CI Status

```
┌──────────────────────────────────────────────────────────────────┐
│ TOPBAR                                                           │
├────────────┬─────────────────────────────────────────────────────┤
│  SIDEBAR   │  🔬 CI Status                                        │
│            │  ─────────────────────────────────────────────────  │
│  Dashboard │                                                      │
│    Overvw  │  ┌── godot-core workflow ──────────────────────────┐ │
│    Runs    │  │  ✅ PASS  •  Last run: 2026-08-14               │ │
│  ▶ CI      │  │  sim_world_tests    PASS                        │ │
│    Notes   │  │  simulation_smoke   PASS                        │ │
│            │  │  modular_battle     PASS                        │ │
│            │  │  gameplay_smoke     PASS                        │ │
│            │  │  game_session       PASS                        │ │
│            │  └─────────────────────────────────────────────────┘ │
│            │                                                      │
│            │  ┌── android CI ───────────────────────────────────┐ │
│            │  │  ✅ PASS  •  Last run: ...                      │ │
│            │  └─────────────────────────────────────────────────┘ │
│            │                                                      │
│            │  ┌── website vitest ───────────────────────────────┐ │
│            │  │  ✅ 10 / 10  •  Last run: ...                   │ │
│            │  └─────────────────────────────────────────────────┘ │
│            │                                                      │
│            │  Data source: public/dashboard-data/ci_status.json  │
│            │  [📋 How to update CI data]                          │
└────────────┴─────────────────────────────────────────────────────┘
```

---

### 3.4 — `/dashboard/playtest` — Playtest Notes

```
┌──────────────────────────────────────────────────────────────────┐
│ TOPBAR                                                           │
├────────────┬─────────────────────────────────────────────────────┤
│  SIDEBAR   │  📝 Playtest Notes                                   │
│            │  ─────────────────────────────────────────────────  │
│  Dashboard │                                                      │
│    Overvw  │  VS10 gate: 0 / 2 sessions recorded                 │
│    Runs    │                                                      │
│  ▶ Notes   │  [→ Open VS10_PLAYTEST_PROTOCOL.md]                 │
│    CI      │                                                      │
│            │  ┌─── Session 1 ────────────────────────────────┐   │
│            │  │  (empty — no data in playtest_sessions.json) │   │
│            │  └──────────────────────────────────────────────┘   │
│            │                                                      │
│            │  ┌─── Session 2 ────────────────────────────────┐   │
│            │  │  (empty)                                     │   │
│            │  └──────────────────────────────────────────────┘   │
│            │                                                      │
│            │  How to record a session:                           │
│            │  1. Fill in VS10_PLAYTEST_PROTOCOL.md              │
│            │  2. Export session JSON to                          │
│            │     public/dashboard-data/playtest_sessions.json   │
│            │  3. Commit + push                                   │
└────────────┴─────────────────────────────────────────────────────┘
```

---

## 4 — Static Data Files Schema

These files live under `docs/website/public/dashboard-data/` and are committed directly. No live endpoint needed.

### `run_history.json`

```jsonc
// Array of RunRecord (schema from DashboardRequirementsView.tsx)
[
  {
    "run_id": "2026-08-11T14:22:00Z",
    "victory": true,
    "reason": "all_waves_cleared",
    "duration_s": 487,
    "primary_civ": "Ming",
    "support_civ": "Portuguese",
    "wave_reached": 5,
    "hq_hp_remaining": 62,
    "smoke_ci_status": "pass"
  }
  // ... more records
]
```

### `ci_status.json`

```jsonc
{
  "updated": "2026-08-14T20:00:00Z",
  "workflows": [
    {
      "name": "godot-core",
      "status": "pass",          // "pass" | "fail" | "unknown"
      "last_run": "2026-08-14",
      "tests": [
        { "name": "sim_world_tests",   "result": "pass" },
        { "name": "simulation_smoke",  "result": "pass" },
        { "name": "modular_battle",    "result": "pass" },
        { "name": "gameplay_smoke",    "result": "pass" },
        { "name": "game_session",      "result": "pass" }
      ]
    },
    {
      "name": "android-ci",
      "status": "pass",
      "last_run": "2026-08-14",
      "tests": []
    },
    {
      "name": "website-vitest",
      "status": "pass",
      "last_run": "2026-08-14",
      "tests": [{ "name": "10 tests", "result": "pass" }]
    }
  ]
}
```

### `playtest_sessions.json`

```jsonc
{
  "gate": "VS10",
  "sessions_required": 2,
  "sessions": [
    // Filled in after each playtest session from VS10_PLAYTEST_PROTOCOL.md
    // {
    //   "date": "YYYY-MM-DD",
    //   "tester": "...",
    //   "platform": "...",
    //   "build_commit": "...",
    //   "hard_criteria_pass": true,
    //   "art_criteria_pass": true,
    //   "verdict": "shows_promise",   // "shows_promise" | "needs_work" | "no"
    //   "notes": "..."
    // }
  ],
  "gate_decision": null   // "pass" | "needs_work" | null
}
```

---

## 5 — Implementation Guidance for ID3

When building ID3, follow these rules from the [Authoring guide](APP.md):

1. **Pattern:** Native React component (not a foreign-root island). New views under `src/frameworks/react/views/Dashboard*.tsx`.
2. **Data:** `fetch('/dashboard-data/*.json')` in a `useEffect` — graceful empty-state when file absent (dev environment without exported data).
3. **No charting library for P0:** Simple CSS bar charts (`<div style={{ width: `${pct}%` }} />`) are sufficient for wave histograms and duration distributions at this data volume (≤20 runs). Add a charting library (ID7 research scope) only when the data volume justifies it.
4. **Sidebar visible:** Dashboard routes are not `isHome`, so the existing sidebar renders automatically.
5. **Budget:** No new foreign-root island → no new `check-island-budgets.mjs` entry needed.
6. **Tests:** Add one Vitest smoke test per view (mount + verify key heading exists), following the pattern in `test/unit/components/smoke.test.ts`.

---

## Document history

| Date | Change |
| --- | --- |
| 2026-08-14 | Initial IA + wireframes (Gemini, T15 follow-on, ID2) |
