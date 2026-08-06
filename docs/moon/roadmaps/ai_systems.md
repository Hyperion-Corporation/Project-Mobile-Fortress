# AI & Procedural Systems Roadmap

Scope: procedural content generation, dynamic difficulty adjustment, and monetization/retention ML — the "frontier" systems from [`research/Multiplayer Tower Defense Implementation.md`](../../research/Multiplayer%20Tower%20Defense%20Implementation.md) §"Algorithmic Procedural Content Generation", §"Deep Learning for Dynamic Difficulty Adjustment", and §"Optimizing Monetization and Player Retention". These are post-MVP: they assume the core loop ([`gameplay.md`](gameplay.md)) and shared Rust core ([`shared_core.md`](shared_core.md)) already exist.

| # | Item | Effort | Status |
| --- | --- | --- | --- |
| A1 | Wave Function Collapse (WFC) raid-map generation: tile-based fortress-grounds and coastal layouts with valid path/wall/shoreline adjacency constraints | L | 📋 Pending |
| A2 | MILP-augmented WFC to guarantee global solvability (a traversable enemy-spawn-to-HQ path always exists, on both land and sea) | L | 📋 Pending |
| A3 | Nested WFC (N-WFC) for large maps, avoiding exponential backtracking | M | 📋 Pending |
| A4 | Heuristic rule-based Dynamic Difficulty Adjustment (DDA) as the shipping v1 — enemy HP/spawn-rate curves tuned per level, no ML dependency for MVP | M | 📋 Pending |
| A5 | RL-based continuous-action DDA (post-MVP): agent modulates enemy velocity/spawn timing/pathfinding aggressiveness to hold players in the flow channel | XL | 📋 Pending |
| A6 | Two-agent (Imitation + Reinforcement Learning) personalized difficulty: an imitation agent clones a player's placement/upgrade heuristics, an adversarial RL agent discovers counter-strategies against the clone | XL | 📋 Pending |
| A7 | Contextual Multi-Armed Bandit (LinUCB) for personalized store-offer selection — tracked jointly with [`monetization.md`](monetization.md#M11) | XL | 📋 Pending |
| A8 | Human-in-the-loop gate for CMAB pricing recommendations (designer approval required before any live pricing change) | M | 📋 Pending |
| A9 | Survival-analysis (Weibull) churn/LTV modeling from early-session telemetry | L | 📋 Pending |
| A10 | Temporal Graph Neural Network (TGNN) over clan Co-Op matchmaking history to detect cascading-churn risk in influential players and trigger retention interventions | XL | 📋 Pending |

Effort key: S = days, M = 1–2 weeks, L = 3–6 weeks, XL = multi-month/cross-cutting; the ML items (A5, A6, A7, A10) are explicitly **not MVP** and should not block launch.
