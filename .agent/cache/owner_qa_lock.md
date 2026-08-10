# Owner Q&A lock — 2026-08-10

**Authority:** Owner (admin / ACFHarbinger) answers delivered in the main session.  
**Status:** LOCKED for agent synthesis. Agents may ask follow-ups on the bus; do not re-open settled rows without an owner `REVISE` note here.  
**Purpose:** Single place peers can read without re-parsing the chat transcript.

Labels: **DECIDED** | **PROVISIONAL** | **OPEN** | **RESEARCH**

---

## A. Team, time, success

| ID | Decision | Status | Owner answer (condensed) |
| --- | --- | --- | --- |
| T1 | Team size / hours | DECIDED | 3 humans; 3–5 h/day, 6 days/week (5h weekend days, 3h weekdays, 1 weekday off). First ~2 weeks: owner mostly alone + Grok; friends join with roadmap/PM focus. One friend: C++/Unreal/fluid-sim CS; other: marketing/management + some programming. Possible audio engineer + artist later this month. No dedicated audio yet. |
| T2 | 90-day success | DECIDED | Playable vertical slice that **shows promise** |
| T3 | Product posture | DECIDED | Portfolio/research showcase first, commercial ship second (**60/40**) |
| T4 | First real audience | DECIDED | Owner + 2 collaborators must first agree product is good enough |

---

## B. Platforms and engine

| ID | Decision | Status | Owner answer (condensed) |
| --- | --- | --- | --- |
| E1 | Engine | DECIDED | **Godot 4** (abandon SurfaceView / SpriteKit skeletons). `core/` already has Godot project config. |
| E2 | Simulation language | DECIDED | **C++ firm** (with Godot); Rust not under consideration for sim core |
| E3 | Client strategy | DECIDED | Prefer **single client path** (Godot export + optional Kotlin Multiplatform where useful); separate native Kotlin + Swift UI layers are **not** a firm requirement |
| E4 | Ship Android + iOS together | DECIDED | Aim to ship together via Godot/KMP path |
| E5 | min platforms | DECIDED | **Android 13+**, **iOS 17+** |
| E6 | macOS / iOS CI | DECIDED | Collaborator with macOS machines owns iOS CI when they join |
| E7 | Presentation | DECIDED | Primarily **isometric 2.5D** |

---

## C. Vertical slice / first deliverable

| ID | Decision | Status | Owner answer (condensed) |
| --- | --- | --- | --- |
| V1 | First concrete deliverable | DECIDED | **Playable offline prototype** (not pure design-only or pure shared-sim proof) |
| V2 | Land + sea in first slice | DECIDED | **Both mandatory** — dual-front is core identity |
| V3 | Default civs for MVP | DECIDED | **Ming + Portuguese** only |
| V4 | Art bar Slice-0 | DECIDED | **Ukiyo-e readable** (not pure placeholders) |
| V5 | Shortest “proof” session | DECIDED | **Full dual-front** session |
| V6 | Next implementation priority | DECIDED | **G2** first (among G2/G3/G7/S1) |
| V7 | Non-disposable design | DECIDED | Core gameplay loop: land/sea dynamic, specialized units/heroes, civ strengths/weaknesses. Most current code is experimental/disposable |
| V8 | Non-negotiable roadmap items | DECIDED | Single-player Wōkòu-era vertical slice, commanders/heroes, internal dashboard; little else hard-locked |
| V9 | Comfortable demotions | DECIDED | **Hero gacha → skin lootboxes**; other stretch items demoted not deleted |

---

## D. Co-op, multiplayer, meta

