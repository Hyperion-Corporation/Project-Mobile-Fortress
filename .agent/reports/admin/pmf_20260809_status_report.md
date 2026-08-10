# Mobile Fortress: Owner Status, Review, and Roadmap Decision Report

**Date opened:** 2026-08-09  
**Owner/editor:** ACFHarbinger  
**Repository under review:** `Project-Mobile-Fortress`  
**Document authority:** Owner-authored synthesis and decision record  
**Status:** Structure ready for owner fill — multi-agent analysis and brainstorming are pending  
**Purpose:** Reconcile the independent agent reports, repository evidence, roadmap documents, GitHub issues, owner decisions, and the final roadmap changes for Mobile Fortress.

## How to Use This Report

This is the owner's authoritative synthesis, not a replacement for the individual agent reports. Agents may add evidence, alternatives, and proposed wording, but must not silently convert a proposal into an owner decision.

Use these labels consistently:

- **DECIDED** — the owner selected the policy or outcome.
- **PROVISIONAL** — current direction pending evidence or prototype results.
- **OPEN** — a decision is still required.
- **REJECTED** — considered and explicitly declined, with a reason.
- **OBSERVED** — directly evidenced in the repository or GitHub.
- **AGENT CLAIM** — an agent conclusion not yet independently accepted.

### Filling order (recommended)

1. Review the executive summary and current implementation evidence.
2. Resolve the product and technical contract questions in §5.
3. Review the independent reports and record accept/qualify/reject decisions.
4. Decide the near-term vertical slice and release gates.
5. Record binding roadmap/issue changes.
6. Complete the final-pass checklist after all agents and the owner have edited this file.

### Contribution rules

1. Add material edits to the changelog at the end of this file.
2. Cite the report, roadmap, issue, code path, test, or owner decision supporting each claim.
3. Distinguish observed implementation facts from future proposals.
4. Record disagreement instead of manufacturing consensus.
5. The owner has final authority over product priorities and release decisions.

### Concurrent editing protocol

Multiple agents and the owner may edit this file concurrently:

1. Re-read the file immediately before every edit session.
2. Prefer append-only additions or clearly owned subsections.
3. Do not rewrite another contributor's section; add a response subsection when disagreeing.
4. Preserve owner edits and document collision repair in the changelog.

## 0. Owner Writing Brief

### 0.1 Questions that must be settled

| Decision area | Status | Owner decision / evidence |
| --- | --- | --- |
| Product identity and first shippable slice | `DECIDED` | Playable offline single-player Wōkòu-era vertical slice that shows promise to the owner and two collaborators. |
| Land/sea dual-front scope for MVP | `DECIDED` | Both land and sea are mandatory core identity; initial prototype is not land-only. |
| Co-op asymmetry and player roles | `DECIDED / PROVISIONAL` | Asymmetric land/sea co-op is a launch pillar, local Wi-Fi first, but networking is deferred from the initial prototype. Current preference is one player controlling both fronts with a shared perspective. |
| Shared-core language and integration strategy | `DECIDED / OPEN` | C++ is firm and Godot 4 is the client direction; Godot↔C++ boundary remains open. Server-authoritative replicated state is sufficient for online play. |
| Offline-first versus online-first delivery | `DECIDED` | Main campaign must work offline; online-only clans/raids/leaderboards may be unavailable offline. |
| Monetization policy and whether gacha is retained | `DECIDED` | Cosmetics first; skin lootboxes are acceptable; gameplay-impacting hero/unit gacha is rejected; rewarded ads only. |
| ML/optimization scope and safety/privacy limits | `DECIDED / PROVISIONAL` | RL DDA and swarm/evo pathing are important research; difficulty starts with hidden RL fine-tuning of baseline intensity. No telemetry after opt-out; offer graduated consent and opt-in anonymized social cohorts. |
| Website/dashboard scope and data-source policy | `DECIDED` | React website; developer-first dashboard, local/static or batch initially, live Docker deployment later. Reddit/X/App Store ingestion is later research, not core product. |

