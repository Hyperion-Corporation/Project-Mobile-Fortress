# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed (2026-08-14, T32 DT3 spawn / jump-wave / reload)

- **DT3:** `SimWorld.debug_jump_wave` (0-based) starts combat and fires only that wave on the next tick — earlier waves marked fired, no RNG. `debug_spawn_raider_at` reuses `spawn_raider` and places on a cell (flow from there, or lane starting there). Overlay: type + cell spawn, click-to-spawn, 1-based Jump wave, Reload level (`BattleRoot._restart` / `load_level_json`). Defender spawn is free via `BattleRoot.debug_spawn_at_cell`. Smoke: `scenario_control_smoke.gd`.

### Changed (2026-08-14, T30 DT1 per-front cheat UI)

- Dev overlay `FrontSelect` (Land / Sea / Both) drives Fill 兩 and ∞ 兩. Native `debug_set_resources` / `debug_set_infinite_resources` were already per-front. `debug_cheats_smoke.gd` covers land-only fill and land-only infinite.

### Changed (2026-08-14, T28 DT1/DT2 god-mode cheats)

- **DT1:** `SimWorld`/`SimulationCore` `debug_set_resources`, per-front infinite spend, `debug_apply_income`. Overlay skip-build zeros the Godot build timer and calls `_start_combat`.
- **DT2:** invuln (HQ/outposts), `debug_kill_all_raiders`, `debug_set_waves_disabled`. Force win/lose uses `BattleRoot._finish` → `GameSession.end_run`. `reset_run` clears cheat flags. Smoke: `debug_cheats_smoke.gd`.

### Added (2026-08-14, T31/T33 U10 ThemeTokens & HUD Visual Design Pass Completion)

- **U10:** `theme_tokens.gd` shared design tokens (Ukiyo-e Ink/Paper/Cinnabar/Gold/Moss/Sea Indigo palette, StyleBox panel/button generators, glyph constants `兩`/`海關兩`/`🌾 糧倉`/`⛵ 港埠`/`🏰 HQ`, and `animate_fade_in`/`animate_slide_fade_in` transition helpers). Adopted across `main_menu.gd`, `settings_dialog.gd`, and `battle_hud.gd`; added live wave-threat skull markers (☠ Ⅰ/Ⅱ/Ⅲ) and `cooldown_ring.gd` procedural radial progress ring + timer on `HeroAbilityBtn`. Smoke: `theme_tokens_smoke.gd`.

### Changed (2026-08-14, T26 DT5 diagnostics + DT4 time)

- **DT5:** DT8 overlay shows FPS, last `sim.tick` ms, land/sea raider counts, defender count, and static memory when `Performance.MEMORY_STATIC` exists.
- **DT4:** `GameSession.time_scale` (0.5–10×) scales the existing battle `_process` delta. Pause is still `set_paused`. Step while paused runs one 1/30s tick. No second clock. Smoke: `dev_diag_smoke.gd`.

### Added (2026-08-14, U9 UnitToken tactical silhouettes & outpost HP state)

- **U9 (Sub-pass 1):** `UnitToken.gd` procedural vector token renderer for Godot combat view. Replaces raw ColorRect placeholders with crisp ukiyo-e cartographic silhouettes: General Qi Jiguang (golden plume star aura), Capitão Dias (naval cross/anchor), Ming Spearmen (diamond pike), Cannon Crew (swivel barrel), Portuguese Arquebusiers (matchlock chevron), War Junk (sail wedge), Cross Support (signal battery beacon), Wōkòu Raiders (nodachi slash / pirate sail), and Outposts (bastion battlements with dynamic health bar and damage modulation). Covered by `unit_token_smoke.gd`.

### Changed (2026-08-14, T25 DT8 developer unlock)

- **DT8:** Runtime unlock — persist `developer_mode` separately from U3 telemetry. `~` / F12 unlocks and toggles a stub overlay; 5-tap the main-menu version label; Settings checkbox "Enable developer tools (not telemetry)". No DT1–DT7 cheats yet. Smoke: `dev_access_smoke.gd`.

### Changed (2026-08-14, T23 G4 Capitão Dias)

- **G4:** Second commander `hero_dias` (Portuguese, sea 兩, both fronts). Active **salvo** damages every raider on the opposite front (22 dmg, 10s CD). One of each hero type. E casts every **ready** hero on the field (a cooling hero no longer aborts the rest). Sidebar + key 5. Native + `simulation_smoke.gd` + `hero_e_smoke.gd`.

