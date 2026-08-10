# Mobile Fortress — Grok Independent Report (Owner Q&A + Direction)

**Date:** 2026-08-10  
**Author:** Grok (Build / xAI)  
**Status:** Post-brainstorm synthesis. Roadmap file edits intentionally **deferred** until multi-agent consensus (owner R.46).  
**Coordination:** `.agent/cache/AGENT_BUS.md` · Q&A freeze: `.agent/cache/owner_qa_lock.md`  
**Companion decision doc (concise):** `.agent/reports/shared/pmf_20260810_decisions.md`

---

## 1. Mission this session

The owner asked us to pivot back to Project Mobile Fortress, but first mirror the Coding-Assistants multi-agent experiment: coordinate via markdown under `.agent/cache/`, write owned reports under `.agent/reports/{agent}/`, and converge on a shared document — **without** relying on the unfinished CA hub.

Grok’s immediate deliverables:

1. Bootstrap a **single** coordination bus (lesson from CA: three parallel channels thrashed).
2. Freeze the owner’s Gemini / Chat / Grok Q&A into a machine-readable lock file.
3. Publish this independent report.
4. Seed a **concise decision document** (owner preference over a full reasoning archive).
5. Hold roadmap/issue rewrites until peers ACK.

---

## 2. Repository OBSERVED state (still true)

| Surface | Reality |
| --- | --- |
| `android/` | SurfaceView + fixed-timestep demo (`Ball`) — **to be abandoned** as primary client |
| `ios/` | SpriteKit top-down shooter skeleton — **to be abandoned** as primary client |
| `core/` | Assets + state-machine docs **and** new **Godot 4.7** `project.godot` (Forward Plus, Jolt) — OBSERVED Godot seed already present |
| `docs/moon/` | Mature roadmaps; still largely dual-native + C++ sim narrative |
| `docs/website/` | Most “finished” product surface (React host + islands) |
| `infra/` | Scaffold only; **no cloud budget** yet |
| Playable Wōkòu TD | **Still no** |

Claude’s 2026-08-09 analysis remains largely correct on diagnosis (docs ahead of playable loop; issue drift; ML needs gates). Several **prescriptions** are now superseded by owner Q&A (engine, slice shape, monetization).

---

## 3. Product identity (Grok read of owner answers)

**Mobile Fortress** is a **portfolio/research-first (60%)**, **commercial-second (40%)** Wōkòu-era coastal tower defense with:

- **Mandatory dual fronts** (land + sea) as core identity, not a later skin.
- **Asymmetric co-op** (land player / sea player) as a **launch pillar**, but **not** in the first offline prototype.
- **Isometric 2.5D** presentation on **Godot 4**, simulation/core systems in **C++**.
- **Ming + Portuguese** default civ pairing for MVP.
- **Ukiyo-e-readable** art bar even for Slice-0 (not pure greyboxes forever).
- Heroes as **grid-placed auras + active abilities**, not pure card ults and not free RTS micro forever.
- Monetization: **cosmetics → battle pass → skin lootboxes**; **reject gameplay-power gacha**.

Success in 90 days: a **playable dual-front vertical slice that shows promise**, validated by the owner + two collaborators — not a store soft-launch.

---

## 4. Architecture direction (DECIDED / PROVISIONAL)

### 4.1 Client stack — major pivot

| Prior default | New default | Notes |
| --- | --- | --- |
| Android SurfaceView + iOS SpriteKit | **Godot 4** single game client exported to Android/iOS | Owner open to C++ engine unification; Godot config already under `core/` |
| Dual native UI firm | Not firm; KMP optional where helpful | Reduces dual-client tax |
| minSdk 24 / iOS 16 (template) | **Android 13+ / iOS 17+** | Update CI + docs when roadmaps move |

**Grok recommendation:** Treat `android/` and `ios/` template trees as **reference / eventual thin wrappers or retirees**, not the long-term gameplay homes. Do not invest further in Ball/shooter skeletons except as disposable experiments. Primary gameplay work should target Godot scenes + a C++ module/GDExtension path consistent with `shared_core.md`’s C++ decision.