### 0.2 Immediate priorities

1. Build the Godot 4 dual-front offline prototype, starting with G2.
2. Define the playable Wōkòu-era Ming/Portuguese vertical slice and its land/sea loop.
3. Define the Godot↔C++ integration boundary and shared gameplay data contracts.
4. Reorganize roadmap items and GitHub issues into milestones, epics, and sub-issues after multi-agent consensus.
5. Keep the internal dashboard static/local until the prototype produces useful data.

## 1. Owner Executive Summary

### 1.1 Overall assessment

The repository has a substantial design, documentation, and tooling foundation,
but the first success criterion is still a playable game rather than additional
planning breadth. The near-term risk is scope: multiplayer, ML, LiveOps,
monetization, and the website can outgrow the small team before the dual-front
loop is validated. The next roadmap revision should therefore make the offline
vertical slice the sequencing anchor while retaining later systems as explicit
deferred work.

### 1.2 Product identity

Mobile Fortress is a historically grounded but accessible fictionalized
Wōkòu-era cooperative tower-defense game. Its non-disposable identity is the
land/sea interaction: distinct environments, same-front combat, cross-front
synergy, specialized support units, heroes/commanders, civilization strengths
and weaknesses, and resource choices.

### 1.3 Release definition

Release the first vertical slice to the owner and two collaborators for a
qualitative “shows promise” decision. It must run offline, include both fronts,
use isometric 2.5D presentation with ukiyo-e-readable placeholder art, target
10–40 units at 30+ FPS, and omit networked co-op, PvP, and live services from
the first prototype.

## 2. Review Inputs and Provenance

### 2.1 Independent agent reports

| Contributor | Report | Owner disposition |
| --- | --- | --- |
| Chat / Codex | `.agent/reports/chat/` | Initial post-Q&A report delivered. |
| Claude | `.agent/reports/claude/` | Review input; final owner disposition pending. |
| Gemini | `.agent/reports/gemini/` | Review input; final owner disposition pending. |
| Grok | `.agent/reports/grok/` | Post-Q&A decision input delivered. |
| Owner | Owner-authored additions | Answers captured in this report. |

### 2.2 Repository evidence

- `README.md`, `docs/ARCHITECTURE.md`, and `core/README.md`.
- `android/`, `ios/`, `core/`, `infra/`, and `docs/website/` implementation.
- `docs/moon/ROADMAP.md`, `docs/moon/roadmaps/`, research, design documents, and changelog.
- GitHub roadmap issues and product-metrics issues for `ACFHarbinger/Project-Mobile-Fortress`.
- Build, test, lint, and documentation-site verification results.

## 3. Shared Findings and Disagreements

| Finding / proposal | Verdict | Evidence and reasoning |
| --- | --- | --- |
| Current clients are functioning prototypes rather than the described game | `DECIDED` | The first deliverable is a new Godot offline prototype; inherited native skeletons are not the target product. |
| Deterministic shared simulation is valuable for cross-platform/co-op play | `PROVISIONAL` | A shared C++ simulation direction is retained, but strict deterministic lockstep is not required; server-authoritative replication is sufficient later. |
| The current C++ plan is preferable to the stale Rust GitHub issues | `DECIDED` | C++ is firm; stale Rust issues should be edited or replaced according to scope. |
| The product scope needs a smaller vertical slice before multiplayer/ML/LiveOps | `DECIDED` | Offline dual-front gameplay comes first; later systems remain deferred rather than removed. |
| ML should follow telemetry, baselines, and human-safety gates | `DECIDED` | Baseline intensity precedes hidden RL tuning; opt-out means no telemetry; sentiment-driven events begin as dashboard research with human approval. |
| Website multi-framework complexity is justified by a concrete user need | `PROVISIONAL` | React is current; dashboard work is secondary and local/static first. Retain other frameworks only if they serve a concrete output. |
| Gacha and personalized monetization fit the product values and launch risk | `MIXED` | Gameplay gacha is rejected. Cosmetic skin lootboxes and opt-in anonymized social personalization remain in scope with privacy safeguards. |