### Changed (2026-08-14, Grok draft pass on DT/U9/U10)

- `dev_tools.md`: DT3 drops RNG-seed until `SimWorld` has RNG; DT6 blocked on G5 ≥2 levels; recommended order DT8 → DT5/DT4 → DT1/DT2 → DT3 → DT7 → DT6; reject telemetry-tier as unlock; cheats live on `SimWorld`, overlay/menu on Godot.
- `ui_ux.md`: U9 sequenced silhouette → building tiers (existing HP/upgrade) → tiles; U9 hero art waits on T23; U10 drops website dashboard from the Godot ticket.

### Added (2026-08-14, ID7 Unit & Outpost Visualizer)

- **ID7 Unit & Outpost Visualizer:** `UnitVisualizerView.tsx` interactive tactical 2.5D/3D model inspector (`/dashboard/visualizer`) supporting 360° rotation, action states (Idle, Attack, March), 3 shader palette filters (Paper/Ink, Coastal Day, Dusk Wōkòu), range projection rings, unit combat spec sheets (HP, DPS, range, deployment cost, abilities), and quick navigation strip.

### Changed (2026-08-14, T20 U3 preload fix + T21 G7 income)

- **T20 / U3:** `main_menu.gd` and `settings_smoke.gd` `preload` `settings_dialog.gd` so headless `--script` does not depend on the global class cache. Dialog spacing uses `add_theme_constant_override`. Settings + main-menu smokes PASS.
- **T21 / G7:** Combat income is `outpost_income(hp, max, alive)` — 2 at full HP, 1 while damaged-but-standing, 0 after loss. Income events expose `land_income` / `sea_income`.

### Added (2026-08-14, ID6 Zoomable coastal lore & outpost map)

- **ID6 Lore map:** `LoreMapView.tsx` zoomable coastal defense map (`/dashboard/lore-map`) with 3 zoom scales (Regional coast, District garrison, Outpost focus), interactive Flow Field vectors, raid corridors, outpost inspector (Citadel, Northern Grain Outpost, Inland Silk Depot, Trading Cove, Strait Trading Post), faction filtering, and quick navigation integration.

### Added (2026-08-14, U3 Settings & telemetry consent dialog)

- **U3 Settings dialog:** `SettingsDialog.gd` modal component (Master/BGM/SFX sliders with percentage feedback, fast tap placement and screen shake toggles, tactical raid alerts, and 3-tier telemetry consent selection). Persisted via `OfflinePersistence.read_settings()` / `write_settings()` to `user://settings.json`. Integrated into `main_menu.gd` via `SettingsBtn` and verified with `main_menu_smoke.gd` and `settings_smoke.gd`.

### Added (2026-08-14, T19 ID3 dashboard skeleton)

- **ID3 internal dashboard:** React dashboard views (`DashboardView.tsx` overview, `RunHistoryView.tsx` run history & survival metrics, `CiStatusView.tsx` CI workflow/test status, `PlaytestNotesView.tsx` VS10 playtest session log), shared `useDashboardData` hook reading `public/dashboard-data/*.json`, routes wired in `router.tsx`, navigation topbar updated, and 15 vitest unit tests in `dashboard.test.ts`.

### Changed (2026-08-14, T18 G3 flow depth)

- **G3:** Flow-wave raiders spawn on staggered entry rows instead of a single mid-row. `pick_flow_step` will not walk into a solid cell (outposts/defenders force a detour). Heroes no longer mark their cell solid (`kind == HERO`). Native tests + `simulation_smoke.gd` stagger check.

### Changed (2026-08-14, T17 G8 progression wiring)

- **G8:** `GameSession.end_run` calls `Progression.record_run()` after extras merge and writes `stars`, `prestige_earned`, `total_prestige`, `best_stars` into `last_run_results.json` / history. Second `end_run` on the same run does not rescore. Result HUD and last-run summary show stars/prestige. Smoke: `progression_smoke.gd`.

### Changed (2026-08-14, T12 wave-on-flow + T13 native tests)

- **T12 / S2 / G3:** `spawn_wave_raiders` prefers an empty path when `flow_active()` so modular `start_combat()` (which still registers lane waypoints) drives raiders via BFS flow. Lane/default paths remain the fallback when grids were never initialized. `get_raiders()` exposes `path_len` / `uses_flow`.
- **T13 / Q3 / S7 / Q2:** Godot-free `mf::SimWorld` owns the sim; `SimulationCore` is the GDExtension wrapper. doctest target `sim_world_tests` + `ctest`. New workflow `.github/workflows/godot-core.yml` (CMake tests + optional Godot 4.7.1 `simulation_smoke.gd`). Existing Android CI jobs untouched.

