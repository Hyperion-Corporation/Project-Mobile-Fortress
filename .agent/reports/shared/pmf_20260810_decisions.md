# Mobile Fortress — Shared Decision Document

**Date opened:** 2026-08-10  
**Form:** Concise decision record (owner preference — not a full multi-agent archive)  
**Authority:** Owner decisions win. Agents propose; Grok last-reviews roadmap application.  
**Q&A source:** `.agent/cache/owner_qa_lock.md`  
**Bus:** `.agent/cache/AGENT_BUS.md`  
**Status:** SEEDED by Grok — awaiting Chat / Claude / Gemini ACK or DISSENT

### How to use

- Labels: **DECIDED** · **PROVISIONAL** · **OPEN** · **RESEARCH** · **REJECTED**
- Agents: append to §9 changelog and §8 signatures; do not silently flip DECIDED rows.
- Long reasoning lives in `.agent/reports/{agent}/`, not here.
- Older templates (`shared_report.md`, `PMF_Shared_Report.md`) remain historical until peers ACK stubbing them.

---

## 1. Executive decisions (TL;DR)

1. Build a **playable offline dual-front** prototype that **shows promise** (portfolio/research 60%, commercial 40%).
2. **Godot 4** is the game client; **C++** remains the systems/sim language; abandon SurfaceView/SpriteKit as primary.
3. **Land + sea** are mandatory core identity; asymmetric co-op is a launch pillar **designed now, networked later**.
4. Monetize with **cosmetics → battle pass → skin lootboxes**; **no gameplay gacha**.
5. Next build focus: **G2**. Roadmap/issue rewrites wait for multi-agent consensus; Grok is final reviewer.

---

## 2. Product contract

| ID | Topic | Status | Decision |
| --- | --- | --- | --- |
| PC1 | 90-day success | DECIDED | Playable vertical slice that shows promise |
| PC2 | Audience gate | DECIDED | Owner + 2 collaborators must agree quality bar |
| PC3 | Team capacity | DECIDED | 3 humans; 3–5h/day; 6 days/week; first ~2 weeks mostly owner+Grok |
| PC4 | First deliverable | DECIDED | Playable offline prototype |
| PC5 | Dual-front in slice | DECIDED | Both land and sea mandatory |
| PC6 | Default civs | DECIDED | Ming + Portuguese only for MVP |
| PC7 | Presentation | DECIDED | Isometric 2.5D; ukiyo-e-readable art bar |
| PC8 | Asymmetric co-op | DECIDED | Core identity; not in first prototype; local Wi‑Fi first when built |
| PC9 | SP control model | PROVISIONAL | One player controls both fronts; shared screen perspective |
| PC10 | PvP | DECIDED | Post-launch |
| PC11 | Clans / settlements | DECIDED | Clans at launch; settlement capture later season |
| PC12 | Offline | DECIDED | Campaign offline; raids/leaderboards online-only |
| PC13 | Day/night | DECIDED | Build/position phase vs combat/resource phase |
| PC14 | Outpost loss | DECIDED | Economic penalty only |
| PC15 | Heroes | DECIDED | Grid place + aura + active CD; reposition with travel time |
| PC16 | Historical tone | DECIDED | Historical aesthetics; accessible fiction; light mystic OK |

---

## 3. Technical contract

| ID | Topic | Status | Decision |
| --- | --- | --- | --- |
| TC1 | Engine | DECIDED | Godot 4 (config already in `core/`) |
| TC2 | Sim language | DECIDED | C++ firm |
| TC3 | Dual native UI | DECIDED | Not required; prefer unified client |
| TC4 | Platforms | DECIDED | Android 13+, iOS 17+; ship together when possible |
| TC5 | Net model | DECIDED | Server-authoritative + replication (when online) |
| TC6 | Units / FPS | DECIDED | ~40 units target, ≥10 min; 30+ FPS |
| TC7 | Pathing research | DECIDED | Swarm + evo experiments in scope; FPS cap OK for battery |
| TC8 | MP tick | PROVISIONAL | ~20 Hz |
| TC9 | Cloud / GameLift | DECIDED | Alternatives OK; no dev cloud budget yet |
| TC10 | Godot↔C++ boundary | OPEN | GDExtension vs staged extract — needs design spike |
| TC11 | Next implement | DECIDED | **G2** first |

---

## 4. Monetization, privacy, ML

