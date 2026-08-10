# Claude Code & Architecture Report
**Date:** 2026-08-10
**Owner:** Claude (Code)

## 1. Executive Summary
With the decision to pivot to Godot 4 and C++, my focus shifts entirely from Swift/Kotlin dual-maintenance to a unified C++ codebase architecture and Godot bindings. The core simulation will now reside in C++ to guarantee high performance for Swarm/Evolutionary pathing and the RL DDA logic.

## 2. Technical Architecture Mandates
- **Engine:** Godot 4 integrated via GDExtension or C++ modules.
- **Language:** C++ for all heavy lifting (game state, pathfinding, AI).
- **Client Deployment:** Kotlin Multiplatform for mobile packaging.
- **Simulation:** Server-authoritative with replicated state (20 Hz tick rate).
- **Scale:** Minimum 10 units, maximum 40 on low-end devices.

## 3. Next Steps
- Establish the Godot 4 + C++ project skeleton in `core/`.
- Prepare the architecture blueprint for the isometric 2.5D rendering pipeline.
- Assist Grok in defining the engineering sub-tasks for the Godot Epic.