### Changed (2026-08-14, T11 Godot UX polish)

- **U2 pause overlay:** `GameSession.set_paused` / `pause_changed`; modular HUD `PauseOverlay` (Resume / Save snapshot / Main Menu). Combat tick, placement, upgrade, and hero pulse freeze while paused.
- **U4 HUD:** dedicated Resource/Trading outpost strip, wave label, bottom status line; phase copy (`BUILD · Place defenders` / `COMBAT · Hold the coast`); HQ and dual-currency counters no longer overload a single debug string.
- **U1 menu theme:** paper/indigo/cinnabar bands, 倭寇 subtitle, “Defend the Coast” entry.
- Headless smokes: `main_menu_smoke.gd` (theme), `modular_battle_smoke.gd` (pause freeze + outpost strip).

### Changed (2026-08-11, VS4 unit-upgrade + T8 verification close-out)

- **VS4 build-phase upgrade:** `SimulationCore::upgrade_defender` (C++) boosts a placed defender's damage (+25%) and range (+12px) while it isn't traveling; bound to the new `upgrade_unit` Godot input action (`U` key) and exposed via `get_defenders()`'s `damage` field; covered by a new case in `core/tests/simulation_smoke.gd`. Strengthens VS-A4 (build/position/upgrade phase).
- **T8 GitHub issue hygiene, verified:** re-checked the 2026-08-11 hygiene plan live via `gh` against `Hyperion-Corporation/Project-Mobile-Fortress` — all 10 title edits and epics/research issues #128–#133 confirmed present. Filled in the plan's short status comments that had not actually posted (#33, #46, #70) and corrected a template-substitution bug in #9's comment (posted a follow-up rather than editing the original). See `.agent/cache/AGENT_BUS.md` (T8 log entry) for detail.

### Changed (2026-08-11, Slice-0 implementation + issue hygiene)

- Godot dual-front prototype playable: classic `core/main.gd` and modular `core/scenes/battle/` over `SimulationCore` GDExtension (raiders, defenders, outposts).
- Headless smokes: `core/tests/{simulation,gameplay,modular_battle,flatbuffers,game_session,offline_persistence,main_menu}_smoke.gd`.
- Finished Epic #128 (Slice-0 Godot prototype) and Epic #134 (Godot↔C++ GDExtension boundary):
  - **G3 / S2 Flow Field**: Dual-mode pathing — waypoint lanes primary; optional `init_grids` / `set_cell_solid` BFS flow field for empty-path raiders (commit `1837ccb`).
  - **G4 Hero Abilities**: Migrated hero state and ability casting to native C++.
  - **G5 Level Loader**: C++ `load_level_json` logic now handles wave/config bootstrapping natively.
  - **G7 Outpost Economy**: Finalized dual-currency economic logic tied to mid-path destructible outposts.
  - **G12 Cross-Front Combat**: Matched C++ coordinates to Godot's UI layout and deployed Signal Battery mechanics.
  - **S4 FlatBuffers**: `SimulationCore.save_state` / `load_state` + `src/schema/simulation_state.fbs` (schema v1).
  - **VS7 Ukiyo-e Art**: Generated 2.5D isometric tile atlas palette mockup matching the Wōkòu crisis aesthetic.
  - **VS8 Offline persistence**: `OfflinePersistence` helper — `user://last_run_results.json`, `run_history.json` (20 runs), FlatBuffers snapshot `mf_slice0_snapshot.bin`, classic JSON save; modular Save/Load buttons; main-menu resume + last-run summary; auto-snapshot on run end (commit `9ab1924`).
  - **VS9 / S8 Mobile Export**: `export_presets.cfg` (Android Gradle minSdk 33 / iOS 17), `EXPORT_MOBILE.md`, `export_mobile_smoke.sh`, template installer; **Android debug APK verified** (~159MB); GDExtension mobile paths deferred until NDK binaries exist (commit `53814d6`).
- Roadmaps updated for G2/S0–S8, VS8–VS9; GitHub epics #128–#133 and child issues commented/closed where done.

### Changed (2026-08-11, multi-agent final pass — Godot dual-front decisions)

