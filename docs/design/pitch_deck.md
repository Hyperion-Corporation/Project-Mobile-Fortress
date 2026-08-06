# Pitch Deck: Mobile Fortress
*Unique Selling Proposition, Demographics, and Technical Innovations*

---

## 1. Product Vision & Value Proposition

**Mobile Fortress** merges tactical, real-time cooperative 2D tower defense with a persistent 4X coastal-territory control game set during the 1540s–1560s Wōkòu pirate crisis on the East Asian coast.

```
+--------------------------------------------------------------+
|                  CORE VALUE PROPOSITION                      |
+--------------------------------------------------------------+
|                                                              |
|   Cooperative TD Combat      Persistent 4X Coastal Map       |
|   - Real-time placement      - Secure coastal provinces      |
|   - Land + Naval Flow Fields - Build fortress assets         |
|                                                              |
+--------------------------------------------------------------+
```

*   **Unique Selling Proposition (USP)**: A dual-loop strategy game that bridges the immediate satisfaction of active fortress defense — against both land raiders and pirate fleets — with the long-term community obligations of cooperative coastal-territory conquest. An East Asian primary civilization (Ming China by default) fights alongside a supporting Western civilization (Portuguese by default, with Spanish/Dutch/British/French alternates), a historically grounded pairing unique among mobile TD titles. Backed by advanced math optimization models (Flow Fields, WFC PCG, Adversarial DDA) ensuring infinite replayability and seamless performance on mobile hardware.

---

## 2. Target Market & Demographics

Mobile Fortress targets three core mobile player segments:

1.  **Tower Defense & Tactical Fans**: Players of *Arknights* or *Kingdom Rush* seeking cooperative multiplayer capabilities and deep character gacha options.
2.  **Mid-Core 4X Strategists**: Players of *Last War* or *Whiteout Survival* who enjoy guild coordination but are fatigued by simple arcade mini-games and want authentic tactical combat.
3.  **Cozy Base Builders**: Players who enjoy nurturing bases, beautifying structures, and co-op PvE gameplay without stressful PvP destruction (Self-Determination Theory fulfillment).

---

## 3. Core Technical Innovations

Mobile Fortress leverages cutting-edge game development technologies to create a high-performance, responsive simulation:

### 3.1 Low-CPU Dijkstra Flow-Field Pathfinding (Land + Naval)
Standard pathfinders choke when moving hundreds of entities on mobile CPUs across both land lanes and coastal waters. Our shared Rust core computes optimal vectors once per grid, keeping calculation costs at $O(1)$ regardless of entity size.

### 3.2 Offline Adversarial DDA
Instead of inflating enemy HP pools, a background Competitive RL agent plays against a clone of the player's strategy, deploying custom wave counters (land raider surges, naval flanking runs) to maintain high strategic tension.

### 3.3 Zero-Overhead UniFFI Rust Core
Bypasses cross-platform engine overhead by running a headless simulation core in Rust, communicating via zero-copy binary serialization with native Kotlin and Swift UI shells.

---
*Document Version: 3.0*  
*Authoritative Reference: docs/design/game_design_document.md*
