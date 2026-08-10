# AI & Procedural Systems Roadmap

**Owner:** ACFHarbinger

Scope: procedural content, dynamic difficulty, pathing research, monetization/retention ML, and sentiment research. Post-MVP systems assume the dual-front loop ([`gameplay.md`](gameplay.md) / [`vertical_slice.md`](vertical_slice.md)) exists first.

**2026-08-11 note:** **Identity research:** RL DDA + swarm/evolutionary pathing. **Important later:** CMAB. **Nice research:** WFC, TGNN. Difficulty UX starts with baseline intensity + **hidden** RL fine-tune; later A/B vs visible controls. Sentiment-driven **in-game events** are research with **HITL** default.

| # | Item | Effort | Status | Entry gate |
| --- | --- | --- | --- | --- |
| A1 | WFC raid-map generation | L | 📋 Research | Nice research — do not block Slice-0 |
| A2 | MILP-augmented WFC for solvability | L | 📋 Research | After A1 |
| A3 | Nested WFC for large maps | M | 📋 Research | Only if A1/A2 backtracking costs measured |
| A4 | Heuristic rule-based DDA (shipping baseline) | M | 📋 Pending | Committed baseline before RL |
| A5 | RL continuous-action DDA (hidden fine-tune of baseline intensity) | XL | 📋 Pending | **Blocked:** A4 + playtest evidence that rules fail a flow metric |
| A6 | Two-agent imitation + adversarial RL difficulty | XL | 📋 Deferred | After A5 evaluated |
| A7 | CMAB (LinUCB) personalized offers — opt-in cohorts | XL | 📋 Deferred | Needs live non-personalized store baseline |
| A8 | HITL gate for CMAB pricing | M | 📋 With A7 | Safety for A7 |
| A9 | Survival-analysis churn/LTV | L | 📋 Deferred | Needs Q8 instrumentation |
| A10 | TGNN cascading-churn | XL | 📋 Research | Needs co-op history + A9 insufficient |
| A11 | **Swarm / Boids + evolutionary pathing experiments** (client-side; 30 FPS cap OK) | L | 📋 Identity research | Can sandbox after dual-front exists; not server-mandatory for offline |
| A12 | **Sentiment ingestion → dashboard** (Reddit/X/store reviews) | L | 🔬 Research | Dashboard HITL only initially ([`internal_dashboard.md`](internal_dashboard.md) ID9/ID10) |
| A13 | **Sentiment-driven automated in-game events** (e.g. global dungeon buffs) | XL | 🔬 Research | **HITL required** until owner approves autonomy; never silent pricing/spawn changes without review |

Effort key: S = days, M = 1–2 weeks, L = 3–6 weeks, XL = multi-month. ML items A5–A10, A12–A13 must not block Slice-0.