- **Engine pivot:** primary game client is **Godot 4** (isometric 2.5D); SurfaceView/SpriteKit demoted to legacy template paths. C++ simulation retained; integration via **godot-cpp and C++ modules** (owner C4). See `roadmaps/shared_core.md`, `roadmaps/ios.md`.
- **Slice-0 redefined:** offline **dual-front** land+sea prototype that “shows promise”; ukiyo-e-readable art; Ming+Portuguese; 10–40 units @ 30+ FPS; Android 13+ / iOS 17+. Supersedes 2026-08-09 Android-first single-lane 2026-08-23 track. New `roadmaps/vertical_slice.md`.
- **Co-op design file:** new `roadmaps/co_op_modes.md` — asymmetric land/sea is launch pillar; local Wi‑Fi first; networking after Slice-0; sea-player role documented for schema work.
- **Monetization:** hero/unit **power gacha rejected**; cosmetics → battle pass → cosmetic skin lootboxes; rewarded ads only (`roadmaps/monetization.md`, `ui_ux.md` U5, `qa_testing.md` Q9).
- **Backend:** GameLift not mandatory; alternatives OK; no remote backend for Slice-0 (`roadmaps/backend.md`).
- **AI:** swarm/evo pathing (A11) and sentiment dashboard/events research (A12/A13 HITL) added; identity = RL DDA + swarm (`roadmaps/ai_systems.md`).
- **Top-level** `docs/moon/ROADMAP.md` rewritten to v5.0 for the above. Decision sources: `.agent/reports/shared/pmf_20260810_canonical_shared_report.md`, admin status report, `.agent/cache/owner_qa_lock.md`.
- GitHub issues: hygiene plan prepared at `.agent/cache/github_issue_hygiene_20260811.md` (title edits for G2/M1/U5/B4/Q9/S3 + new epics/research A11–A13). Apply with `gh` when network mutations are authorized.

### Changed (2026-08-09, multi-agent roadmap brainstorm session)

