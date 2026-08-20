# Mobile Fortress — Claude Initial Analysis & Feedback

**Date:** 2026-08-09
**Author:** Claude (Claude Code)
**Status:** Initial read-through, pre-brainstorm. Not a final roadmap proposal — see closing questions to the owner before that follows.
**Scope reviewed:** `docs/moon/ROADMAP.md` + all `docs/moon/roadmaps/*.md`, `docs/moon/research/*`, `docs/moon/reports/Tower Defense Market Research.md`, `.agent/AGENTS.md`, `game/`, `android/`, `ios/` source trees, `docs/website/APP.md`, `infra/`, and all 100 GitHub issues (`gh issue list`).

---

## 1. What this repository actually is today

Strip away the docs and the honest state is: **two native "hello world" game skeletons and an extraordinarily well-developed planning apparatus.** Android's `engine/` is a bouncing `Ball` demo entity. iOS's `Scenes/` is a generic top-down shooter (`PlayerNode`/`EnemyNode`/`BulletNode`). Neither implements a single frame of Wōkòu-era tower-defense gameplay — no grid, no lanes, no towers, no HQ, no Flow Field. `game/` is assets + a markdown spec, not compiled code. `infra/` is scaffolding for a backend that doesn't exist yet. This is stated candidly in `.agent/AGENTS.md` §7 — the project is self-aware about this, which is good — but it's worth naming plainly as the starting condition for everything below.

Meanwhile the roadmap/issue surface is huge and mature: 11 topic roadmaps, ~100 GitHub issues, two lengthy research documents (market research + a multiplayer-TD technical implementation report), and a fully worked-out C++/ECS/GameLift/gacha/RL architecture. The documentation-to-code ratio is unusually large even for an early-stage project.

## 2. Pros

- **The core concept is genuinely differentiated.** A Wōkòu-era East-Asian-vs-Western coastal-defense setting with dual land/sea fronts is not represented in the current TD/4X charts (per your own market research doc), and it isn't a costume-swap of an existing IP — it has real historical texture (Ming coastal garrisons, Fo-lang-ji cannon, rōnin/pirate-smuggler raiders, Portuguese/Iberian trade presence) to draw on for units, lore, and art direction.
- **The documentation quality is genuinely high**, not cargo-culted. Every roadmap item cites the market-research or technical-implementation doc section that justifies it. The `shared_core.md` C++-vs-Rust decision doc, in particular, is a real engineering trade-off writeup (RAII discipline, sanitizer requirements, `clang-tidy` gates) rather than a hand-wave.
- **The scaffolding choices are sound and appropriately boring.** `SurfaceView`+Canvas / SpriteKit for the 2D game surface, Compose/SwiftUI only for chrome outside the render loop, is the right call for a 2D mobile TD game — you correctly avoided pulling in a full engine (Godot/Unity) or a declarative-UI-for-everything approach that would fight frame-budget discipline. ADRs exist for this (`docs/adr/0002`, `0003`).
- **The repo-automation and multi-agent tooling (`.agent/`, `git/`) is unusually disciplined** for a solo/small-team project — commit-linked board sync, severity-tiered AI review protocol, module-boundary rules. This will pay off once actual gameplay code starts landing at volume.
- **The regulatory awareness in monetization planning is ahead of the curve** — Kompu-Gacha-compliant disclosure "from day one" (M2) rather than bolted on after a regulator notice is the right posture, and cheap to keep.
- **The docs website (`docs/website/`) is a legitimately interesting, functioning artifact in its own right** — real Apollo/GraphQL, real Aurelia island, real Astro island, budget-gated, tested. It's not vaporware; it's the most "finished" subsystem in the repo.

## 3. Cons / risks

### 3.1 Sequencing risk: the plan is architected far ahead of a validated fun loop

