# Co-Op Modes Roadmap (design-first)

**Owner:** TBD  
**Status:** 📋 Design now · 📋 Implementation **after** Slice-0  
**Authority:** Owner Q&A 2026-08-10 (asymmetric co-op is a launch pillar, not first prototype)

## Identity

Asymmetric **land player / sea player** co-op is part of Mobile Fortress’s core identity, but **Slice-0 is single-player** (one mind controlling both fronts). Networking, matchmaking, and multi-device plumbing are deferred until the dual-front loop is fun offline.

## Player model

| Mode | When | Perspective | Notes |
| --- | --- | --- | --- |
| SP dual control | Slice-0 + early | Shared screen; one player places on both fronts | Preferred default while learning the loop |
| Asymmetric co-op (2P) | Post-slice launch pillar | Shared screen first (simplifies camera/UI) | Local **Wi‑Fi** first; online later |
| AI on one front | OPEN | Same presentation | Optional assist; not required for Slice-0 |

## Sea-player role (schema-ready)

Sea is **not** a disconnected strategic-only minigame in v1:

- Same **grid placement rules** as land initially (may evolve into a distinct naval minigame later).
- Owns **naval raid lanes**, **Trading Outpost** economy, and fleet intercept / convoy-style defense against pirate fleets.
- **Cross-front synergy:** extended-range units can engage across environment interfaces; specialized support units trade own-env effectiveness for other-env support; some upgrades require land-only or sea-only resources.
- **Heroes** work on either front: grid placement, auras, active CD, reposition with travel time (no attack while moving; auras may apply in transit).

## Deliverables

| # | Item | Effort | Status |
| --- | --- | --- | --- |
| C1 | Document dual-front state schema (land grid, sea grid, shared HQ, cross-front modifiers) for FlatBuffers / C++ | M | 📋 Pending |
| C2 | Local Wi‑Fi co-op session join + input split (land vs sea authority) | L | 📋 Deferred post Slice-0 |
| C3 | Shared-camera UX for two local players | M | 📋 Deferred |
| C4 | Server-authoritative session service (see [`backend.md`](backend.md)) for online co-op | XL | 📋 Deferred |
| C5 | Optional AI partner controlling one front | L | 📋 OPEN research |

## Non-goals (near term)

- PvP clan wars
- Persistent settlement capture (later season)
- Lockstep determinism as a hard requirement (server-authoritative replication is sufficient when online)