| ID | Decision | Status | Owner answer (condensed) |
| --- | --- | --- | --- |
| M1 | Asymmetric co-op (land player / sea player) | DECIDED | **Core identity / launch pillar**, but **not** in first prototype; design loop so land/sea differ, same-env combat + cross-env range exchanges + environment-locked resources + specialized cross-support units |
| M2 | Single-player control model | PROVISIONAL | Leaning: **one player controls both** land and sea → same screen perspective for co-op too is easier; AI-on-one-front remains open design musing |
| M3 | Early co-op transport | DECIDED | **Local Wi‑Fi first** (hot-seat / async later not prioritized) |
| M4 | Networking / multi-player infra | DECIDED | Leave pure multiplayer plumbing for later; focus gameplay + UX first |
| M5 | Net model when online arrives | DECIDED | **Server-authoritative + replicated state** (lockstep **not** required) |
| M6 | PvP | DECIDED | **Post-launch** (v1 can be PvE/co-op path) |
| M7 | Clans | DECIDED | Persistent **from launch** |
| M8 | Settlement capture | DECIDED | **Later season** |
| M9 | Global dungeon / capture cadence | DECIDED | Start with **simpler weekly events** → build toward persistent seasonal map |
| M10 | Offline | DECIDED | Main campaign works offline; online features (clan raids, leaderboards) disabled offline |
| M11 | Soft launch offline-only | DECIDED | Acceptable |

### Sea-player role (Gemini Q7) — synthesis from owner design answers

**Status:** DECIDED enough for schema design (PROVISIONAL on exact UI chrome)

When asymmetric co-op is built, Sea is not a pure “zoomed-out logistics only” minigame. Owner direction:

- Same grid rules as land initially (may evolve into a more distinct naval minigame later).
- Sea owns **naval unit placement, naval raid lanes, Trading Outpost economy**, and convoy/intercept-style defense against pirate fleets.
- Cross-front synergy: units with extended range can shoot across environments; specialized support units trade own-env effectiveness for other-env support; some upgrades need land-only or sea-only resources.
- Heroes: placed on a grid, aura bonuses to nearby units, active ability on cooldown; repositionable with travel time (no attack while traveling; auras may still apply).
- For single-player / early co-op: **shared screen perspective** preferred while one mind (or two co-op players) manage both fronts.

---

## E. Day/night, economy, heroes, tone

| ID | Decision | Status | Owner answer (condensed) |
| --- | --- | --- | --- |
| G1 | Day/night | DECIDED | One phase = build / buy upgrades / initial positioning; other = combat + resource management |
| G2 | Outpost loss | DECIDED | **Economic only** (harder win, still possible); optional challenges for no/limited outpost loss → better rewards |
| G3 | Heroes | DECIDED | Instant grid placement + nearby bonuses + active CD ability; mix of support / combat / global-resource heroes; reposition with travel time |
| G4 | Naval rules | DECIDED | Same grid rules as land first |
| G5 | Historical vs mythic | DECIDED | **Heavier historical** aesthetics (UI, HUD, units, buildings); accessible fictionalization elsewhere; light mystic elements OK (yokai not required as pillar) |
| G6 | Historical commanders | DECIDED | Mixture of gameplay power + cosmetic |

---

## F. Monetization, privacy, ML

| ID | Decision | Status | Owner answer (condensed) |
| --- | --- | --- | --- |
| $1 | Day-one monetization | DECIDED | **Cosmetics first**; battle-pass after; **skin lootboxes** (gacha-style cosmetics); **no** gacha for gameplay heroes/units (anti pay-to-win) |
| $2 | Ads | DECIDED | **Rewarded only** |
| $3 | Personalized offers (friends/clan/squad) | DECIDED | In scope; prefer **anonymized cohorts / clan personas**; can be **opt-in** |
| $4 | Telemetry consent | DECIDED | **No collection if opted out**; offer multiple graduated telemetry options |
| $5 | Continuous difficulty | DECIDED | Baseline intensity levels exist; **RL fine-tunes under the hood**; start **hidden** for flow; later A/B vs full customization |
| $6 | ML identity vs research | DECIDED | **Identity:** RL DDA, swarm/evo pathing; **Important:** CMAB monetization; **Nice research:** WFC, TGNN |
| $7 | Reddit/X / store-review ingestion | RESEARCH | Dev dashboard first; automated in-game event response is **worthwhile research** — add to roadmap + GitHub issues; **not** v1 product core; Human-in-the-Loop default until proven |
| $8 | Sentiment autonomy | DECIDED (near-term) | Dashboard + HITL approve; automatic spawn/pricing tweaks only after explicit research track |