Phases 2–7 (shared C++ core, gacha/monetization, GameLift multiplayer, WFC/RL/CMAB ML, LiveOps, compliance) are all planned in detail before Phase 1 — a single-player MVP core loop — has a single tower placed on a single lane. This is the single biggest risk in the plan. Tower defense is a genre where the core loop's feel (pacing, readability of threat, tower-vs-lane tension, the day/night rhythm you've designed in G6) is not knowable from a design doc; it has to be played. Investing further roadmap depth into gacha psychology (UTAUT3), GameLift fleet cost-tuning, or TGNN churn models before you know the core loop is fun is the classic "pre-production forever" trap.

**Recommendation:** Freeze net-new roadmap depth on Phases 3–7 and put the next unit of work entirely into G2/G3/G10 (grid core loop + Flow Field + touch input) as a *playable, ugly, single-lane vertical slice* — placeholder rectangles for towers/enemies, no art, no meta-progression — that you can actually play in under two weeks. Everything else in this document assumes that slice exists soon.

### 3.2 The C++ shared core is the wrong default given where the project actually is

`shared_core.md` argues C++ over Rust/UniFFI on **organizational consistency** grounds ("this org standardizes on C++... one systems language across projects"), explicitly trading away Rust's compile-time memory/thread-safety guarantees for that consistency, and then spends a third of the document on mitigations (ASan/UBSan/TSan in CI, mandatory RAII discipline, `clang-tidy` gates) to manually re-earn safety properties Rust would give for free. For a small team (or solo + LLM agents) writing new netcode/ECS/FFI-boundary code from scratch, that's a lot of self-imposed discipline burden to take on for a cross-project-consistency argument, on a project where nothing else currently forces C++.

You told me not to be constrained by the current stack, so I'll say plainly: **if I were deciding this fresh, I'd pick Rust + UniFFI**, specifically because the highest-risk part of this exact plan is the JNI/Swift-C++-interop FFI boundary carrying concurrent simulation state for Co-Op netcode — precisely the class of bug (data races, use-after-free across FFI, lifetime bugs in the async bridge, called out by your own S6 item as "higher risk than a typical async-bridging task") that Rust's borrow checker and `Send`/`Sync` catch at compile time instead of in a sanitizer run after the fact. UniFFI also generates the Kotlin/Swift bindings for you, which is real schedule time saved versus hand-writing and hand-reviewing a C ABI shim per platform.

That said — the org-consistency argument isn't nothing if you're actually planning to share engineers/tooling with Image-Toolkit's `base/` module. Whether to reverse this decision is a real product/org call, not a pure technical one, which is why it's in my questions below rather than something I'll just flip.

### 3.3 Roadmap/issue drift is already happening, and the automation meant to prevent it has a known gap

I found concrete drift, not hypothetical risk:
- **All shared-core issues (S1–S7) and several performance issues (P2, P5) still say Rust/`hecs`/UniFFI/`rkyv`**, while `docs/moon/roadmaps/shared_core.md` and `ROADMAP.md` were switched to C++/EnTT/JNI three commits ago (`6f4bab8`, "Switch planned shared simulation core from Rust to C++20"). iOS issue IOS3 still says "Consume shared Rust core via UniFFI Swift bindings."
- **Issue B4 says "GCP Firebase fleet provisioning"; `backend.md` says AWS GameLift + FlexMatch.** These aren't the same decision restated differently — they're different clouds and different matchmaking products.

`repo_automation.md` (RA1–RA4) already diagnoses half of this problem (RA4, the deterministic non-LLM sync mode, is explicitly deferred) but the *existing* Gemini-driven sync apparently only reconciles **status** (open/closed, board column), not **content** (title/body text) — otherwise these wouldn't still say Rust. That's worth fixing before the issue count grows further; 100 issues with silent content drift is a maintenance trap, especially once actual contributors (human or agent) start reading the issue instead of the roadmap file as their source of truth.

### 3.4 The ML/optimization ambitions are sound in principle but currently unordered by risk/leverage