## 4. Current Implementation Review

### 4.1 Strengths to keep

Keep the Wōkòu-era dual-front design, the existing documentation/agent
discipline, the C++ direction, and the internal dashboard concept. Preserve
offline play as a first-class constraint and historical aesthetics as a visual
bar while using accessible fictionalization.

### 4.2 Weaknesses and risks to change

Replace the native SurfaceView/SpriteKit-first implementation assumption with
Godot 4 as the primary client direction; move implementation effort from broad
website/ML/backend scaffolding to the offline dual-front slice; and reconcile
stale Vue/Rust/native-client wording in documentation and issues.

### 4.3 Implementation alternatives

| Area | Option A | Option B | Option C | Recommendation / gate |
| --- | --- | --- | --- | --- |
| Simulation core | C++ | Rust | Kotlin/Swift/KMP | **C++ selected**; use `godot-cpp` plus native C++ modules, with exact boundary still open |
| Rendering | Native 2D | Shared engine | Full 3D engine | **Godot 4 selected**; isometric 2.5D first |
| Networking | Authoritative server | Lockstep | Turn/phase-based async | **Authoritative replication selected** for later online play |
| Analytics | Batch export | Managed telemetry | Self-hosted pipeline | **Static/local first**; Docker/live later |
| Website visualization | React-native | Web components/islands | Separate app | **React current**; avoid complexity without concrete need |

## 5. Product and Architecture Contract

| ID | Decision | Status | Rationale / constraints |
| --- | --- | --- | --- |
| C1 | First playable vertical slice | `DECIDED` | Offline dual-front isometric 2.5D prototype that shows promise to the owner and two collaborators. |
| C2 | Land/sea mechanics included in first slice | `DECIDED` | Both fronts, distinct resources/environments, cross-front synergy, heroes, and specialized units. |
| C3 | Co-op role split | `DECIDED / PROVISIONAL` | Asymmetric land/sea co-op is a launch pillar; local Wi-Fi first and networking later. Current preference is one player controlling both fronts. |
| C4 | Shared-core boundary and determinism model | `DECIDED / OPEN` | C++ firm; Godot client; server-authoritative replication later. Exact Godot↔C++ boundary remains open. We will use both godot-cpp and C++ modules to run C/C++ code. |
| C5 | Backend and hosting model | `DECIDED` | No remote backend needed for the first prototype; custom Docker/live dashboard later; cloud alternatives remain acceptable. |
| C6 | Privacy, consent, and player-data policy | `DECIDED` | No telemetry after opt-out; offer graduated options; social personalization is opt-in and cohort-based/anonymized. |
| C7 | Monetization and non-paying-player experience | `DECIDED` | Cosmetics first, battle pass later, skin lootboxes acceptable; no gameplay gacha; rewarded ads only. |
| C8 | Website/dashboard launch scope | `DECIDED` | Developer-first React dashboard, local/static or batch initially; live deployment later. |

## 6. Roadmap and GitHub Issue Decisions

### 6.1 Keep

Keep the single-player dual-front vertical slice, C++/Godot direction,
commanders/heroes, internal developer dashboard, clans as a launch concept,
and the core land/sea/resource/civilization identity.

### 6.2 Change or split

Reorganize roadmap rows into milestones, epics, and implementation sub-issues.
Replace or edit stale Rust-era issues with C++ equivalents, make the dual-front
offline slice the immediate dependency, and add future research issues for
sentiment-informed events without making them core launch automation.

### 6.3 Defer, archive, or remove

Defer co-op networking, PvP, settlement capture, live dashboards, RL/CMAB
automation, public-web ingestion, and broad LiveOps until the offline slice is
validated. Reject gameplay-impacting hero/unit gacha; retain cosmetic lootboxes
as a later option.

### 6.4 Synchronization defects to resolve