- `docs/moon/roadmaps/multi_framework_platform.md` renamed to `docs/moon/roadmaps/internal_dashboard.md`: merges the delivered MFP1–MFP16 host/island infrastructure (kept verbatim) with a new Part A (ID1–ID11) covering the internal product/telemetry dashboard vision — absorbs the `product-metrics`-labeled GitHub issues (#120–125). Cross-references updated in `docs/moon/ROADMAP.md`, `docs/mkdocs.yml`, `docs/moon/roadmaps/repo_automation.md`, `.agent/messages/claude_subagent_delegation.md`.
- `docs/moon/ROADMAP.md`: added a timeboxed "Playable Vertical Slice" track (VS1–VS5, 2026-08-09 → 2026-08-23, Android first) after review found the roadmap had architected Phases 2–7 well ahead of any playable frame of actual gameplay; added per-roadmap-file ownership table (all `TBD` except `ai_systems.md`, owned by ACFHarbinger).
- `docs/moon/roadmaps/ai_systems.md`: added an Entry gate column for A5, A6, A7, A10 — each now names the required evidence/baseline before implementation starts, rather than being merely marked "not MVP."
- `docs/moon/roadmaps/shared_core.md`: C++-over-Rust/UniFFI decision explicitly revisited and reaffirmed (owner decision) after independent review argued for Rust's compile-time FFI/concurrency safety; noted the mitigations (sanitizers, `clang-tidy`, RAII discipline) are therefore load-bearing.
- GitHub issue backlog (all 100 issues): bodies converted to thin pointers (link to the current roadmap row, no restated implementation description) after finding concrete content drift — issues S1–S7, P2, P5, Q3, IOS3, IOS7 still described a Rust/`hecs`/UniFFI/`rkyv` core three commits after `shared_core.md` switched to C++/EnTT, and B4 said "GCP Firebase fleet provisioning" against `backend.md`'s AWS GameLift/FlexMatch. Root cause: `git/scripts/sync_backlog.py`'s `apply_plan` only ever set issue `body` on ticket creation, never on status transitions, so bodies were frozen at creation time regardless of later roadmap edits. `sync_backlog.py`'s `SYSTEM_PROMPT` updated to require thin-pointer bodies for future ticket creation (see `docs/moon/roadmaps/repo_automation.md` RA5).
- See `.agent/reports/claude/PMF_Analysis_2026-08-09.md` and `.agent/reports/shared/PMF_Shared_Report.md` for the full review and decision record behind these changes.

### Added

- Website source parity modules under `docs/website/src/`: `configs/`, `constants/`, `enums/`, `graphql/`, `hooks/`, `interfaces/`, `simulations/`, `utils/`, plus `stories/` for structured game lore (Wōkòu crisis, coastal fortress network, allied civilizations).
- Root `docs/website/nuxt.config.ts` re-export of `stack/nuxt/nuxt.config.ts` (same discovery pattern as `eslint.config.js` → `stack/eslint/`).
- Nuxt CLI scripts on `docs/website` (`nuxt:dev`, `nuxt:build`, `nuxt:generate`, `nuxt:preview`, `nuxt:prepare`) and matching workspace scripts on the repo-root `package.json`; Nuxt dependency lives on the website package.
- `docs/website/postcss.config.js` and `docs/website/tailwind.config.js` for the Vite + Vue docs site (Tailwind content scan, dark mode via `[data-theme="dark"]`, accent/surface token extensions).
- Custom Vue directives (`src/frameworks/vue/directives/`) and CoastalFlowField Astro island under `src/frameworks/astro/` with Vue iframe wrapper and `public/astro-island` build output.
- Flattened the documentation SPA from `docs/website/vue/` to `docs/website/`, merged the site/app README files, and reorganized Vue sources under `src/frameworks/vue/` with bootstrap in `src/main.ts`, matching this org's multi-framework `src/frameworks/*` convention.
- Added multi-framework platform roadmap [`docs/moon/roadmaps/multi_framework_platform.md`](roadmaps/multi_framework_platform.md) (MFP1–MFP16) for Vue-host + React/Astro/Aurelia islands, GraphQL/Apollo, and WASM on the docs site, grounded in hybrid Vue/React and WASM research.
- Game design and technical architecture research: `docs/moon/reports/Tower Defense Market Research.md` (market/genre/monetization analysis) and `docs/moon/research/Multiplayer Tower Defense Implementation.md` (Rust/UniFFI shared core, ECS, netcode, matchmaking, and ML systems research), informing the roadmap below.
- Rewrote `moon/ROADMAP.md` and all `moon/roadmaps/*.md` around the concrete game concept: **Mobile Fortress**, a cooperative tower-defense game set in 1520s Sengoku Japan with a light 4X clan/territory meta-game, a planned Rust shared simulation core, server-authoritative Co-Op netcode, and procedural/ML systems (Flow Field pathfinding, Wave Function Collapse, RL-based dynamic difficulty, CMAB-personalized offers).
- New `moon/roadmaps/ai_systems.md` tracking procedural content generation and ML-driven difficulty/monetization/retention systems.
- Rewrote `README.md` and updated `.agent/AGENTS.md`'s project overview to describe Mobile Fortress instead of the generic template.
- Filed 76 GitHub issues (one per roadmap line item across `gameplay`, `ui_ux`, `performance`, `monetization`, `backend`, `qa_testing`, `ios`, `shared_core`, `ai_systems`), each labeled `roadmap:<topic>`, and added them all to the [Project Mobile Fortress](https://github.com/users/ACFHarbinger/projects/17) GitHub Project board.
- `docs/moon/roadmaps/multi_framework_platform.md` (MFP7, MFP15 partial): a cross-framework a11y parity kit — `src/simulations/summary.ts`'s `convergenceSummary()` is now the single source of truth both the React host (`ConvergenceStatus.tsx`, a `role="status"` region in the design hub) and the Aurelia island (`convergence-chart-app.ts`'s new `statusSummary` getter, rendered in its own `role="status"` region) call, so the two independently-rendered frameworks can't drift out of sync describing the same GA-convergence run — proven by a Vitest test instantiating both paths against the same data. Also: an Apollo `InMemoryCache` broadcast test (`test/unit/apollo/cache-broadcast.test.ts`, asserting a second `client.query()` for the same entity hits the cache instead of re-invoking the local resolver) and `docs/website/scripts/check-island-budgets.mjs`, a `postbuild`-wired gzip-size check against the roadmap's "≤ 300 kB gzip additional vendor" per-island budget (currently the Aurelia island's `mount-*.js` chunk, ~66 kB gzip).
- `docs/mkdocs.yml`'s Roadmap nav section now lists `multi_framework_platform.md` (it existed on disk but was never wired into the docs site's sidebar).
- `docs/moon/roadmaps/multi_framework_authoring_guide.md` (MFP16): the decision guide for adding new `docs/website/` functionality — native React component vs. foreign-root island (Aurelia pattern, with the decorator-metadata and SVG-binding pitfalls this site already hit documented as teardown/verification rules) vs. iframe island (Astro pattern) vs. WASM (forward-looking, MFP12+). Linked from the Roadmap nav alongside the platform roadmap.

### Changed

- Merged `LICENSE.md` (AGPL-3.0 open track) and `LICENSE.txt` (commercial terms) into a single extensionless `LICENSE` file matching the dual open-core layout used in `Repositories/Templates/*` (Section A AGPL-3.0 + Section B commercial agreement); updated README license links.
- Slimmed `docs/website/stack/nuxt/`: removed mini-app copies (`app.vue`, `pages/`, local `tsconfig`) and the nested `package.json` so the directory holds Nuxt **config** only, analogous to `github-pages/stack/next/`.
- Moved `docs/website/src/views/` → `src/frameworks/vue/views/` and `src/directives/` → `src/frameworks/vue/directives/`; updated `main.ts`, `router.ts`, tests, and docs accordingly.
- Relocated `docs/reports/` → `docs/moon/reports/` and `docs/research/` → `docs/moon/research/`; updated `docs/mkdocs.yml`, navigation configs, and all internal relative path references across the repository.
- Retconned the setting from 1520s Sengoku Japan to the **1540s–1560s Wōkòu (倭寇) / Wakō pirate crisis** on the East Asian coast: the player defends a coastal fortress network — a Main HQ/Citadel (loss condition), Resource Outposts (fund land units), and Trading Outposts (fund naval units) — against raiding Wōkòu pirate fleets striking by land and sea, commanding an East Asian primary civilization (Ming China by default; Japan/Joseon Korea as alternates) reinforced by a supporting Western civilization (Portuguese by default; Spanish/Dutch/British/French as alternates). Reworked the unit roster accordingly (Ming Garrison Spearmen, Fo-lang-ji Cannon Crews, East Asian Archers, Veteran Commanders, Portuguese Arquebusiers, East Asian War Junks, Western Galleons) and dropped the supernatural Yokai-corruption mechanic in favor of grounded raider warfare. Updated `docs/design/*.md`, `docs/moon/ROADMAP.md`, `docs/moon/roadmaps/*.md`, `README.md`, `.agent/AGENTS.md`, `docs/index.md`, `docs/ARCHITECTURE.md`, `docs/GLOSSARY.md`, and the interactive design website (`docs/design/website/`) accordingly. Added a new Resource/Trading Outpost economy line item to `docs/moon/roadmaps/gameplay.md`.
- Moved `design/` → `docs/design/` and `moon/` → `docs/moon/` so all design, roadmap, and reference documentation lives under a single `docs/` tree; fixed all cross-references (relative links in docs, `.agent/`, PR/MR templates, CI workflow comments) to the new paths.
- Merged the interactive design-hub website (formerly `docs/design/website/`) and the documentation portal (formerly `docs/public/`) into a single `docs/website/`. Initially rewritten as a no-bundler CDN/global-build Vue 3 SPA, then superseded by a proper **Vite + Vue 3 + TypeScript** project at `docs/website/` (mirroring the architecture used by this org's other repos, e.g. Image-Toolkit's `docs/website/`): `scripts/generate-nav.mjs` derives the site's nav from `docs/mkdocs.yml`'s `nav:` tree plus a curated list of repo-wide guides that live outside `docs/` (README, CONTRIBUTING, infra runbooks, `core/`, research/reports), and every Markdown source is bundled at build time via `import.meta.glob` (`src/composables/useDocs.ts`) — no runtime content mirror needed. Pages render with `markdown-it` + `markdown-it-anchor` + `markdown-it-texmath`/KaTeX + `highlight.js`, with Mermaid diagrams rendered live, a searchable sidebar (⌘K), per-page TOC, prev/next navigation, and an "Edit on GitHub" link. The design-hub tabs (Flow Field simulator, GA wall-layout visualizer, dynamic-audio mixer, sprint roadmap, QA net-sync dashboard) are proper Vue SFCs under `src/components/hub/` with real reactive state, computed properties, and `v-model` bindings. Also adds `docs/{TROUBLESHOOTING,DEPENDENCY_POLICY,DOCUMENTATION_STANDARDS,BENCHMARKS}.md`, matching this org's other repos' documentation set.
- Reworked `.github/workflows/docs.yml` to build `docs/website` (`npm ci && npm run build`) and publish its `dist/` output to a `gh-pages` branch via `peaceiris/actions-gh-pages`, instead of GitHub's managed Pages artifact/OIDC deploy or a runtime content-mirror step. `docs/mkdocs.yml` (excluding `website/` via `exclude_docs`) remains available for local browsing via `mkdocs serve`, sharing its `nav:` tree as the Vue site's source of truth. Trigger/permissions structure follows this org's `WSmart-Route` convention: `workflow_dispatch` takes a `reason` input, the `push` trigger runs on every push to `main` (no path filter — the site's nav also covers repo-wide guides outside `docs/`, e.g. `README.md`, `core/README.md`, infra runbooks), and `permissions: contents: write` is scoped to the `build-and-deploy` job rather than the whole workflow.
- Moved `reports/` → `docs/reports/` and `research/` → `docs/research/` so every design/reference document lives under `docs/`; added a **Research** section to `docs/mkdocs.yml`'s `nav:` (picked up automatically by `docs/website`) and removed the now-redundant `Research` entry from `generate-nav.mjs`'s `EXTRA_SECTIONS`. Fixed all cross-references across `README.md`, `.agent/AGENTS.md`, every `docs/moon/roadmaps/*.md`, `docs/DEPENDENCY_POLICY.md`, `docs/BENCHMARKS.md`, and `docs/website/README.md`.
- Restructured the Gradle build to a **repo-root workspace**: moved `gradlew`, `gradlew.bat`, `gradle/` (wrapper + `libs.versions.toml`), `gradle.properties`, and `settings.gradle.kts` from `android/` to the repo root, and moved `android/build.gradle.kts` to a new root `build.gradle.kts`. `settings.gradle.kts` maps `:app` to `android/app/` via an explicit `projectDir` override, so `./gradlew <task>` now works from anywhere in the repo without `cd android/` or `-p android`. Updated every CI workflow (`.github`, `.forgejo`, `.gitea`, `.gitlab`), `.pre-commit-config.yaml`, `.devcontainer/devcontainer.json`, all `tools/*/justfile` recipes, and the relevant docs (`AGENTS.md`, `TROUBLESHOOTING.md`, `DEVELOPMENT.md`, `DEPENDENCY_POLICY.md`, `TESTING.md`, `.agent/rules/kotlin.md`, `.agent/skills/*.md`) accordingly — local `local.properties` now lives at the repo root too (`android/local.properties` is no longer read). Verified with `./gradlew ktlintCheck`/`./gradlew projects` under JDK 21.
- Added a root `package.json` declaring **npm workspaces** (`docs/website`), with `site:dev`/`site:build`/`site:preview`/`site:nav` convenience scripts — `docs/website`'s `package-lock.json` was removed in favor of one root-level lockfile (npm workspaces hoist `node_modules` to the root). Updated `.github/workflows/docs.yml` to `npm ci` at the root and `npm run build --workspace docs/website`, and added an `npm` entry to `.github/dependabot.yml` (directory `/`) alongside the existing `gradle` entry (also repointed from `/android` to `/`).
- Added a root `pyproject.toml` pinning `mkdocs-material` (this repo has no Python application code) — `pip install .` now reproducibly installs the local `mkdocs serve` dependency instead of the previous ad-hoc `pip install mkdocs-material`.
- Rewrote `README.md`'s Quick Start section so every command runs from the repo root without `cd`-ing into a subdirectory first (`./gradlew`, `npm run <script> -w docs/website`, `pip install . && mkdocs serve`), and updated the Repository Layout tree/table to reflect the new root-level workspace files.
- **Switched the planned shared simulation core from Rust to C++20**, matching this org's `base/`-module convention (see Image-Toolkit's `base/` for precedent): ECS via [EnTT](https://github.com/skypjack/entt) (was `hecs`), zero-copy state serialization via [FlatBuffers](https://flatbuffers.dev/) (was `rkyv`), and a hand-written C ABI shim bound via JNI (Android) and Swift's native C++ interop / an Objective-C++ fallback (iOS) in place of UniFFI's automated Rust bindings generator — no C++ equivalent of UniFFI's maturity exists, so the FFI surface is kept intentionally small and hand-reviewed. Dependency management moves to CMake + vcpkg (manifest mode) in place of Cargo, and `criterion` micro-benchmarks become Google Benchmark. Added a "Trade-offs vs. a Rust core" section to `docs/moon/roadmaps/shared_core.md` documenting the safety properties lost without a borrow checker (no data races/use-after-free guarantees) and the mandatory mitigations (RAII discipline, ASan/UBSan/TSan in CI, `clang-tidy` as a required gate) — this is a real engineering trade-off, not a cosmetic rename. Updated every design doc (`game_design_document.md`, `technical_design_document.md`, `production_roadmap.md`, `pitch_deck.md`, `qa_test_plan.md`), every roadmap referencing the core (`shared_core.md`, `performance.md`, `backend.md`, `ai_systems.md`, `qa_testing.md`, `ios.md`), `docs/ARCHITECTURE.md`, `docs/GLOSSARY.md`, `docs/DEPENDENCY_POLICY.md`, `docs/BENCHMARKS.md`, `docs/DOCUMENTATION_STANDARDS.md`, `README.md`, `.agent/AGENTS.md`, `.agent/prompts/master_context.md`, `core/README.md`, and the `docs/website` design-hub content (`TechPanel.vue`, `ProductionPanel.vue`, `QaPanel.vue`, `HomeView.vue`, plus `useMarkdown.ts`'s registered `highlight.js` languages: `cpp`/`cmake` in place of `rust`). Left the original Rust/UniFFI research and rationale intact in `docs/moon/research/Multiplayer Tower Defense Implementation.md` and in already-shipped `docs/moon/CHANGELOG.md` history as the frozen record of what was originally researched — `shared_core.md` now explains why C++ was chosen instead.
- Renamed the Android package `com.example.gametemplate` → `com.acfharbinger.mobilefortress` (directories, `build.gradle.kts` namespace/applicationId, ProGuard rules, manifest, `Theme.GameTemplate` → `Theme.MobileFortress`, app name string) and the iOS bundle identifier `com.example.mygame` → `com.acfharbinger.mobilefortress` (`.pbxproj`, `UserDefaults` keys in `SettingsStore`/`HighScoreStore`).
- Renamed the optional backend's Helm chart directory `infra/global/helm/mobile-game-template/` → `infra/global/helm/mobile-fortress/` (chart name, template helper names, image repository references), and updated matching image references in `infra/global/ansible/`, `infra/global/k8s/`, `infra/global/terraform/`.
- Scrubbed remaining "Mobile-Game-Template"/generic-template wording from `README.md`, `.agent/` (`AGENTS.md`, prompts, rules, skills, workflows), `docs/` (`index.md`, `ARCHITECTURE.md`, `GLOSSARY.md`, `DEVELOPMENT.md`, `mkdocs.yml`, ADRs 0002/0003), `git/CONTRIBUTING.md`, `LICENSE.txt`, `justfile`, `tools/*/justfile`, `.devcontainer/`, and `.github/ISSUE_TEMPLATE/config.yml` — all now describe Mobile Fortress specifically. Historical "template era" framing in `moon/ROADMAP.md`/`CHANGELOG.md` (documenting the repo's actual scaffolding phase) is intentionally kept.

### Added (template era)

- Initial template scaffolding: root files (`LICENSE`, `README.md`, `.pre-commit-config.yaml`, `.gitignore`), `.github/` CI/CD, `git/` (`CONTRIBUTING.md`, `codecov.yaml`), `docs/` documentation portal (MkDocs + ADRs), `moon/` roadmap and changelog.
- `.agent/` LLM coding-agent scaffolding: `AGENTS.md` plus rules, workflows, prompts, and skills covering Kotlin, Android lifecycle, game-loop performance, Compose UI, testing/QA, code review, debugging, documentation, and planning.
- Standard Android app module (`app/`) built on `com.android.application` + `kotlin-android`: `MainActivity`, `GameView` (SurfaceView), `GameLoop` (fixed-timestep thread), `GameEngine`/`GameState`, one demo entity (`Ball`), one unit test, one instrumented test.
- Root Gradle wrapper and `settings.gradle.kts` including `:app`.
- `infra/{docker,k8s,helm,terraform,ansible}/` — optional, lightweight leaderboards/cloud-save backend scaffolding, explicitly optional for offline play.
- `.devcontainer/` with Android SDK cmdline-tools, JDK 17, and an emulator system image.
- `.github/workflows/ci.yml` (unit tests + lint + instrumented tests via emulator matrix), `release.yml` (signed AAB/APK + optional fastlane Play Store upload), `docs.yml`.

## [0.1.0] — 2026-08-02

### Added

- Repository created from scratch as a GitHub template.