`ai_systems.md`'s A1–A10 (WFC+MILP map generation, two-agent imitation+adversarial-RL difficulty, TGNN churn detection, CMAB offers) are correctly marked "not MVP," which is good discipline. But there's no stated *evaluation gate* for any of them — no "A5 (RL DDA) doesn't start until we have telemetry showing rule-based DDA (A4) actually fails to hold players in a flow channel." Given your own stated appetite (RL/ML/optimization researcher, want to leverage that here — inferred from your framing of this task, not yet confirmed, see questions), the risk isn't that these are bad ideas; it's that without named entry gates they'll get built because they're interesting to build, not because a measured failure class demands them. This is exactly the failure mode your sibling project's admin report (ASP) already caught and corrected for ("RL/evolutionary/generative work should be bounded by a named failure class and human-calibrated evaluation") — worth importing that discipline here proactively rather than rediscovering it.

### 3.5 The monetization/multiplayer/ML breadth may be premature relative to team size

Nothing in the repo states team size, but the roadmap assumes sustained parallel work across: two native game clients, a C++ simulation core, a server-authoritative netcode stack, AWS infrastructure, a gacha economy with regulatory compliance, and multiple ML/RL systems. Any one of these is a multi-month specialty. If this is primarily a solo project (with LLM agent assistance), the roadmap's *breadth* is its biggest scope risk, independent of any individual item's merit.

### 3.6 The dashboard/telemetry initiative (issues #120–125) has no roadmap doc