### 4.2 Simulation and netcode

| Topic | Decision |
| --- | --- |
| Language | **C++ firm** (EnTT/FlatBuffers direction still valid to revisit for Godot integration details) |
| Online model | Server-authoritative + replicated state (not lockstep) |
| Offline | Campaign playable offline; raids/leaderboards require online |
| Early co-op | Local Wi‑Fi first; networking plumbing deferred past prototype |
| Tick | ~20 Hz provisional for future MP |

### 4.3 Performance budget

- **≥30 FPS**, ~**40** concurrent units on target devices, minimum **10** units for a meaningful fight.
- Swarm/Boids + evolutionary pathing are **identity research** — OK to experiment client-side with capped rates; do not block Slice-0 on perfect RVO.
- Identity ML: **RL DDA** + **swarm/evo pathing**; CMAB important for monetization later; WFC/TGNN nice-to-have research.

---

## 5. Gameplay contract (for G2+)

### 5.1 Dual-front loop (mandatory in prototype)

1. **Build phase:** placement, upgrades/bonuses purchase, initial positioning.
2. **Combat phase:** defense + resource management under raid pressure.
3. **Land vs sea:** different environments; same-env combat primary; **cross-env range exchanges** at designated interfaces; environment-locked resources force strategic focus; specialized cross-support units trade own-env power for other-front support.
4. **Outposts:** Resource (land currency) vs Trading (naval currency); loss is **economic**, not auto-defeat; optional challenge modifiers for no/low outpost loss.
5. **HQ:** still the primary lose condition (per existing GDD direction — keep unless owner revises).

### 5.2 Heroes

- Instant placement on grid cell.
- Nearby unit bonuses + active ability with cooldown.
- Mix: support-heavy, combat-focused, global/resource.
- Reposition with travel time: no attack while moving; auras may apply along path.

### 5.3 Co-op (design now, implement later)

- Asymmetric land/sea roles are identity, but **prototype is single-player controlling both** with **shared screen perspective**.
- Sea role (for schema): naval lanes, Trading Outposts, fleet intercept — **same grid rules as land** initially, not a disconnected strategic-only UI.
- FlatBuffers/state schema should model two fronts + cross-front modifiers early even if only one human acts.

---

## 6. Monetization & privacy

| Item | Policy |
| --- | --- |
| Gameplay gacha | **REJECTED** (pay-to-win risk) |
| Cosmetic skin lootboxes | **IN** (after or with battle pass) |
| Battle pass | After cosmetics baseline |
| Ads | Rewarded only |
| Social-graph offers | Opt-in; anonymized **cohorts / clan personas** |
| Telemetry | None if opt-out; graduated options preferred |
| Difficulty UX | Hidden RL fine-tune on baseline intensity; later A/B vs visible control |
| Sentiment scrape → live game | Research + issues; **HITL dashboard** near-term |

---

## 7. Website / dashboard

- Priority split **75% game / 25% website** this quarter.
- Dashboard: **internal-first**, player-curious second; **static/batch** first; local Docker later OK; no rush to Vercel/Amplify.
- 3D lore map: marketing-important, not mission-critical.
- MkDocs: keep only if it feeds the React surface.
- Sentiment/social ingestion: explicitly **later** for v1 metrics product, but **file research issues** now (owner Gemini R.5).

---

## 8. Process recommendations

1. **Shared report form:** concise decision doc at `pmf_20260810_decisions.md`. Keep long analysis in per-agent files. Eventually stub-redirect older dual templates (`shared_report.md` / `PMF_Shared_Report.md`) after peer ACK (do not hard-delete history).
2. **Roadmaps:** restructure as agents deem best — strongly recommend:
   - `vertical_slice.md` (Slice-0 acceptance criteria: dual-front, offline, Godot, Ming/Portuguese, ukiyo-e-readable, unit budget)
   - `co_op_modes.md` (design-only until post-prototype)
   - Monetization edits: hero gacha → skin lootboxes
   - Engine pivot notes in `shared_core.md` + new ADR
   - AI systems: entry gates; add **sentiment-driven events** as RESEARCH row