- Update issues that still describe Rust/`hecs`/`rkyv`/UniFFI after the C++/EnTT/FlatBuffers decision.
- Resolve backend provider terminology drift (AWS GameLift/FlexMatch versus GCP/Firebase issue wording).
- Reconcile the top-level roadmap's stale docs-platform summary with the React-host roadmap.
- Decide whether product metrics deserves its own roadmap and link issue #120's sub-work.

## 7. Validation and Release Gates

The first slice should build and run offline on the target platform path, contain
both fronts in one complete session, sustain the 10–40-unit target at 30+ FPS,
persist campaign state, and pass qualitative review by the owner and two
collaborators. Privacy gates must verify opt-out telemetry suppression and
consent boundaries before analytics or personalization work is enabled.

## 8. Final Recommendations

### 8.1 Keep

Prioritize the playable dual-front Godot prototype, C++ simulation foundation,
heroes and specialized units, historical-readable art, and a small internal
dashboard fed by local/static data.

### 8.2 Change

Re-sequence the roadmap around G2 and the offline slice; defer multiplayer,
website expansion, ML automation, and LiveOps; replace stale architecture and
issue language; and retain future ideas as explicitly demoted work rather than
quietly treating them as launch requirements.

### 8.3 Reject or park

Reject gameplay gacha. Park PvP, settlement capture, remote live dashboards,
public-web ingestion, and autonomous sentiment-driven balancing until later
evidence supports them.

## 9. Final-Pass Consensus

| Contributor | Agrees with structure? | Required changes | Final date |
| --- | --- | --- | --- |
| Owner | `[AGREE]` | Owner decisions captured; final synthesis approved. | 2026-08-11 |
| Chat / Codex | `[AGREE]` | Final pass completed; owner clarification on `godot-cpp` plus native C++ modules incorporated. | 2026-08-11 |
| Claude | `[AGREE]` | Re-verified OBSERVED facts (Godot 4.7 seed, no `.gdextension` yet, no KMP config) against the repository; withdrew the KMP mobile-packaging mandate from my 2026-08-10 report as an unsupported inference. No disagreement with the recorded DECIDED/PROVISIONAL/OPEN items. See `.agent/reports/claude/report.md`. | 2026-08-11 |
| Gemini | `[AGREE]` | Bus final-pass note 2026-08-11; roadmap substance aligns (KMP not mandatory — Claude caution stands). | 2026-08-11 |
| Grok | `[AGREE]` | Final reviewer: roadmaps v5 + vertical_slice/co_op + issue hygiene executed. | 2026-08-11 |

## 10. Binding Handoff to Roadmap Authors

**CLOSED 2026-08-11 (Grok final pass):** roadmaps under `docs/moon/roadmaps/` and
`docs/moon/ROADMAP.md` updated to match the canonical shared report and this
admin contract. GitHub epics/titles adjusted for Godot dual-front, monetization
policy, backend alternatives, and sentiment research. Owner closes any remaining
process items; implementation next step is **G2 / VS1**.

## Changelog

| Date | Contributor | Change |
| --- | --- | --- |
| 2026-08-09 | Chat / Codex | Created the initial owner status/review/roadmap decision template, adapted to Mobile Fortress and the repository's concurrent-editing workflow. |
| 2026-08-10 | Chat / Codex | Filled owner-answer-supported sections from the PMF Q&A; left unresolved mechanics and final consensus sign-off pending. |
| 2026-08-11 | Owner | Final synthesis approved (`[AGREE]`); C4 notes godot-cpp + C++ modules. |
| 2026-08-11 | Grok | Final pass: consensus table filled; roadmaps v5 + vertical_slice/co_op; GitHub hygiene; handoff closed. |
| 2026-08-11 | Claude | Final report pass: re-verified OBSERVED repo facts, refreshed `.agent/reports/claude/report.md`, withdrew the unsupported KMP mandate, and signed the §9 consensus row `[AGREE]`. |
| 2026-08-11 | Chat / Codex | Completed final pass, corrected the Godot/C++ integration wording, and recorded Codex's sign-off only; other agent sign-offs remain pending. |
