# Pitch Deck: Mobile Fortress
*Unique Selling Proposition, Demographics, and Technical Innovations*

---

## 1. Product Vision & Value Proposition

**Mobile Fortress** merges tactical, real-time cooperative 2D tower defense with a persistent 4X clan territory control game set in 1520s Sengoku Japan.

```
+--------------------------------------------------------------+
|                  CORE VALUE PROPOSITION                      |
+--------------------------------------------------------------+
|                                                              |
|   Cooperative TD Combat      Persistent 4X Clan Map          |
|   - Real-time placement      - Capture provinces together    |
|   - Flow Field pathfinding   - Build fortress assets         |
|                                                              |
+--------------------------------------------------------------+
```

*   **Unique Selling Proposition (USP)**: A dual-loop strategy game that bridges the immediate satisfaction of active castle defense with the long-term community obligations of cooperative clan territory conquest. Backed by advanced math optimization models (Flow Fields, WFC PCG, Adversarial DDA) ensuring infinite replayability and seamless performance on mobile hardware.

---

## 2. Target Market & Demographics

Mobile Fortress targets three core mobile player segments:

1.  **Tower Defense & Tactical Fans**: Players of *Arknights* or *Kingdom Rush* seeking cooperative multiplayer capabilities and deep character gacha options.
2.  **Mid-Core 4X Strategists**: Players of *Last War* or *Whiteout Survival* who enjoy guild coordination but are fatigued by simple arcade mini-games and want authentic tactical combat.
3.  **Cozy Base Builders**: Players who enjoy nurturing bases, beautifying structures, and co-op PvE gameplay without stressful PvP destruction (Self-Determination Theory fulfillment).

---

## 3. Core Technical Innovations

AISS leverages cutting-edge game development technologies to create a high-performance, responsive simulation:

### 3.1 Low-CPU Dijkstra Flow-Field Pathfinding
Standard pathfinders choke when moving hundreds of entities on mobile CPUs. Our shared Rust core computes optimal vectors once per grid, keeping calculation costs at $O(1)$ regardless of entity size.

### 3.2 Offline Adversarial DDA
Instead of inflating enemy HP pools, a background Competitive RL agent plays against a clone of the player's strategy, deploying custom wave counters to maintain high strategic tension.

### 3.3 Zero-Overhead UniFFI Rust Core
Bypasses cross-platform engine overhead by running a headless simulation core in Rust, communicating via zero-copy binary serialization with native Kotlin and Swift UI shells.

---
*Document Version: 2.0*  
*Authoritative Reference: design/game_design_document.md*