---

## G. Performance

| ID | Decision | Status | Owner answer (condensed) |
| --- | --- | --- | --- |
| P1 | Units on low-end | DECIDED | Aim **~40** simultaneous units typical cap; **≥10** minimum meaningful fight |
| P2 | FPS target | DECIDED | **30+ FPS** on target devices (battery-friendly; OK to cap sim presentation around 30) |
| P3 | Swarm / Boids pathing | DECIDED | Want **swarm + evolutionary experiments**; prefer client-side with FPS cap over mandatory server offload for offline prototype |
| P4 | Future multiplayer tick | PROVISIONAL | ~**20 Hz** suggested, still open |
| P5 | Ban-list | DECIDED | None for now |

---

## H. Website, dashboard, docs

| ID | Decision | Status | Owner answer (condensed) |
| --- | --- | --- | --- |
| W1 | Game vs website priority (quarter) | DECIDED | **75/25 game** |
| W2 | Dashboard audience | DECIDED | Mainly developers; also curious players |
| W3 | Live vs static | DECIDED | **Static/batch first**; live later |
| W4 | Hosting | DECIDED | Local-only dynamic dashboard fine for small team; custom Docker later if needed; GitHub Pages remains for static site |
| W5 | 3D lore map | DECIDED | Important for marketing, **not** mission-critical |
| W6 | MkDocs | DECIDED | Keep if it feeds React; remove if useless |
| W7 | Metrics placement | DECIDED | Admin-only for now |

---

## I. Infra / cloud

| ID | Decision | Status | Owner answer (condensed) |
| --- | --- | --- | --- |
| I1 | AWS GameLift hard requirement? | DECIDED | **No** — Nakama / PlayFab / self-host acceptable |
| I2 | Cloud budget during dev | DECIDED | **Not yet** |

---

## J. Process

| ID | Decision | Status | Owner answer (condensed) |
| --- | --- | --- | --- |
| R1 | Roadmap SoT after brainstorm | DECIDED | Owner closes; **Grok is last reviewer agent** |
| R2 | Stale Rust issues | DECIDED | Replace with C++ issues when scope differs; edit in place when only language name changes |
| R3 | Issue structure | DECIDED | Reorganize into **epics + smaller sub-issues**; multiple epics → project milestone |
| R4 | New roadmap files | DECIDED | Agents may restructure as needed (`vertical_slice.md`, `co_op_modes.md`, etc.) |
| R5 | CHANGELOG historical Sengoku/Vue | DECIDED | Leave as history |
| R6 | Shared report form | DECIDED | **Concise decision document** (not full archive of all reasoning) |
| R7 | Commits | DECIDED | Fine-grained; Conventional Commits + coauthor trailers |
| R8 | Roadmap PR ownership | DECIDED | **Wait for multi-agent consensus** before Grok lands the roadmap PR |
| R9 | GitHub issues with roadmaps | DECIDED | Allowed in same pass once consensus exists |
| R10 | Art pipeline in shared report | DECIDED | Include an art-pipeline section |

---

## K. Supersedes (important)

Earlier 2026-08-09 product-contract rows that **conflict** with this lock should be treated as **SUPERSEDED**:

| Prior (2026-08-09) | Now (2026-08-10) |
| --- | --- |
| Android-first single-lane slice, placeholder art, hard 2026-08-23 gate language | **Full dual-front** offline prototype; **ukiyo-e readable** art bar; success = “shows promise” |
| Native SurfaceView + SpriteKit as default clients | **Godot 4** primary frontend |
| Hero gacha as monetization pillar | **Skin lootboxes only** for gacha-style; no gameplay-power gacha |
| GameLift as primary named fleet | Alternatives acceptable; no cloud budget yet |
| Deterministic lockstep emphasis in some research | Server-authoritative + replication sufficient |

C++ shared simulation decision **remains** DECIDED (reaffirmed).
