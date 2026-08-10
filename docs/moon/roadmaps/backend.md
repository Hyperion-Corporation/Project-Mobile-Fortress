# Backend Roadmap

**Owner:** TBD

Scope: optional online services for co-op, clans, leaderboards, and cloud save. **No remote backend is required for Slice-0** (offline campaign first). Cloud budget during early development: **none yet**.

**2026-08-11 note:** AWS GameLift is **not** a hard requirement — Nakama, PlayFab, or self-host are acceptable. Online model when needed: **server-authoritative + replicated state** (not lockstep). Early co-op transport: **local Wi‑Fi** (see [`co_op_modes.md`](co_op_modes.md)).

| # | Item | Effort | Status |
| --- | --- | --- | --- |
| B1 | `infra/` scaffolding (Docker, k8s, Helm, Terraform, Ansible) | M | ✅ Done |
| B2 | Server-authoritative game-session service (C++ sim authority, delta state) | XL | 📋 Deferred post Slice-0 |
| B3 | Client-side prediction + reconciliation for placement/commands | L | 📋 Deferred |
| B4 | Fleet/matchmaking provider evaluation & provisioning (GameLift **or** Nakama/PlayFab/self-host) | L | 📋 Deferred · provider open |
| B5 | Latency-aware matchmaking policy | M | 📋 Deferred |
| B6 | Cost-control fleet policies (spot/on-demand or equivalent) | M | 📋 Deferred |
| B7 | Leaderboards API (online-only feature) | L | 📋 Deferred |
| B8 | Godot networking client for backend API | M | 📋 Deferred |
| B9 | Cloud save with conflict resolution | L | 📋 Deferred |
| B10 | Clan/territory persistent map service (settlement capture = later season) | XL | 📋 Deferred |
| B11 | Local Wi‑Fi co-op session transport (pre-cloud) | M | 📋 After Slice-0 fun |

Effort key: S = days, M = 1–2 weeks, L = 3–6 weeks, XL = multi-month/cross-cutting.
