# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed (2026-10-09, T67 T64 HOLD follow-up — Qwen Harbinger)

- **Range/cooldown parity:** `UnitDef` now has `canonicalRange` (world units) and `canonicalCooldown` (seconds) matching `unit_defs.gd`. Derived `range`/`cooldown` used for demo grid. Roster shows canonical values with units (e.g., "🎯 1.6", "⏱️ 0.7s"). Drift test checks both; range and cooldown mutations each fail independently.
- **Own-wallet-first placement:** `canPlace`/`placeUnit`/`removeUnit` follow `UnitDefs.placement_plan` — charge unit's own currency first, fall back to clicked grid's wallet only when different and can pay. `PlacedUnit.paidFrom` tracks which wallet paid; removal refunds that wallet. Tests for Qi, Dias, Signal Battery: own-first, fallback, rejection, refund.
- **Fractional damage:** `getDamageMatrix` and combat use raw float values (Signal Battery 3.3/6.9, not 3/7). Roster displays with `toFixed(1)` for non-integers.
- **Targeting note:** Demo page now documents how toy targeting differs from `SimWorld` (normal defenders only fire own-front; Signal Battery fires both fronts per tick vs native closest-target).

### Reviewed (2026-10-09, T66 round 4) — Codex Harbinger

- Reviewed T59–T65 by commit; full findings and independent mutation evidence live in `.agent/reports/chat/T66_review_2026-10-09.md`. T59/T61 verified with game fixes; T60/T63/T65 verified; T62 verified with documentation corrections; T64 held for range/cooldown drift coverage and placement/damage parity.
- Reconciled AGENTS/README with repaired Android/export configuration, updated the smoke inventory to include T65, and distinguished headless control measurements from full-grid/device playtesting in VS10 guidance. ID8 remains Partial with the T64 review hold recorded.

### Fixed (2026-10-09, T66 menu and review guards) — Codex Harbinger

- Placement and preview preserve infinite-wallet mode with an empty purse, including own-wallet priority before a finite fallback. The new T61 affordability pre-check had rejected these placements.
- Returning-player menus with Resume and history text no longer clip Quit at 844×390: compact landscape omits the introductory blurb and retains rank, history and full-size actions. Accessibility smoke now exercises that state and checks labels, including campaign rank, for containment.
- Battle HUD coverage is checked against the independently measured pre-T59 16640 px² reference instead of measuring a baseline from the same implementation under test.

### Added (2026-10-08, T65 Godot-boundary determinism smoke — Muse Harbinger)

- **Q4/S7:** New `game/tests/determinism_smoke.gd` (runs in `scripts/run_godot_smokes.sh`, sub-second) scripts a fixed-dt session through `SimulationCore` on every catalog level — fixed defender placements, combat at a fixed tick, run past the second wave — twice in fresh cores, requiring byte-identical `save_state` buffers; a third run saves mid-wave and resumes in a fresh core to the same end buffer. A one-tick placement shift must change the digest (proven: the built-in 1-tick control fires every passing run, and a disposable 7-tick-shifted duplicate fails the comparison). No C++ or level changes.

### Added (2026-10-09, T64 ID8 slice 3: roster + damage matrix + drift test — Qwen Harbinger)

- **Full roster in demo:** All 7 playable units from `unit_defs.gd` now in the website sim: 4 defenders (spearman, cannon, arquebusier, junk), 2 heroes (Capitão Dias ⭐, Commander Qi ⭐), and Signal Battery 🔗. Added missing `hero_dias` (Capitão Dias). Heroes now have `front: "both"` matching the game.
- **Roster panel:** New `RosterPanel` component below the demo grids shows every unit with cost/currency, damage, range, cooldown, HP, and a 2×2 damage matrix (stands on land/sea × target land/sea) following the game's `get_effective_damage` rule (own multiplier vs same-front, cross multiplier vs opposite-front).
- **Drift test:** `unit-defs-drift.test.ts` reads `game/scripts/data/unit_defs.gd` from the repo and verifies cost, damage, own_env_mult, cross_env_mult, currency, front, and kind match for all 7 shared units. Mutation proven: changing spearman damage from 8→99 in the game file fails the test.
- **Sim module:** `UnitDef` now has `kind`, `currency`, `ownEnvMult`, `crossEnvMult` fields (all required). `isHero`/`isCrossSupport` use `kind` field. `getDamageMatrix()` helper added. Normal defender damage uses `ownEnvMult` per the game's rule.

### Fixed (2026-10-08, T63 legacy Android configures again; export smoke points at game/ — Kimi Harbinger)

- **Android CI unblocked (Q2):** `gradle/libs.versions.toml` pinned AGP 9.3.1, which CI rejected with "Minimum supported Gradle version is 9.5.0" against the wrapper-pinned Gradle 8.7. Reverted to the documented combo — AGP 8.5.2 — and reverted the dependabot-style bumps that had cascaded from it (`lifecycleRuntimeKtx` 2.8.4, `kotlinxCoroutines` 1.8.1, `espressoCore` 3.6.1, `androidxTestCore` 1.6.1; lifecycle 2.11.0 alone requires AGP 9.1.0 + compileSdk 37 per its AAR metadata). Verified locally (JDK 21, SDK platform auto-installed with accepted licenses): `ktlintCheck` BUILD SUCCESSFUL, `lintDebug` BUILD SUCCESSFUL, `testDebugUnitTest` 3/3 tests 0 failures, `assembleDebug` produces `app-debug.apk`. CI runs JDK 17 — first post-merge run confirms. Instrumented emulator job unchanged, not runnable on this host.
- **`scripts/export_mobile_smoke.sh`:** `CORE_DIR` corrected `core` → `game` (the tree was renamed long ago; the config check failed on every run since). Config check now passes end-to-end: 14 PASS (project files, export presets, desktop `.so` present) with only legitimate warnings (optional Android arm64 GDExtension absent, templates not installed on this host, iOS export needs macOS). ShellCheck-clean. APK export itself not run (not required by T63).
- **iOS (unchanged, recorded):** `ios/MyGame.xcodeproj` still fails to parse under the runner's Xcode 26.6; extended static checks (balanced braces, no duplicate keys, no non-ASCII/control bytes, `objectVersion 56` / `compatibilityVersion "Xcode 14.0"` is an Xcode-written pair) find no defect. Left path-gated to `ios/**`; no `continue-on-error`. Needs a macOS host.