You described (in this task's brief) a developer-facing dashboard for telemetry, monetization metrics, lore/product tracking, and review/social scraping, with 3D/zoomable-map visualization — and there's already a `product-metrics` GitHub label with 6 open issues (#120–125) scoping exactly this, including one explicitly rejecting real-time WebSocket streaming "for now." But there's no `docs/moon/roadmaps/*.md` file for it — it exists only as issues, orphaned from the roadmap index. That's a gap to close either way this initiative proceeds.

## 4. What to keep, and why

- **The C++/Rust *decision structure* itself** (a dedicated roadmap doc naming the alternatives and trade-offs explicitly) — regardless of which language wins, this is the right way to record an architecture decision. Keep the doc shape even if §3.2's recommendation changes its content.
- **The MVP-gating discipline in `ai_systems.md`** ("not MVP, should not block launch") — correct instinct, just needs entry gates added (§3.4).
- **The regulatory-first monetization posture (M2).**
- **The `.agent/` automation and severity-tiered review protocol** — this is infrastructure that compounds in value as code volume grows; don't let it atrophy while gameplay work ramps up.
- **The historical-setting specificity.** Resist any temptation to genericize the setting for broader appeal — the market research's whole thesis is that specificity is the gap in the market.
- **The docs-website multi-framework work as a *technical showcase*, but see the question below about whether it's the right thing to keep expanding right now** (§5 avenues).

## 5. What to change — avenues

### 5.1 Sequencing: gate everything on a playable slice

**Avenue A (recommended):** Declare a "Playable Vertical Slice" milestone that is *only* G2 + G3 (or a naive per-unit A\* if Flow Field is too much upfront) + G10, single lane, placeholder art, one enemy type, one tower type, defend-the-HQ win/lose condition. Freeze roadmap grooming on Phases 3–7 until it exists and has been played (by you, ideally by 2–3 outside people). Everything downstream (meta-progression, monetization, multiplayer, ML) gets re-evaluated against what the slice actually teaches you about pacing.
**Avenue B:** Timebox instead of gate — e.g. "two more weeks of roadmap/infra work is fine, but by date X the vertical slice must exist regardless of what's unfinished elsewhere." Lower discipline than A but may fit better if you're using idle time on planning while blocked on something else (e.g. waiting on art).
**Avenue C:** Reject gating — if the planning work is itself the enjoyable/valuable part of this project for you right now (a legitimate reason to keep going), say so explicitly and I'll stop flagging it as risk in future passes, but I'd still recommend at least a throwaway paper-prototype (physical or a spreadsheet sim of wave math) to sanity-check pacing before Phase 2 architecture gets more concrete.

### 5.2 Shared core language

**Avenue A:** Reverse to Rust + UniFFI per §3.2's reasoning — rewrite `shared_core.md` back, but keep the *trade-offs section structure* (now framing what's lost by leaving C++/org-consistency behind instead).
**Avenue B:** Keep C++, but change the mitigation story from "manual discipline + sanitizers" to a stricter subset — e.g. mandate `Result`/`expected`-style error handling and forbid raw pointers/manual `new` anywhere in `game/` via a custom `clang-tidy` ruleset enforced pre-merge, not just CI-detected after the fact. Doesn't recover compile-time guarantees but tightens the gap.
**Avenue C:** Defer the decision entirely — this only matters once G2/G3 exist on both platforms and Co-Op multiplayer (Phase 4) is imminent; per §5.1 that's a long way off. Keep `game/` documentation-only until the vertical slice is played, then decide with actual netcode-latency requirements in hand instead of speculatively.

### 5.3 Issue/roadmap drift

**Avenue A:** Bulk-correct the 9 stale issues now (S1–S7, P2, P5, IOS3, and B4) via `gh issue edit`, then extend RA1's Gemini sync (or write a small deterministic script per RA4, scoped down to just "diff issue body against roadmap row text, flag mismatches") to catch this going forward — even a weekly CI job that diffs issue bodies against `docs/moon/roadmaps/*.md` and files a meta-issue on mismatch would close this gap without waiting for full RA4.
**Avenue B:** Stop maintaining GitHub issues as a parallel copy of roadmap content at all — issues become thin pointers ("see `gameplay.md#G2`") with no restated implementation detail, so there's nothing to drift. Loses per-issue GitHub-native features (assignees, project-board automation reading issue body) but removes the sync problem structurally.

### 5.4 ML/RL entry gates

**Avenue A:** Add a "Research entry gate" column (or short subsection) to `ai_systems.md` for A5–A10 naming: the specific failure class each system addresses, the baseline it must beat, and the telemetry/evidence required before implementation starts — mirroring the pattern already validated in your ASP project's admin report.
**Avenue B:** Split `ai_systems.md` into a committed-phase list (A1, A4, A9 — WFC, rule-based DDA, churn survival analysis: all bounded, well-precedented techniques) and a `research_backlog.md` for the higher-risk items (A5, A6, A7, A10), so the roadmap index itself signals which are scheduled work vs. hypotheses awaiting evidence.

### 5.5 Dashboard/telemetry initiative

**Avenue A:** Promote issues #120–125 into a new `docs/moon/roadmaps/product_metrics.md` (or `telemetry_dashboard.md`) roadmap file now, folding in your fuller brief (3D/zoomable map + lore-on-zoom, review/social scraping, personalization signals) as new deliverable rows — this is a natural site for the extended dashboard/ML-personalization vision described in this task's brief, and it already has a `product-metrics` GH label and issue numbers to link against.
**Avenue B:** Treat it as a `multi_framework_platform.md` extension instead (since it's a `docs/website` surface, same host/island architecture) rather than a wholly separate roadmap — less roadmap-file sprawl, but mixes "docs site interop demo" scope with "real product telemetry" scope in one document, which §3.6's own reasoning for keeping `repo_automation.md` separate argues against.

---

## 6. Closing note

None of the above should read as "the plan is bad" — it's unusually rigorous for this stage of a project, and the market thesis is genuinely good. The core tension is simply: **the planning has outpaced the proof.** My strongest single recommendation is §5.1 Avenue A — everything else in this document (including whether C++ or Rust is right) gets easier to decide correctly once a played vertical slice exists to test assumptions against, and harder to decide correctly the longer that's deferred.

See the questions posed directly to the owner in the chat session for the items I need your input on before finalizing this into roadmap/issue edits.