| ID | Topic | Status | Decision |
| --- | --- | --- | --- |
| MC1 | Gameplay gacha | REJECTED | Avoid pay-to-win heroes/units |
| MC2 | Skin lootboxes | DECIDED | Cosmetic gacha-style OK |
| MC3 | Sequence | DECIDED | Cosmetics → battle pass → skin lootboxes |
| MC4 | Ads | DECIDED | Rewarded only |
| MC5 | Social personalization | DECIDED | In scope; opt-in; anonymized cohorts/clan personas |
| MC6 | Telemetry | DECIDED | Nothing if opt-out; graduated options |
| MC7 | DDA UX | DECIDED | Baseline intensity; RL hidden fine-tune; later A/B |
| MC8 | ML identity | DECIDED | RL DDA + swarm/evo identity; CMAB important; WFC/TGNN research |
| MC9 | Sentiment → game events | RESEARCH | Dashboard HITL now; automated events on roadmap + new issues |
| MC10 | Reddit/X in v1 product | DECIDED | Explicitly later (research direction) |

---

## 5. Website / docs

| ID | Topic | Status | Decision |
| --- | --- | --- | --- |
| WC1 | Priority | DECIDED | 75% game / 25% website |
| WC2 | Dashboard | DECIDED | Dev-first; static/batch first; local OK |
| WC3 | Live remote dashboard | DECIDED | Later (Docker when needed) |
| WC4 | 3D lore map | DECIDED | Marketing-important, not mission-critical |
| WC5 | MkDocs | DECIDED | Keep if feeds React; else remove |

---

## 6. Art pipeline (summary)

| Stage | Slice-0 bar |
| --- | --- |
| Style | Ukiyo-e-readable silhouettes; coastal Ming/Portuguese read |
| Units | Distinct land/sea silhouettes at isometric distance |
| Structures | HQ / Resource / Trading outposts readable by function |
| UI | Historical aesthetic; large touch targets |
| Audio | Not required for Slice-0; candidate hire later |

---

## 7. Process contract

| ID | Topic | Status | Decision |
| --- | --- | --- | --- |
| RC1 | Shared doc form | DECIDED | This concise decision document |
| RC2 | Roadmap SoT application | DECIDED | Owner closes; Grok last reviewer |
| RC3 | Roadmap PR timing | DECIDED | After multi-agent consensus |
| RC4 | Issues | DECIDED | Epics + sub-issues; milestones from epic groups |
| RC5 | Rust-era issues | DECIDED | Edit if language-only; else replace with C++ issues |
| RC6 | Commits | DECIDED | Fine-grained Conventional Commits + agent coauthors |
| RC7 | CHANGELOG history | DECIDED | Leave Sengoku/Vue history |
| RC8 | Coordination | DECIDED | Single bus: `.agent/cache/AGENT_BUS.md` |

### Supersedes (2026-08-09 rows)

| Prior | Replacement |
| --- | --- |
| Android single-lane placeholder slice by 2026-08-23 | Dual-front offline prototype; art ukiyo-e-readable; qualitative 90-day bar |
| SurfaceView/SpriteKit primary | Godot 4 primary |
| Hero power gacha pillar | Skin lootboxes only |
| GameLift-centric backend assumption | Alternatives OK; offline-first |

C++ sim decision: **reaffirmed**.

---

## 8. Agent signatures (structure + substance)

| Agent | Decision doc OK? | Notes | Timestamp |
| --- | --- | --- | --- |
| Grok | Yes (seed) | Bootstrapped from full owner Q&A | 2026-08-10 |
| Chat | | | |
| Claude | | | |
| Gemini | | | |
| Owner | | | |

---

## 9. Collaborative changelog

| When | Who | Change |
| --- | --- | --- |
| 2026-08-10 | Grok | Created decision doc from owner Q&A lock; linked bus + per-agent report |
| 2026-08-10 | Grok | Observed peer reports (Chat/Gemini/Claude short forms); canonicalized over thin `pmf_20260810_shared_decision.md` stub; flagged website≠Godot and KMP-optional cautions on bus |

---

## 10. Next actions (ordered)

1. Chat / Gemini / Claude: personal reports + signature rows above.
2. Resolve OPEN TC10 (Godot↔C++ boundary) if possible before roadmap PR.
3. Consensus ACK → roadmap restructure + GitHub epics.
4. Grok final review pass.
5. Implement **G2**.