### Fixed (2026-10-08, T62 player-facing docs truth pass — Mistral Harbinger)

- `game/README.md` + `docs/TESTING.md`: replaced the stale hand-enumerated smoke invocation lists (the README named only a subset of the 27 smokes on disk) with the runner (`./scripts/run_godot_smokes.sh`, subset args, `GODOT`/`SMOKE_TIMEOUT` overrides), a per-smoke coverage table built by reading each `game/tests/*_smoke.gd`, a native `ctest` section, and the manual perf-bench section (budgets + the `docs/BENCHMARKS.md` recording rule). Every documented command was run in this checkout on 2026-10-08: smokes 27/27 PASS, `ctest --test-dir game/build` 1/1 PASS, perf bench PASS (tick p95 = 1 µs at 40 units; flow recompute p95 = 1 µs); not run: the cmake extension rebuild (Grok-only `game/bin/*.so` replacement rule — the checked-in binary passes all smokes) and the export smoke script (Kimi's T63 is fixing its stale `core/` path).
- `docs/moon/VS10_PLAYTEST_PROTOCOL.md`: environment setup now points at `game/BUILD_CPP.md` for the exact build commands (dropping the stale inline copy to a `linux.template_debug` binary name that no longer matches the `.gdextension`) and at the repo-root `scripts/export_mobile_smoke.sh`; new DDA section — A4 heuristic director **off by default**, dev-overlay only, per-session on/off record; documents the DT7 `wave_start` fields `dda_enabled`/`dda_intensity` and the four T46/T59 reference windows (1280×720, 720×1280, 390×844, 844×390); both session-log templates gained DDA and window-size fields. No session results invented — sessions have not been run.
- `.agent/cache/README.md`: the agent table (still listing the four 2026-08-10 founders) now carries the current two-team roster (nine Harbinger agents + Gemini Wall + owner) with bus aliases and a pointer to the bus `§Signing` section rather than duplicating it; the completed 2026-08-10 bootstrap goals are replaced by a pointer to the live bus task board.

### Added (2026-10-08, T61 one affordability rule and menu citadel rank — Cursor Harbinger)

- **G12:** `UnitDefs.placement_plan(id, placed_front, land, sea)` is the single answer for “can this stand here, and which wallet pays”: own currency first, then the other wallet only when the clicked grid uses that other wallet. `can_afford(..., placed_front)` is optional; the three-argument form stays own-currency-only. `battle_root` placement and touch preview call the helper — no second spend path. Spawn front remains the clicked grid. Spawn-fail refund still credits the unit’s own currency even if the fallback wallet paid (left for an owner decision).
- **G8:** Main menu `CampaignRankLabel` shows the T58 citadel title, progress to the next rank, and campaign star total. Smoke: `placement_afford_smoke.gd` (battle path uses the helper: mutating the fallback fails the Qi-on-sea / 0-land placement) plus `unit_catalog_smoke.gd` plan cases.

### Added (2026-10-08, T59 U4/U8/IOS2 battle HUD phone-scale targets & citadel rank)

- **U4 / U8 / IOS2 (Battle HUD):** Density-aware touch target sizing and responsive layout in `battle_hud.gd` (`game/scripts/ui/battle_hud.gd`). Sized all interactive buttons to $\ge 48\text{ dp}$ in both width and height across all four target viewports (`1280×720`, `720×1280`, `390×844`, `844×390`) with and without 1.15× Large Text (`ThemeTokens.large_text`).
- **Sidebar & TopBar Reflow:** `SideBar` restructured into a multi-column responsive `GridContainer` (3 columns in compact landscape phone viewports, 2 columns otherwise) holding all unit and action buttons with zero clipping, non-overlapping with `TopBar`, and zero extra grid occlusion at 1280×720 baseline (exactly matching the 16,640 px² StatusLabel footprint).
- **Dedicated Pause & Speed Controls:** Added accessible HUD `PauseBtn` (toggling `GameSession.is_paused`) and `SpeedBtn` (cycling `GameSession.time_scale` 1× / 2× / 3×) with focus rings, hover styling, and a11y metadata.
- **Citadel Rank Progression:** Results panel (`show_result`) now surfaces Citadel Rank prestige tier (`Progression.get_prestige_tier`) and progression towards the next rank (`Progression.get_next_prestige_tier`) alongside star ratings and prestige rewards.
- **Verification:** Added `game/tests/battle_hud_layout_smoke.gd` headless smoke asserting rendered window pixels $\ge 47.9\text{ px}$ in both dimensions, viewport containment, non-overlap, and grid coverage constraints across all 4 reference viewports and large-text states. 26/26 Godot smokes pass. — Gemini Harbinger

### Changed (2026-10-08, T60 flow-field property tests and tick allocation audit — Grok Harbinger)

- **Q3:** Doctest now checks flow fields from a fixed-seed xorshift32 inside the test (`0x54464C57`). Six grid sizes, 24 solid layouts each, both fronts: 288 fields. A finite-cost cell steps to a strictly cheaper neighbour that is on the grid and not solid. Cutoff cells stay at cost 9999 with a zero direction. Toggling one open cell solid and back restores cost, direction, and the solid bit. `SimWorld` itself stays RNG-free. ECS ordering is still untested, so Q3 stays Partial.
- A raider walled into a single cell stays there. `pick_flow_step` used to fall back to east even when that step entered a solid and no open neighbour existed; that one case now returns `{0,0}`. East is still used when it is open. The v1 snapshot fixture and the v2 save/load tick-match test still pass.
- **P4 (Partial):** `update_flow_field` reuses one member BFS queue sized to the grid. The first event of a tick reserves 8 slots; a quiet tick still allocates nothing. A lane path is moved into the raider once, and the raider vector is reserved to the spawn cap of 40. Left in place on purpose: the vector `tick` returns (the signature returns it by value), each raider's own waypoint storage, and the long victory-reason string. There is no entity pool.
- `perf_budget_bench.gd` on this machine, before and after, both PASS: tick p95 at 40 entities = 1 us, flow-recompute p95 = 1 us, budget 8000 us. New C++ getter `flow_cost_at` is not bound to GDScript. Existing GDScript method signatures are unchanged.

### Fixed (2026-10-08, T49 review — guide accuracy)

- Agent guide v3.1 and README distinguish vector-backed `SimWorld` combat from the separate EnTT scaffold. Corrected the level-loader location to `simulation_core.cpp`, the legacy AGP pin to 9.3.1, the relative C++ badge link, and the required playtest-sync input argument. Removed unsupported Jolt configuration and GC/blocking-await claims; section 8 stays unchanged.
- Documented a pre-existing export-smoke limitation: `scripts/export_mobile_smoke.sh` still uses `CORE_DIR="core"` and fails against the current `game/` tree. Export-script repair remains separate from T49's documentation work.

### Fixed (2026-10-08, T49 docs workflow strict-green + agent-guide refresh)

- `mkdocs build --config-file docs/mkdocs.yml --strict` is green locally again, reproduced with the same install and command the `Docs` workflow uses (`pip install mkdocs-material` on Python 3.12+/mkdocs-material 9.7.7, mkdocs 1.6.1). The five out-of-tree references strict mode rejected are now absolute GitHub URLs — `moon/ROADMAP.md` → the two `.agent/reports/*` decision documents, `moon/roadmaps/repo_automation.md` → `git/README.md`, `moon/roadmaps/shared_core.md` → `game/BUILD_CPP.md`, and `design/dual_front_state_schema.md` → `game/src/schema/simulation_state.fbs` + `game/src/cpp/` — rather than disabling strict mode. The `moon/CHANGELOG.md` link to the deleted `multi_framework_platform.md` is pinned to its last-existing commit with a pointer to the renamed `internal_dashboard.md` Part B. `docs/mkdocs.yml` site identity updated to the canonical `Hyperion-Corporation` org (the former `ACFHarbinger` org URL redirects there).
- `.agent/AGENTS.md` v3.0 and `README.md` now describe the live product — the Godot 4.7 game under `game/` with the C++ `SimulationCore` GDExtension (vector-backed combat, EnTT scaffold, FlatBuffers snapshots) — with current module boundaries, CLI entry points (`scripts/run_godot_smokes.sh`, `ctest` per `game/BUILD_CPP.md`, `scripts/run_perf_bench.sh`, the strict docs build), Godot/C++ review-severity examples, and the `android/`/`ios/` trees explicitly marked legacy. AGENTS.md §8 (multi-agent session workflow) is unchanged.

### Fixed (2026-10-08, T54/T56 website review follow-up)

- Signal Battery remains selectable when either wallet can pay; the component regression now also verifies sea placement charges only sea funds and an unaffordable land placement is rejected.
- Website CI generates doc content before a real `tsc -b` check. Review strengthens combat tests to assert exact 3/7 damage for support placed on either front and simultaneous 28-damage hits on two hero targets while a sea target stays unharmed. Zeroing either attack, doubling cross damage, and limiting the hero to one target each fail regression tests. Full suite: 80/80 PASS.
- Independent Chromium measurement at 320×844 confirms the demo header and document have 320px scroll widths; all five visible header controls fit and pass center-point hit testing. Vite production build and Aurelia island budget pass (66.1 kB gzip / 300 kB).

### Fixed (2026-10-08, T53 review — phone target widths)

- Settings Reset/Cancel/Save now apply the density minimum to width as well as height. At 390×844 the original widths were 40.2/30.5/39.6 window pixels; the accessibility smoke now checks both dimensions at all four reference-density windows with Large Text on/off. The width regression probe failed six assertions before the fix; the full combined Godot suite passes 24/24 afterward.

### Fixed (2026-10-08, T53 review — legacy CI gates)

- Android build and instrumented jobs now directly depend on `changes`, making their path-gate outputs available. An unavailable Git diff range runs both legacy trees conservatively instead of considering only the last commit. Verified the actual gate shell for six path sets, an unavailable base, and manual dispatch; real Actions execution remains for the lead after push.

### Added (2026-10-08, T52 level schema refresh + validation smoke + P3 flow-recompute bench)

- **Level schema refresh:** `game/src/level-schema.json` now describes the dual-front level JSONs as the loaders actually read them (cross-checked against `SimulationCore.load_level_json` and `LevelCatalog`): required `id`/`displayName`/`waves`, per-wave `delaySeconds` + `landCount`/`seaCount`, loader-read optionals (`startingLandCurrency`, `startingSeaCurrency`, `hqMaxHp`, `buildPhaseSeconds`, `victoryTimeSeconds`), and carried-but-unread informational keys (`civPrimary`, `civSupport`, `enemySpawnIntervalSeconds`, `spawnPattern`). The legacy `level_01.json` single-front leftover is documented as non-conforming and catalog-skipped. No level JSON was changed.
- **Level validation smoke:** new `game/tests/level_schema_smoke.gd` (runs in `scripts/run_godot_smokes.sh`) validates every catalog level against the loaded `level-schema.json` itself (bounded draft-07 subset: required, types, integer vs number, minimums, lengths), cross-checks wave count and starting values through the real C++ loader, and pins the `level_01` catalog exclusion. Negative controls fail on broken in-memory copies (missing `seaCount`/`id`, empty waves, numeric `spawnPattern`, fractional `enemyCount`) and on a tampered schema with an extra `required` key; a vacuous validator fails all six controls.
- **P3 flow-recompute bench:** `perf_budget_bench.gd` gains a second scenario timing 2000 defender-style solid place/remove recomputes (each timed sample is exactly one `set_cell_solid` call, fronts alternating) on live 8×5 combat grids (20 flow-mode raiders, `uses_flow` asserted, HQ-damage liveness proof) with its own percentiles and `FLOW_BUDGET_US = 8000` line — still a manual gate, never CI. Desktop numbers in `docs/BENCHMARKS.md`: p95 = 1 us per recompute, PASS. Roadmap: P3 → 🚧 Partial; P7 notes the extended script; G5 unchanged.

### Added (2026-10-08, T51 ID8 slice 2 + header overflow + website CI)

- **ID8 slice 2:** Demo gains Commander Qi (⭐ hero, area ability on 80-tick cooldown, 28 AoE damage) and Signal Battery (🔗 cross-front support, fires at both land and sea raiders with 0.55×/1.15× env multipliers). Hero ability auto-triggers when raiders are in range and the cooldown is ready; the view shows a gold cooldown bar. Cross-support can be placed on either front grid. Budgets raised to 60/60 to accommodate the new units. Known bug (T53 review HOLD): the Signal Battery button is disabled whenever land funds are short, even if sea funds could pay for a sea placement.
- **Header overflow fix:** T56 independently verified the rendered demo header at 320px (no overflow; visible controls reachable) — brand-name hidden below 480px, topbar padding and gaps reduced, search trigger min-width removed at 640px.
- **Website CI:** New `.github/workflows/website.yml` runs ESLint, a real `tsc -b` after generating doc content (T54, independently verified in T56), and `vitest run` on pushes/PRs touching `docs/website/**`.
- **Tests:** 63 → 78 vitest tests (+15: hero ability mechanics, cross-support dual-front firing, unit classification helpers, view rendering of new unit badges).

### Fixed (2026-10-08, T50 CI workflow green — Q2)

- **`ci.yml` no longer fails on every push.** A new `changes` job diffs the push/PR range and gates the legacy-template jobs per tree: the three Android jobs run only when `android/**`, `gradle/**`, root Gradle build files, `justfile`, or the workflow itself change; `ios-test` runs only when `ios/**` or the workflow changes; `game/**` work is gated by `godot-game.yml` instead. The `changes` and `shellcheck` jobs always run. Findings recorded in `docs/TESTING.md`, not hidden: (1) `gradle/wrapper/gradle-wrapper.jar` regenerated via Gradle 8.7's `wrapper` task — sha256 now matches the official 8.7 checksum and passes `setup-gradle` wrapper validation; (2) the Android tree still pins AGP 9.3.1, which cannot run on wrapper-pinned Gradle 8.7 (`NoClassDefFoundError` at plugin apply) — needs a deliberate AGP-downgrade or wrapper-upgrade decision; (3) `ios/MyGame.xcodeproj` fails to parse under the runner's Xcode 26.6 despite a statically valid pbxproj — needs a macOS host to root-cause. Legacy code is untouched and no failure is masked with `continue-on-error`.
- **ShellCheck gate for `scripts/*.sh`:** new `shellcheck` job in `ci.yml` (digest-pinned `koalaman/shellcheck` 0.11.0 image, same as local verification); `export_mobile_smoke.sh` (unused `WARN` counter, five `A && B || C` checks) and `install_godot_export_templates.sh` (two `ls | head` listings) fixed — all 10 repo shell scripts now lint clean.

### Added (2026-10-08, T48 A4 battle hookup + DT5 intensity readout)

- **A4:** Modular battle now pushes the persisted DT8 overlay DDA toggle through `GameSession.apply_dda` after level load, `debug_load_level`, and `load_snapshot` (the overlay setting wins over a v2 snapshot's stored flag). Default remains off; player Settings is unchanged. With the toggle off, the director stays disabled.
- **DT5:** Overlay `DiagLabel` shows `DDA on/off · intensity 0.00` from `SimulationCore.get_dda_intensity` (1.00 while off). `DdaToggle` is the persisted fine-tune, not a player-facing control.
- **DT7:** Open playtest sessions record a `wave_start` event at each C++ `wave_spawned` with `dda_enabled` and `dda_intensity` so VS10 sessions can be compared. Smoke: `dda_battle_smoke.gd`. A4 stays 🚧 until tuned against playtest data.

### Changed (2026-10-08, T47 snapshot completeness — S4/S5)

- **S4 / S5:** Schema v2 appends `Raider.entry_row`, `grid_width` / `grid_height`, both flow grids (cost, direction, solid), and the DDA inputs (`dda_enabled`, wave-open, spawn time, last clear, purse baseline). `save_state` / `load_state` round-trip them. A resumed mid-combat run with flow grids live and DDA on matches the same ticks without the round trip (`sim_world_tests`). Snapshots written before this change are version 1: they still load, leave the receiver's grids and DDA flag alone, drop the clear sample, and rebase the purse. Fixture: `game/tests/native/fixtures/s4_v1_midcombat.bin`.
- DT1/DT2 cheat flags are not stored. Every successful `load_state` turns infinite resources, invulnerability, and disabled waves off. `SimulationCore` method signatures are unchanged. `flatbuffers_smoke.gd` covers a fresh-core restore of flow, entry row, and DDA, and the cheat reset.
- `docs/design/dual_front_state_schema.md` §8 marks the T41/T38 gaps resolved or, for cheat flags and the legacy EnTT registry, deliberately omitted.

### Added (2026-10-08, T46 U8 mobile touch-target sizing & responsive menu reflow)

- **U8 (Menu & Settings):** Density-aware touch target sizing (`ThemeTokens.compute_density_min_size`, `ThemeTokens.apply_density_min_height`) scales interactive controls to ≥48dp in actual rendered window pixels under Godot 4 `canvas_items`/`expand` stretch across desktop, portrait, and phone viewports (`1280×720`, `720×1280`, `390×844`, `844×390`).
- Responsive reflow: MainMenu adjusts `VBox` width and separation with dynamically pinned version label; SettingsDialog adopts a 9-column landscape audio slider grid and combined 4-checkbox control row in compact viewports to prevent vertical clipping within the 720 canvas height. Runtime `size_changed` listeners re-apply density sizes on window resize/orientation change.
- `game/tests/accessibility_smoke.gd` Section 6 updated to verify rendered window-pixel dimensions (`wr.size.y >= 47.9`), screen containment (`vp_rect.encloses`), and non-overlapping layouts across all 4 viewports for both `large_text = false` and `large_text = true`. All T39 accessibility assertions (WCAG AA contrast, closed-loop focus, 4-way modal containment, opener restoration) continue to pass. In-battle HUD touch targets remain deferred.

### Fixed (2026-10-08, lead review of the GGWall branch — T57/T58)

- **G12:** `UnitDefs.get_effective_damage` now follows the simulation rule: a defender uses `own_env_mult` against raiders on the front it stands on and `cross_env_mult` against the other front. The first version hard-coded the Signal Battery as "strong on land, weak on sea" wherever it stood and ignored the heroes' cross-front multiplier. New optional `placed_front` argument for both-front units, defaulting to the new `get_home_front` (the front whose currency pays); raiders return 0. `unit_catalog_smoke.gd` covers both placements and both heroes.
- **G8:** `Progression.total_stars` and `get_level_summary` skip a malformed (non-dictionary) level entry instead of raising; `progression_smoke.gd` adds that case and just-below-threshold tier checks.
- GeminiWall's two tasks are renumbered **T57** (G12) and **T58** (G8): T54/T55 were already taken on the team board. Roadmap rows G8/G12 reworded to 🚧 Partial — both are data-layer helpers with smokes; no HUD, menu or battle code calls them yet.

### Added (2026-10-08, T58 G8 Citadel prestige tiers & campaign progress)

- **G8:** Enhanced `Progression` (`game/scripts/data/progression.gd`) with historical coastal fortress defense prestige tiers (Rank 0: Coastal Beacon / 烽火台 up to Rank 5: Imperial Coastal Stronghold / 海防总要塞), dynamic `get_prestige_tier` and `get_next_prestige_tier` (progress ratio & remaining prestige to next citadel rank), campaign-wide `total_stars()` aggregation across multiple levels, level completion status queries (`is_level_completed`, `is_level_perfected`), level summary dictionaries, and `reset_progression()`. Extended `game/tests/progression_smoke.gd` covering tier thresholds, ratio calculations, multi-level star aggregation, and clean reset. Headless smoke verified PASS in Godot 4.7.

### Added (2026-10-08, T57 G12 cross-front support units & catalog smoke)

- **G12:** Enhanced `UnitDefs` (`game/scripts/data/unit_defs.gd`) with structured helpers: `get_currency`, `get_cost`, `can_afford` for environment-locked resources (verifying land vs sea currency locking), `get_units_for_front`, `get_cross_support_units`, `get_defender_units`, `get_hero_units`, and `get_effective_damage` factoring in cross-environment multiplier logic (Signal Battery: 0.55x against the front it stands on, 1.15x against the other). Added complete schema and bounds checking via `UnitDefs.validate_catalog()`. Shipped new headless `game/tests/unit_catalog_smoke.gd` asserting full roster completeness, environment currency gating, effective cross-front calculations, and unknown ID guards (`has_def`). Smoke verified PASS headlessly in Godot 4.7.

### Added (2026-10-08, T44 P7 tick-budget benchmark)

- **P7:** new headless `game/tests/perf_budget_bench.gd` (deliberately not `*_smoke.gd`, so CI never gates on timing) plus `scripts/run_perf_bench.sh`: loads `slice0_dual_front.json` through the public `SimulationCore` API, sustains 10/20/40/60-entity dual-front combat loads, and reports min/median/p95/p99/max tick us with entity counts. Budget: p95@40 ≤ 8000 us (~1/4 of a 30 FPS frame); PASS/WARN exit 0, FAIL only past 3x budget; hard FAIL if the native extension is absent. Desktop baseline (i9-12900HX, x86-64): p95@40 = 1 us, PASS ×3 reviewer runs after the sustained-combat fix. Untimed per-front damage/movement checks and a tail probe reject no-op ticks and targets leaving range. Numbers and caveats in `docs/BENCHMARKS.md`. P7 → 🚧 Partial (on-device runs still open).

### Added (2026-10-08, T41 C1 dual-front state schema document)

- **C1:** New reference doc [`docs/design/dual_front_state_schema.md`](../design/dual_front_state_schema.md). Part 1 inventories every `SimWorld` field by land-only / sea-only / shared / cross-front with C++ type, `file:line`, FlatBuffers-snapshot coverage, units, and mutators, plus the level-JSON → runtime mapping and save/load flow. Real findings called out: the S4 snapshot does not persist the flow-field grids (`land_flow_`/`sea_flow_`/`grid_size_`), `Raider.entry_row`, or the DT1/DT2 cheat flags, and `game/src/level-schema.json` is stale relative to the dual-front level JSONs (the catalog only checks the first wave for `landCount`/`seaCount`). Part 2 is a clearly labeled, not-implemented proposal for the C2 land/sea authority split and minimal per-tick delta. Review corrections clarify GDScript gameplay authority, incomplete placement/flow restoration, numeric guards and snapshot version handling. Documentation only — no code, schema, or JSON changed.

### Fixed (2026-10-08, T45 re-review of T40)

- Touch smoke now routes desktop and emulated mouse press/release through the viewport, covering GUI dispatch rather than invoking grid handlers directly. Guard absent optional unit-selection InputMap actions during unhandled input; the existing physical-key 5 fallback remains available. G10 GUI routing verified headlessly; IOS2 remains Partial pending device testing.

### Fixed (2026-10-08, T40 HOLD follow-up)

- Touch placement no longer starts in `_input` ahead of the GUI: a press that hits any interactive Control (HUD, pause/modal overlay, dev overlay) goes to that Control only. Grid click layers use `MOUSE_FILTER_PASS` so ScreenTouch can reach `_unhandled_input` after GUI miss; in-progress drags stay on BattleRoot so a finger can still cross both grids. Smoke covers an injected STOP button over a cell and a tap while paused. IOS2 remains Partial; no device verification.

### Fixed (2026-10-08, T45 review of T40)

- Touch releases outside both grids now cancel even below the drag threshold; the preview follows the cell a sub-threshold tap will commit. Preview validity accounts for unit front, resources, hero uniqueness, and redeploy travel state. Touch smoke now dispatches touch/drag through the viewport and covers these boundary/affordability/front cases and OS cancellation; regressions fail against the original implementation.
- **G10 HOLD (touch before GUI) resolved in the follow-up above.** IOS2 remains Partial; no device verification.

### Changed (2026-10-08, T40 G10/IOS2 touch placement)

- **G10:** Modular dual-grid placement follows real `InputEventScreenTouch` / `InputEventScreenDrag` (hold preview, drag threshold, commit on release, off-grid cancel, second finger ignored). New presses wait until after GUI hit-testing so overlapping HUD/modal Controls consume the finger; emulated mouse-from-touch is swallowed during an active gesture so a finger cannot double-place; desktop left-click still places on press. Valid vs invalid preview uses fill+plus vs outline+X, not colour alone. Smoke: `touch_placement_smoke.gd`.
- **IOS2:** Shared Godot touch path is the iPhone/iPad control layer, but this was not device-tested on iOS — row stays Partial.

### Added (2026-10-08, T42 Q2 CI runs every headless Godot smoke)

- **Q2:** `scripts/run_godot_smokes.sh` auto-discovers every `game/tests/*_smoke.gd` (new smokes need no runner/CI edits), does the one-off `--import` pass, and runs each headless with a per-smoke timeout (`SMOKE_TIMEOUT`, default 120s). A smoke fails on non-zero exit or on Godot failure text in its output (`SCRIPT ERROR`, `Parse Error`, a printed `FAIL`) even at exit 0; commented `SKIP_LIST` carries per-entry reasons (currently empty — all 19 smokes run). Reviewer hardening: import failures also fail the gate (exit 134 gets one checked retry; error text from either attempt still fails), timeouts force termination after a five-second grace period, and runner regression tests exercise failure detection in CI. Per-smoke PASS/FAIL table + combined log; non-zero exit if any failed; subset args and `GODOT` env override supported. Local runner: `just test::godot-smokes [names]` (see `docs/TESTING.md`). The `godot-game.yml` smoke job now runs all smokes (was `simulation_smoke.gd` only), also triggers on `scripts/run_godot_smokes.sh` changes, and uploads `godot-smokes.log` as an artifact on failure; Godot stays pinned at 4.7.1 and the native CMake/`ctest` job is unchanged.

### Added (2026-10-08, T43 ID8 interactive dual-front demo)

- **ID8:** New `/dashboard/demo` route — interactive dual-front placement-and-raid mini-game. Pure deterministic TypeScript sim (`src/simulations/dualFrontDemo.ts`) with fixed timestep, injectable config, no `Math.random`. React view (`DualFrontDemoView.tsx`) with two grids (land + sea), unit palette, budget tracking, keyboard-accessible cells, `prefers-reduced-motion` support, and clear win/lose states. Roster names, costs, HP and damage follow `game/scripts/data/unit_defs.gd`; ranges and tick-based cooldowns are simplified for the toy. Review fixed interleaved front spawning, path-only raider rendering, focus/selection colors, reduced-motion transitions and narrow-screen cell sizing. Vitest: 63/63 tests (baseline 27; includes 23 sim and 12 view tests with actual placement/run/reset interactions). Lint: 0 errors, 12 pre-existing warnings. Review also corrected the pre-existing invalid `highlight.js/lib/game` import to `lib/core` and connected its published types. Full `npm run build` (TypeDoc/Astro/Storybook/Vite/postbuild), `tsc --noEmit`, and island budgets pass. Main JS gzip grows 418.37 → 422.75 kB (1.05%, baseline measured with the same import correction); Aurelia is 66.1 kB against its 300 kB budget.

### Added (2026-10-08, T38 A4 heuristic DDA baseline)

- **A4:** Rule-based difficulty director inside `SimWorld`, off by default. Intensity is clamped to 0.75–1.25 from HQ fraction, outposts lost, previous-wave clear time, and unspent currency versus the run's starting purse. It scales only the count and HP of waves that have not spawned (authored delays, speed, and damage stay put). `SimulationCore.set_dda_enabled` / `dda_enabled` / `get_dda_intensity`. `GameSession.dda_enabled` plus `apply_dda(sim)` is the session toggle; modular battle does not call it yet, and the DT5 overlay does not show intensity yet. On load, the clear-time sample resets and the purse baseline rebases to loaded currency; the enable flag stays on the receiving object (schema unchanged). Resumed DDA decisions can differ from uninterrupted play. No RNG. Tests: `sim_world_test.cpp` A4 cases, `dda_smoke.gd`. T45 review hardens combined-purse arithmetic for large valid balances and smoke failure reporting for missing spawns.

### Added (2026-10-08, T39 U8 accessibility primitives — re-review HOLD)

- Main menu and settings controls use a named 48-unit logical-canvas minimum and native AccessKit metadata. **48dp-equivalent mobile targets remain unresolved:** canvas stretching shrinks controls in phone-sized windows; fixed-width content clips at direct phone-sized logical viewports. Popup item targets and platform screen readers remain unverified.
- Persisted `large_text` (1.15x) through the backward-compatible `OfflinePersistence` settings path. The compacted settings panel and container-safe fade fix the original 1280×720 clipping; the relocated version label no longer overlaps Quit at that size. This is not responsive reflow.
- Four-way modal focus containment, host button isolation, slider lateral adjustment, and opener focus restoration verified. Re-review limits focus restoration to buttons so static labels remain unfocusable.
- Button normal/hover/pressed text and focus styles, checkbox text, and version-label contrast corrected. Re-review smoke checks instantiated screen controls, rather than only styling isolated helper objects.
- Regression checks cover persistence, focus membership, post-animation geometry in 1280×720, 720×1280, 390×844, and 844×390 **windows with project stretching enabled**. A 720×1280 window actually has a 1280×2275 logical canvas; window-fit checks do not establish mobile touch-target compliance.
- Re-review restored unrelated U7 roadmap row accidentally removed in the follow-up. U8 stays partial/on HOLD for mobile layout and target sizing; in-battle HUD remains out of scope.

### Changed (2026-08-15, T37 DT6 overlay level picker)

- **DT6:** DT8 overlay `LevelPickSelect` lists `LevelCatalog` dual-front JSONs. **Load level** sets `GameSession.selected_level_path` and calls `BattleRoot.debug_load_level` (in-place reset to that JSON's build/waves/兩). Wave jump stays DT3. Smoke: `level_picker_smoke.gd`.

### Changed (2026-08-15, T35 G5 second dual-front level)

- **G5:** `night_tide_dual_front.json` — same schema as `slice0_dual_front`, sea-heavy night raid (28s build, 5 waves, 32/28 兩, HQ 90). `LevelCatalog` skips leftover `level_01.json`. `GameSession.selected_level_path` + main-menu `LevelSelect`; `BattleRoot` loads the selected JSON and tags `level_id` on `end_run`. Unblocks DT6 (picker not in this slice). Smoke: `level_catalog_smoke.gd`.

### Added (2026-08-15, T36 U9 Environmental Tile Variety & Art Polish Completion)

- **U9:** Extended `game/assets/iso_tiles.png` to a 6-tile terrain atlas (coast, deep ocean, road path, tidal marsh, ocean shoals, and elevation bastion) with custom ukiyo-e wave foam & masonry textures; wired `grid_front.gd` environmental tile variety mapping, outpost bastion perimeter zone highlights, and procedural ukiyo-e wave foam / elevation vector contours using `_draw()`. Completes sub-passes 1, 2, and 3 for U9 art & asset polish. Smoke: `unit_token_smoke.gd`.

### Changed (2026-08-15, T34 DT7 playtest session log + dashboard sync)

- **DT7:** `PlaytestLog` writes `user://playtest_sessions.json`. Overlay `[📝 Mark Session Event]` timestamps marks (tester field); `end_run` logs only if a session is already open. **Sync to Dashboard** merges into `docs/website/public/dashboard-data/playtest_sessions.json` in the existing `PlaytestNotesView` shape (events folded into `notes`). No checkout / mobile: export + `scripts/sync_playtest_session.sh <file>`. Event-triggered, not telemetry. Smoke: `playtest_log_smoke.gd`.

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

- **VS4 build-phase upgrade:** `SimulationCore::upgrade_defender` (C++) boosts a placed defender's damage (+25%) and range (+12px) while it isn't traveling; bound to the new `upgrade_unit` Godot input action (`U` key) and exposed via `get_defenders()`'s `damage` field; covered by a new case in `game/tests/simulation_smoke.gd`. Strengthens VS-A4 (build/position/upgrade phase).
- **T8 GitHub issue hygiene, verified:** re-checked the 2026-08-11 hygiene plan live via `gh` against `Hyperion-Corporation/Project-Mobile-Fortress` — all 10 title edits and epics/research issues #128–#133 confirmed present. Filled in the plan's short status comments that had not actually posted (#33, #46, #70) and corrected a template-substitution bug in #9's comment (posted a follow-up rather than editing the original). See `.agent/cache/AGENT_BUS.md` (T8 log entry) for detail.

### Changed (2026-08-11, Slice-0 implementation + issue hygiene)

- Godot dual-front prototype playable: classic `game/main.gd` and modular `game/scenes/battle/` over `SimulationCore` GDExtension (raiders, defenders, outposts).
- Headless smokes: `game/tests/{simulation,gameplay,modular_battle,flatbuffers,game_session,offline_persistence,main_menu}_smoke.gd`.
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
- Added multi-framework platform roadmap [`docs/moon/roadmaps/multi_framework_platform.md`](https://github.com/Hyperion-Corporation/Project-Mobile-Fortress/blob/3727c58f5d7e5298042c27f13a20afe048fd9349/docs/moon/roadmaps/multi_framework_platform.md) (MFP1–MFP16) for Vue-host + React/Astro/Aurelia islands, GraphQL/Apollo, and WASM on the docs site, grounded in hybrid Vue/React and WASM research. (That file was later renamed into [`roadmaps/internal_dashboard.md`](roadmaps/internal_dashboard.md) Part B.)
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
- Merged the interactive design-hub website (formerly `docs/design/website/`) and the documentation portal (formerly `docs/public/`) into a single `docs/website/`. Initially rewritten as a no-bundler CDN/global-build Vue 3 SPA, then superseded by a proper **Vite + Vue 3 + TypeScript** project at `docs/website/` (mirroring the architecture used by this org's other repos, e.g. Image-Toolkit's `docs/website/`): `scripts/generate-nav.mjs` derives the site's nav from `docs/mkdocs.yml`'s `nav:` tree plus a curated list of repo-wide guides that live outside `docs/` (README, CONTRIBUTING, infra runbooks, `game/`, research/reports), and every Markdown source is bundled at build time via `import.meta.glob` (`src/composables/useDocs.ts`) — no runtime content mirror needed. Pages render with `markdown-it` + `markdown-it-anchor` + `markdown-it-texmath`/KaTeX + `highlight.js`, with Mermaid diagrams rendered live, a searchable sidebar (⌘K), per-page TOC, prev/next navigation, and an "Edit on GitHub" link. The design-hub tabs (Flow Field simulator, GA wall-layout visualizer, dynamic-audio mixer, sprint roadmap, QA net-sync dashboard) are proper Vue SFCs under `src/components/hub/` with real reactive state, computed properties, and `v-model` bindings. Also adds `docs/{TROUBLESHOOTING,DEPENDENCY_POLICY,DOCUMENTATION_STANDARDS,BENCHMARKS}.md`, matching this org's other repos' documentation set.
- Reworked `.github/workflows/docs.yml` to build `docs/website` (`npm ci && npm run build`) and publish its `dist/` output to a `gh-pages` branch via `peaceiris/actions-gh-pages`, instead of GitHub's managed Pages artifact/OIDC deploy or a runtime content-mirror step. `docs/mkdocs.yml` (excluding `website/` via `exclude_docs`) remains available for local browsing via `mkdocs serve`, sharing its `nav:` tree as the Vue site's source of truth. Trigger/permissions structure follows this org's `WSmart-Route` convention: `workflow_dispatch` takes a `reason` input, the `push` trigger runs on every push to `main` (no path filter — the site's nav also covers repo-wide guides outside `docs/`, e.g. `README.md`, `game/README.md`, infra runbooks), and `permissions: contents: write` is scoped to the `build-and-deploy` job rather than the whole workflow.
- Moved `reports/` → `docs/reports/` and `research/` → `docs/research/` so every design/reference document lives under `docs/`; added a **Research** section to `docs/mkdocs.yml`'s `nav:` (picked up automatically by `docs/website`) and removed the now-redundant `Research` entry from `generate-nav.mjs`'s `EXTRA_SECTIONS`. Fixed all cross-references across `README.md`, `.agent/AGENTS.md`, every `docs/moon/roadmaps/*.md`, `docs/DEPENDENCY_POLICY.md`, `docs/BENCHMARKS.md`, and `docs/website/README.md`.
- Restructured the Gradle build to a **repo-root workspace**: moved `gradlew`, `gradlew.bat`, `gradle/` (wrapper + `libs.versions.toml`), `gradle.properties`, and `settings.gradle.kts` from `android/` to the repo root, and moved `android/build.gradle.kts` to a new root `build.gradle.kts`. `settings.gradle.kts` maps `:app` to `android/app/` via an explicit `projectDir` override, so `./gradlew <task>` now works from anywhere in the repo without `cd android/` or `-p android`. Updated every CI workflow (`.github`, `.forgejo`, `.gitea`, `.gitlab`), `.pre-commit-config.yaml`, `.devcontainer/devcontainer.json`, all `tools/*/justfile` recipes, and the relevant docs (`AGENTS.md`, `TROUBLESHOOTING.md`, `DEVELOPMENT.md`, `DEPENDENCY_POLICY.md`, `TESTING.md`, `.agent/rules/kotlin.md`, `.agent/skills/*.md`) accordingly — local `local.properties` now lives at the repo root too (`android/local.properties` is no longer read). Verified with `./gradlew ktlintCheck`/`./gradlew projects` under JDK 21.
- Added a root `package.json` declaring **npm workspaces** (`docs/website`), with `site:dev`/`site:build`/`site:preview`/`site:nav` convenience scripts — `docs/website`'s `package-lock.json` was removed in favor of one root-level lockfile (npm workspaces hoist `node_modules` to the root). Updated `.github/workflows/docs.yml` to `npm ci` at the root and `npm run build --workspace docs/website`, and added an `npm` entry to `.github/dependabot.yml` (directory `/`) alongside the existing `gradle` entry (also repointed from `/android` to `/`).
- Added a root `pyproject.toml` pinning `mkdocs-material` (this repo has no Python application code) — `pip install .` now reproducibly installs the local `mkdocs serve` dependency instead of the previous ad-hoc `pip install mkdocs-material`.
- Rewrote `README.md`'s Quick Start section so every command runs from the repo root without `cd`-ing into a subdirectory first (`./gradlew`, `npm run <script> -w docs/website`, `pip install . && mkdocs serve`), and updated the Repository Layout tree/table to reflect the new root-level workspace files.
- **Switched the planned shared simulation core from Rust to C++20**, matching this org's `base/`-module convention (see Image-Toolkit's `base/` for precedent): ECS via [EnTT](https://github.com/skypjack/entt) (was `hecs`), zero-copy state serialization via [FlatBuffers](https://flatbuffers.dev/) (was `rkyv`), and a hand-written C ABI shim bound via JNI (Android) and Swift's native C++ interop / an Objective-C++ fallback (iOS) in place of UniFFI's automated Rust bindings generator — no C++ equivalent of UniFFI's maturity exists, so the FFI surface is kept intentionally small and hand-reviewed. Dependency management moves to CMake + vcpkg (manifest mode) in place of Cargo, and `criterion` micro-benchmarks become Google Benchmark. Added a "Trade-offs vs. a Rust core" section to `docs/moon/roadmaps/shared_core.md` documenting the safety properties lost without a borrow checker (no data races/use-after-free guarantees) and the mandatory mitigations (RAII discipline, ASan/UBSan/TSan in CI, `clang-tidy` as a required gate) — this is a real engineering trade-off, not a cosmetic rename. Updated every design doc (`game_design_document.md`, `technical_design_document.md`, `production_roadmap.md`, `pitch_deck.md`, `qa_test_plan.md`), every roadmap referencing the core (`shared_core.md`, `performance.md`, `backend.md`, `ai_systems.md`, `qa_testing.md`, `ios.md`), `docs/ARCHITECTURE.md`, `docs/GLOSSARY.md`, `docs/DEPENDENCY_POLICY.md`, `docs/BENCHMARKS.md`, `docs/DOCUMENTATION_STANDARDS.md`, `README.md`, `.agent/AGENTS.md`, `.agent/prompts/master_context.md`, `game/README.md`, and the `docs/website` design-hub content (`TechPanel.vue`, `ProductionPanel.vue`, `QaPanel.vue`, `HomeView.vue`, plus `useMarkdown.ts`'s registered `highlight.js` languages: `cpp`/`cmake` in place of `rust`). Left the original Rust/UniFFI research and rationale intact in `docs/moon/research/Multiplayer Tower Defense Implementation.md` and in already-shipped `docs/moon/CHANGELOG.md` history as the frozen record of what was originally researched — `shared_core.md` now explains why C++ was chosen instead.
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
