# Backend Roadmap

**Owner:** TBD

Scope: server-authoritative Co-Op multiplayer, matchmaking/fleet orchestration, leaderboards, and cloud save. See [`research/Multiplayer Tower Defense Implementation.md`](../research/Multiplayer%20Tower%20Defense%20Implementation.md) §"Multiplayer Netcode" and §"Matchmaking and Fleet Orchestration via Amazon GameLift".

| # | Item | Effort | Status |
| --- | --- | --- | --- |
| B1 | `infra/` scaffolding (Docker, k8s, Helm, Terraform, Ansible) | M | ✅ Done |
| B2 | Server-authoritative game-session service: ingests client inputs, runs the C++ simulation core, broadcasts canonical state with delta compression | XL | 📋 Pending |
| B3 | Client-side prediction + server reconciliation for tower placement/unit commands (local render immediately, snap to authoritative state on mismatch) | L | 📋 Pending |
| B4 | AWS GameLift fleet provisioning for dedicated Co-Op session servers | L | 📋 Pending |
| B5 | FlexMatch latency-optimized matchmaking: graduated latency policy (e.g. 50ms → 100ms over 120s) to avoid infinite queuing | M | 📋 Pending |
| B6 | Multi-type Spot Instance fleet + On-Demand fallback for cost control, monitoring `MatchAcceptanceTimeouts`/`MatchesCreated` ratios | M | 📋 Pending |
| B7 | Leaderboards REST API (faction rankings, individual HQ-defense scores) | L | 📋 Pending |
| B8 | Android/iOS clients: networking layer for the backend API (Retrofit/Ktor on Android, `URLSession`/async-await on iOS) | M | 📋 Pending |
| B9 | Cloud save with conflict resolution between device and server state | L | 📋 Pending |
| B10 | Coastal faction/territory persistent-world-map service (owns the 4X-lite meta-map state) | XL | 📋 Pending |

Effort key: S = days, M = 1–2 weeks, L = 3–6 weeks, XL = multi-month/cross-cutting.