3. **GitHub:** epics + sub-issues; milestones from epic groups; Rust issues → C++ (edit vs replace per similarity).
4. **Commits:** fine-grained Conventional Commits + `git/messages/grok_coauthor.msg`.
5. **Grok role:** last roadmap reviewer after consensus; may update issues once consensus exists.

---

## 9. Capacity reality check

Rough capacity: 3 people × ~3–5 h × 6 days ≈ **54–90 human-hours/week** once full, but **first 2 weeks ≈ owner + Grok only**.

Therefore:

- **Do not** parallelize GameLift fleet work, full CMAB, TGNN, or live multiplayer.
- **Do** G2 dual-front fun loop on Godot.
- Friends’ early contributions: issues, roadmap, product framing — good fit.
- C++ collaborator is high-leverage for sim core **after** a fun Godot slice exists (or in parallel only if slice ownership is clear).

---

## 10. Art pipeline (requested for shared report)

| Stage | Slice-0 | Later |
| --- | --- | --- |
| Style anchor | Ukiyo-e-readable silhouettes, limited palette, coastal Ming/Portuguese read | Full illustration pass |
| Units | Distinct land vs sea silhouettes at isometric read distance | Animation cycles, damage states |
| Buildings/HQ/outposts | Readable faction + function icons on grid | Seasonal skins (lootbox cosmetics) |
| UI/HUD | Historical-aesthetic chrome; large touch targets | Clan/meta surfaces |
| Audio | Optional later (engineer candidate) | SFX for placement, raid horns, sea/land stingers |
| Tooling | Godot import pipeline under `core/` | CI art lint / max texture budgets |

---

## 11. Keep / change / demote

### Keep

- Wōkòu dual-front fantasy and Ming + Portuguese defaults
- C++ as systems language
- Hero-as-commander fantasy (retargeted away from power gacha)
- Internal dashboard initiative (scoped static first)
- `.agent/` discipline, severity protocol, fine-grained agent process
- Claude’s ML **entry-gate** discipline

### Change (high impact)

- **Engine:** Godot 4 primary client
- **Slice:** full dual-front, not land-only stub
- **Art bar:** ukiyo-e readable
- **Monetization:** skin lootboxes; no gameplay gacha
- **Net philosophy:** server-auth when online; offline campaign first
- **min OS versions:** Android 13 / iOS 17

### Demote (not delete)

- Live multiplayer plumbing, PvP, settlement capture
- GameLift-as-default
- WFC/TGNN as near-term delivery
- Live dashboard / remote dynamic hosting
- Reddit/X productization (keep as research issues)

### Reject

- Pay-to-win hero/unit gacha
- Telemetry when user opted out
- Multiple simultaneous “primary” coordination buses

---

## 12. Immediate sequence (after consensus)

1. Peer reports + ACK on `pmf_20260810_decisions.md`
2. Roadmap PR (Grok final review): Godot pivot, vertical_slice, monetization, AI research rows, co-op design doc
3. GitHub epic reorg + C++ issue hygiene + sentiment-events research issues
4. **Implement G2** playable dual-front offline prototype
5. Only then G3 pathing depth / G7 economy polish / shared-core packaging

---

## 13. Open items still needing owner or peer input

| ID | Item | Why open |
| --- | --- | --- |
| O1 | Exact Godot↔C++ boundary (GDExtension vs rewrite sim in GDScript/C# then extract) | Owner said C++ + Godot; integration pattern not chosen |
| O2 | Whether `android/`/`ios/` trees are deleted, archived, or kept as export shells | Process/cleanliness |
| O3 | Vertical-slice calendar target (old 2026-08-23 single-lane date is stale) | Owner gave qualitative 90-day success, not a new hard date |
| O4 | 20 Hz sim tick confirmation | Owner said “guess / undecided” |
| O5 | AI-controlled opposite front as optional single-player assist | Owner musing only |

---

## 14. Changelog (this report)

| When | Change |
| --- | --- |
| 2026-08-10 | Initial post-Q&A independent report; cache bus bootstrap; decision-doc seed |
