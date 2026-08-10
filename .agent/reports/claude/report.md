# Claude Code & Architecture Report
**Date:** 2026-08-11 (final-pass refresh; supersedes the 2026-08-10 version below)
**Owner:** Claude (Code)
**Status:** T5 final pass — OBSERVED facts re-verified against the repository; reconciled with the canonical shared report (`.agent/reports/shared/pmf_20260810_canonical_shared_report.md`) and the admin status report (`.agent/reports/admin/pmf_20260809_status_report.md`).

## 1. Executive Summary
With the decision to pivot to Godot 4 and C++, my focus shifts entirely from Swift/Kotlin dual-maintenance to a unified C++ simulation core and Godot bindings. The core simulation will reside in C++ to guarantee performance headroom for Swarm/Evolutionary pathing and the RL DDA logic. This pass corrects one item from my 2026-08-10 note (Kotlin Multiplatform) that the owner did not actually decide, and re-verifies the Godot seed directly against the repository rather than by report.

## 2. OBSERVED (re-verified 2026-08-11)
- `core/project.godot` exists and declares `config_version=5`, `config/features=PackedStringArray("4.7", "Forward Plus")`, and `3d/physics_engine="Jolt Physics"` — the Godot 4.7 seed Grok flagged is real, not aspirational.
- No `.gdextension` file exists anywhere in the repo yet — the Godot↔C++ boundary is genuinely unstarted, confirming it should stay **OPEN** per the admin report (§5, C4) rather than being treated as already chosen.
- `android/app/` and `ios/MyGame/` still exist as full source trees (SurfaceView `Ball` demo / SpriteKit shooter skeleton). Nothing in the repo currently retires or archives them — they remain reference/retiree candidates per Grok's report, not yet acted on.
- No Kotlin Multiplatform configuration exists anywhere in the build files (only doc mentions). **Correction:** my 2026-08-10 report listed "Client Deployment: Kotlin Multiplatform for mobile packaging" as a mandate — this was my own inference, not an owner decision, and the canonical shared report (§3) confirms separate native Kotlin/Swift clients (KMP included) are **not required**. I withdraw that line.

## 3. Technical Architecture Mandates (revised)
- **Engine:** Godot 4.7 (OBSERVED seed) as the primary client, integrated with the C++ simulation via GDExtension or C++ modules — boundary choice remains **OPEN**, needs a short design spike (see §4).
- **Language:** C++ for all heavy simulation logic (game state, pathfinding, AI); no shared-core language reversal.
- **Client packaging:** No second packaging stack (KMP or otherwise) is mandated; Godot's own export covers Android/iOS unless a spike shows a concrete gap.
- **Simulation:** Server-authoritative with replicated state for later online play (not lockstep); ~20 Hz tick is still **PROVISIONAL** per the admin report.
- **Scale:** 10–40 concurrent units at 30+ FPS on target devices, consistent with the canonical report.

## 4. Next Steps
- Spike the Godot↔C++ integration boundary (GDExtension vs. staged C++-module extraction) and report findings back to the group before it's locked as DECIDED.
- Decide and record the disposition of `android/app/` and `ios/MyGame/` (archive, delete, or keep as export shells) — currently unresolved (Grok's O2).
- Assist in defining the G2 dual-front offline-slice engineering sub-tasks once roadmap restructuring proceeds.

## 5. Final-Pass Sign-off
I agree with the admin status report's structure and the canonical shared report's synthesis. My only required change was the KMP correction applied in §2/§3 above; no other disagreement with the recorded DECIDED/PROVISIONAL/OPEN items. See `.agent/reports/admin/pmf_20260809_status_report.md` §9 for the recorded consensus row.

---

## Superseded 2026-08-10 version (kept for history)

**Date:** 2026-08-10
**Owner:** Claude (Code)

### 1. Executive Summary
With the decision to pivot to Godot 4 and C++, my focus shifts entirely from Swift/Kotlin dual-maintenance to a unified C++ codebase architecture and Godot bindings. The core simulation will now reside in C++ to guarantee high performance for Swarm/Evolutionary pathing and the RL DDA logic.

### 2. Technical Architecture Mandates
- **Engine:** Godot 4 integrated via GDExtension or C++ modules.
- **Language:** C++ for all heavy lifting (game state, pathfinding, AI).
- **Client Deployment:** Kotlin Multiplatform for mobile packaging.
- **Simulation:** Server-authoritative with replicated state (20 Hz tick rate).
- **Scale:** Minimum 10 units, maximum 40 on low-end devices.

### 3. Next Steps
- Establish the Godot 4 + C++ project skeleton in `core/`.
- Prepare the architecture blueprint for the isometric 2.5D rendering pipeline.
- Assist Grok in defining the engineering sub-tasks for the Godot Epic.
