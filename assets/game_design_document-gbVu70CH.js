const e=`# Game Design Document (GDD): Mobile Fortress
*An In-Depth Blueprint for a Wōkòu-Era Cooperative Tower Defense & 4X Strategy Game*

---

## 1. Executive Summary & Vision Statement

**Mobile Fortress** is a cooperative multiplayer 2D tower-defense and meta-4X game set during the Jiajing-era Wōkòu (倭寇) / Wakō pirate crisis (1540s–1560s) on the East Asian coast. Players coordinate to defend a coastal fortress network — a Main HQ/Citadel, Resource Outposts, and Trading Outposts — against raiding Wōkòu pirate fleets: mixed bands of Japanese rōnin swordsmen and Chinese/Korean pirate-smugglers striking by both land and sea. The defending garrison is drawn from an East Asian primary civilization (Ming China's coastal garrison by default; Japan or Joseon Korea as alternate settings) reinforced by a supporting Western trading-partner civilization (Portuguese by default — historically resident at Macau and the Zhejiang/Fujian coast in this exact period — with Spanish, Dutch, British, and French forces selectable as alternates). Success in combat feeds into a regional 4X-style territory control game where player-run coastal defense factions cooperate to secure the coastline, build fortifications, and manage economic assets.

### 1.1 The Gameplay Hybridization Imperative
In accordance with contemporary market realities, pure tower-defense titles suffer from limited retention. Mobile Fortress addresses this via a dual-loop framework:
*   **The Tactical Loop (Action/TD)**: A high-fidelity, real-time cooperative 2D tower defense screen spanning both land approach lanes and coastal/naval approach lanes. It utilizes Native UI overlays enclosing a high-performance gameplay canvas powered by a shared headless simulation engine.
*   **The Strategic Loop (4X Coastal Meta)**: A persistent, social-first political and military map of the mid-16th-century East Asian coast. Coastal defense factions capture territories, distribute resources, and coordinate multi-party counter-raids, driving long-term habit formation (D30+ retention).

\`\`\`mermaid
graph TD
    A[4X Coastal Map: Strategic Loop] -->|Unlocks Levels & Provides Resource Buffs| B(Co-Op Tower Defense: Tactical Loop)
    B -->|Generates Faction Influence & Materials| A
    B -->|Feeds Player Progression| C[Hero/Unit Gacha & Upgrades]
    C -->|Augments Tactical Performance| B
    C -->|Amplifies Faction Power| A
\`\`\`

### 1.2 Target Demographics & Motivations
*   **Primary Audience**: Mid-core strategy and RPG players (Male/Female, ages 18–45) seeking tactical depth without extreme cognitive exhaustion.
*   **Psychological Goal (UTAUT3 Alignment)**: Maximize **Hedonic Motivation** (visceral visual feedback, Ukiyo-e-influenced aesthetic with Age-of-Sail Western contact) and **Social Influence** (faction-level obligations, joint fortress defense) while minimizing **Effort Expectancy** (frictionless progression, auto-farm assistance, and clean native UI transitions).

---

## 2. Thematic Direction & Aesthetics

### 2.1 Visual Art Style (Ukiyo-e Woodblock, East-Asian-Coast + Age of Sail)
*   **Aesthetic Identity**: The game utilizes a stylized, premium 2D design inspired by classical East Asian woodblock print traditions (Ukiyo-e-influenced, reminiscent of Katsushika Hokusai and Utagawa Hiroshige for line work and composition). Characters and environments feature bold, dark line work, textured gradients, and parchment paper overlays. Western units and ships read as period-accurate 16th-century Iberian/Portuguese carrack-and-galleon design language rendered in the same woodblock style, not modern silhouettes — the two visual traditions are meant to visibly collide, since that collision *is* the setting.
*   **Visual Feedback**: A successfully repelled raid causes the environment to shift from a smoke-choked, storm-lit palette back to vibrant, hand-painted daylight colors, creating a highly satisfying sensory experience — reframed from the previous "spiritual purification" beat into a grounded "the raid broke, the coast is safe" beat.

### 2.2 Auditory Landscape
*   **Instrumentation**: Traditional East Asian instrumentation forms the acoustic core: Taiko drums for high-intensity defense phases, Shakuhachi (bamboo flute) and Shamisen (lute) for peaceful day/building cycles, and a weeping Biwa to build tension before boss waves. Sparse Western motifs — ship's bell chimes and a distant bugle/brass stinger — mark the arrival of Portuguese (or other Western allied) reinforcements, keeping the two traditions distinct in the mix rather than blended.
*   **Soundscapes**: Immersive natural audio (crickets chirping during day preparation, coastal wind and surf effects, creaking rigging and distant ship's bells at night).

---

## 3. Core Gameplay Loop & Mechanics

### 3.1 The Day/Night Gameplay Cycle
Each combat encounter operates on a dynamic cycle:
*   **Day Phase (Preparation & Fortification)**: Players repair structures, collect resources, and coordinate placement across both the Main HQ and its outposts.
*   **Night Phase (The Raid)**: Wōkòu pirate fleets assault the fortress network by land and sea. Players dynamically shift hero positions, activate combat abilities, and manage real-time path obstructions to protect the Main HQ, Resource Outposts, and Trading Outposts.

### 3.2 Base Structures

Losing the Main HQ ends the game; outposts are separately defendable and, if lost, only damage the economy — they do not end the run.

1.  **Main HQ / Citadel**: The primary fortress. Its HP reaching zero is the game-over condition.
2.  **Resource Outposts**: Inland land-based positions (farms, mines, garrisons) that generate the currency used to buy and deploy **land** units.
3.  **Trading Outposts**: Coastal harbor positions that generate the currency used to buy and deploy **naval** units.

### 3.3 Unit & Tower Classification
Towers are represented as active military units stationed along the fortress walls, inland approach lanes, and coastal waters:
1.  **Ming Garrison Spearmen (Melee/Blocker, land, East Asian primary civ)**: Placed directly on land paths. They slow down enemies and engage in melee combat, altering the local traversal cost.
2.  **Fo-lang-ji Cannon Crews (Ranged/Piercing, land)**: Deal high linear damage but have slow reload speeds — Ming-operated breech-loading swivel cannons adapted from captured Portuguese "Folangji" designs, a real technology transfer of this exact era. Effective when aligned along long straightaways or covering harbor approaches.
3.  **East Asian Archers (Ranged/Indirect, land)**: Fire over walls and terrain, dealing moderate single-target damage with high fire rates.
4.  **Veteran Commanders (Dynamic Units, land)**: Super-units with high mobility, styled after historical anti-Wōkòu commanders (e.g., a Qi Jiguang-inspired Ming general in the default setting). Players can manually command them to relocate to reinforce failing lanes or execute active ultimate skills.
5.  **Portuguese Arquebusiers (Ranged, land, Western supporting civ)**: Matchlock gunners fielded by the supporting Western civilization (Portuguese by default; Spanish/Dutch/British/French as alternates). Deal high linear damage but have slow reload speeds.
6.  **East Asian War Junks (Naval, primary civ)**: Coastal defense vessels that intercept Wōkòu raiding junks before they can land troops.
7.  **Western Galleons (Naval, Western supporting civ)**: Cannon-armed carracks/galleons that provide long-range bombardment against pirate fleets approaching Trading Outposts.

### 3.4 Flow-Field Pathfinding Engine
To support hundreds of enemy combatants — on land and at sea — simultaneously on mobile devices without battery drain or framerate stuttering, the pathfinding engine abandons classical $A^*$ in favor of a dynamic **Flow Field (Vector Field)**, applied independently to land approach lanes and coastal/naval approach lanes.

#### Pathfinding Mathematical Architecture
1.  **Integration Field (Dijkstra Map)**:
    A cost grid is maintained where traversable cells have a base cost of $1.0$, blocked cells have a cost of $\\infty$, and slowed/difficult cells (mudflats, shoals) have a cost of $2.5$. Radiation outwards from the goal node $G$ (the HQ or a targeted outpost) calculates the total travel cost $C(p)$ for every grid point $p$:
    $$C(p) = \\min_{n \\in \\text{Neighbors}(p)} \\left( C(n) + \\text{Cost}(p \\to n) \\right)$$
2.  **Flow Field Vector Generation**:
    The system calculates a normalized gradient vector field $V(p)$ indicating the optimal direction of movement for any entity situated on cell $p$:
    $$V(p) = -\\nabla C(p) = -\\left( \\frac{\\partial C}{\\partial x}, \\frac{\\partial C}{\\partial y} \\right)$$
    In discrete terms, for a cell $(x, y)$, the vector pointing to the neighbor with the minimum integrated cost is computed:
    $$V(x, y) = \\text{Normalize}\\left( \\arg\\min_{dx, dy \\in \\{-1, 0, 1\\}} C(x+dx, y+dy) - C(x, y) \\right)$$
3.  **Dynamic Grid Updates**:
    When a player places a blocking unit (e.g., a Ming Garrison Spearmen barricade, or a War Junk holding a strait), the local cost changes. The Dijkstra map is recomputed locally using a queue-based boundary expansion. Enemy entities query the vector of the tile they currently occupy:
    $$\\text{Velocity}_{\\text{entity}} = V(\\text{Tile}(x, y)) \\times \\text{Speed}_{\\text{entity}}$$

\`\`\`
[Spawn Gate] ---> [Tile (1.5, 0.5): Vector Right] ---> [Barricade: Cost 99.0]
                                                             | (Dijkstra recalculates)
                                                             v
                  [Tile (1.5, 0.5): Vector Down]  ---> [Cleared Lane: Cost 1.0] ---> [Fortress HQ]
\`\`\`

---

## 4. Multiplayer Netcode & Cloud Orchestration

Mobile Fortress features a **Server-Authoritative State Synchronization** model running on a headless C++ simulation core, ensuring parity between Android and iOS clients.

\`\`\`mermaid
sequenceDiagram
    participant ClientA as Android Client (Compose/SurfaceView)
    participant Server as GameLift Dedicated Server (C++ Core)
    participant ClientB as iOS Client (SwiftUI/SpriteKit)
    
    ClientA->>Server: Send Input Payload (Place Archer at x:5, y:2) via UDP
    Note over Server: Tick Simulation (100ms cycle)
    Note over Server: Update Dijkstra Maps & Flow Fields
    Server-->>ClientA: Broadcast Compressed State Diff (FlatBuffers Binary)
    Server-->>ClientB: Broadcast Compressed State Diff (FlatBuffers Binary)
    Note over ClientA: Deserialize & Smoothly Interpolate positions
    Note over ClientB: Deserialize & Smoothly Interpolate positions
\`\`\`

### 4.1 Serialization & Data Transport
*   **FlatBuffers (Zero-Copy Serialization)**: State updates are serialized into binary formats via Google's FlatBuffers library. Deserialization overhead on native clients is bypassed by traversing the raw byte stream directly from the FFI memory layout.
*   **Delta Compression**: The server only broadcasts changes (e.g., entity spawns, deaths, position updates) rather than the complete simulation frame, minimizing cellular bandwidth.

### 4.2 Cloud Orchestration via AWS GameLift FlexMatch
*   **Latency-Graduated Matchmaking**: Lobbies are assembled dynamically. The queue checks player pings to various AWS regions (e.g., \`eu-west-1\` in Ireland, \`us-east-1\` in Virginia). FlexMatch applies strict thresholds:
    *   *0–30s*: Latency $< 50\\text{ms}$ (Strict regional routing).
    *   *30–60s*: Latency $< 90\\text{ms}$ (Fallback to secondary regional clusters).
    *   *60s+*: Latency $< 120\\text{ms}$ (Cross-continental lobby matching).
*   **Spot Instance Mitigation**: The game server fleet runs on a mix of 70% Spot and 30% On-Demand instances (primarily \`c5.large\` and \`c5.xlarge\`). If a Spot termination notice is issued:
    1.  The instance notifies the GameLift SDK.
    2.  The matchmaking queue diverts new sessions to On-Demand fleets.
    3.  Active game sessions on the terminating instance are allowed up to 2 minutes to complete or are cleanly saved and migrated during a wave break.

---

## 5. Algorithmic Procedural Content Generation (PCG)

To support long-term replayability, coastal fortress battlefields — including their harbor approaches — are dynamically generated using constraint-satisfaction algorithms.

\`\`\`
+-------------------------------------------------------------+
|               PCG Environment Synthesis Pipeline            |
+-------------------------------------------------------------+
|                                                             |
|   1. Local Constraint Solver                                |
|      [Wave Function Collapse (WFC)]                         |
|      - Collapses tile superpositions based on local rules.  |
|      - Ensures cliff-to-cliff, road-to-road, shore-to-water |
|        adjacency.                                           |
|                                                             |
|                             |                               |
|                             v                               |
|                                                             |
|   2. Global Structural Optimization                         |
|      [Mixed Integer Linear Programming (MILP)]              |
|      - Verifies path traversability from spawns to the HQ   |
|        and outposts, on both land and sea.                  |
|      - Guarantees minimum path length and tactical metrics. |
|                                                             |
|                             |                               |
|                             v                               |
|                                                             |
|   3. Intelligent Editing Agent                               |
|      [PCGRL (Deep PPO Agent)]                               |
|      - Evaluates strategic depth (choke points, elevations).|
|      - Dynamically refines maps to match targeted difficulty.|
|                                                             |
+-------------------------------------------------------------+
\`\`\`

### 5.1 Local Constraints: Wave Function Collapse (WFC)
*   **Superposition**: Every grid cell starts as a set of all possible terrain tiles (Grass, Mountain, Road, Forest, Wall, Shoal, Open Water).
*   **Entropy Minimization**: The tile with the lowest Shannon entropy is collapsed first. 
*   **Constraint Propagation**: Adjacency rules (e.g., "Roads cannot spawn adjacent to Cliffs", "Open Water must border Shoal before Shore") propagate outward, reducing the superposition of neighboring cells.

### 5.2 Global Constraints: MILP Solver
To prevent WFC from generating beautiful but unplayable loops or dead-ends, a Mixed Integer Linear Programming (MILP) model runs alongside the solver.
*   **Objective**: Maximize path strategic depth while ensuring a valid flow field exists from $S_{\\text{spawn}}$ to $T_{\\text{HQ}}$.
*   **Decision Variables**: Binary variable $x_{ij} \\in \\{0, 1\\}$ representing if cell $(i, j)$ contains a path tile.
*   **Flow Conservation Constraint**:
    $$\\sum_{j} f_{ij} - \\sum_{k} f_{ki} = \\begin{cases} 1 & \\text{if } i = S_{\\text{spawn}} \\\\ -1 & \\text{if } i = T_{\\text{HQ}} \\\\ 0 & \\text{otherwise} \\end{cases}$$
    This guarantees that a path is always mathematically traversable.

### 5.3 Strategic Optimization: PCGRL (RL-based Map Generation)
A Deep Reinforcement Learning agent (trained via PPO) edits the WFC output to place optimal tactical points (chokepoints, towers, elevated sniper zones, coastal gun emplacements).
*   **State Space ($S$)**: A 2D grid containing local cell heights, path vectors, and tower coverage matrices.
*   **Action Space ($A$)**: Select cell $(x, y)$ and apply action (Raise elevation, Add bridge, Clear path).
*   **Reward Function ($R$)**:
    $$R = w_1 \\cdot (\\text{Path Length}) + w_2 \\cdot (\\text{Count of Chokepoints}) - w_3 \\cdot (\\text{Redundant Paths})$$

---

## 6. AI-Driven Dynamic Difficulty Adjustment (DDA)

To prevent player churn caused by boredom (game too easy) or frustration (game too hard), Mobile Fortress utilizes an automated, continuous difficulty calibration engine.

\`\`\`mermaid
graph LR
    subgraph Live Game Engine
        Player[Human Player Telemetry] -->|Inputs, Spacial Layout, Resource Hoarding| IA[Imitation Learning Agent]
    end
    subgraph Offline adversarial training
        IA -->|Cloned Playstyle| CompetitiveRL[Adversarial RL Agent]
        CompetitiveRL -->|Discovers Counters| TargetDifficulty[Optimal Counter-Policy]
    end
    TargetDifficulty -->|Adjusts Spawns & Lane Vectors| LiveGameEngine[Adjusted Enemy AI & Waves]
\`\`\`

### 6.1 Two-Agent Neural Network Framework
*   **Imitation Agent (The Shadow Clone)**:
    Observes player metrics (average response time to breaches, placement clusters, resource spending velocity, upgrade priority). The agent undergoes supervised training to replicate the player's playstyle in real-time.
*   **Competition Agent (The Tactician)**:
    Runs in the background, playing against the Imitation Agent. It searches for optimal wave mixtures (e.g., spawning fast-moving Wōkòu raiding skiffs to exploit a player's lack of coastal artillery).
*   **Implementation**: Once the Competition Agent finds a counter-strategy, the game engine adapts wave spawning metrics. This creates a highly personalized, dynamic threat index without altering basic enemy health or damage values.

### 6.2 Continuous Modulation via PPO
The DDA system modulates continuous factors (spawn rate modifiers, pathfinding reaction delays, stealth unit visibility radii) using Proximal Policy Optimization:
*   **Tension Reward Model**: The RL reward is maximized when the player's HQ health drops below 30% but recovers to win, maintaining a state of high physiological arousal and hedonic enjoyment.

---

## 7. LiveOps, Retention & Monetization

### 7.1 Offer Personalization: Contextual Multi-Armed Bandits (CMAB)
Rather than statically offering microtransactions, the game uses the **LinUCB** algorithm to determine the optimal resource or cosmetic bundle to offer a player during wave breaks.

#### LinUCB Mathematical Formulation
For each user context vector $x_{a}$ (containing D1–D7 retention flags, current coin deficit, favorite class usage ratio, and past purchase history):
1.  Estimate the expected conversion probability for each store offer $a$:
    $$p_{t, a} \\equiv x_{t, a}^T \\hat{\\theta}_a + \\alpha \\sqrt{x_{t, a}^T A_a^{-1} x_{t, a}}$$
    Where $A_a = D_a^T D_a + I_d$ (the covariance matrix of historical context values), $\\hat{\\theta}_a$ represents the ridge regression weights of arm $a$, and $\\alpha$ is a hyperparameter managing the balance of exploration vs exploitation.
2.  The store displays the bundle $a_t$ maximizing the upper confidence bound:
    $$a_t = \\arg\\max_{a} \\left( x_{t, a}^T \\hat{\\theta}_a + \\alpha \\sqrt{x_{t, a}^T A_a^{-1} x_{t, a}} \\right)$$

### 7.2 Early Churn Forecasting (Weibull Survival Analysis)
To prevent players from churning before D30, a parametric survival model forecasts time-to-churn:
$$S(t | x) = \\exp\\left( -\\left( \\lambda(x) \\cdot t \\right)^\\beta \\right)$$
Where $\\lambda(x) = \\exp(\\gamma^T x)$ scales based on context parameters (e.g., number of failed co-op matches, average time spent waiting in matchmaking). If $S(\\text{Day 14}) < 0.35$, the backend triggers an automated retention event:
*   Granting a free temporary Legendary Commander hire.
*   Issuing a cooperative faction assistance quest.

### 7.3 Community Stability: Temporal Graph Neural Networks (TGNN)
*   **Player Social Graph**: Nodes represent players; edges represent cooperative games played together.
*   **Churn Cascade Mitigation**: When a highly active hub node (e.g., a Faction Leader or active raid-response coordinator) shows signs of high churn risk, the TGNN flags all connected neighbor nodes. The server automatically routes group buffs and shared faction milestones to that network cluster to preserve community ties.

---

## 8. Mathematical Optimization Methods (Swarm Intelligence & Evolutionary Algorithms)

To support complex strategic systems in both the 4X Strategic Loop and procedural content generation, Mobile Fortress implements classical mathematical optimization methods alongside its machine learning models.

\`\`\`
+-------------------------------------------------------------+
|        Mathematical Optimization Systems Overview           |
+-------------------------------------------------------------+
|                                                             |
|   1. Genetic Algorithms (GA)                                |
|      [Procedural Level Design]                              |
|      - Optimizes fortress wall barricade structures.        |
|      - Maximizes pathing distance within budget constraint. |
|                                                             |
|                             |                               |
|                             v                               |
|                                                             |
|   2. Ant Colony Optimization (ACO)                          |
|      [4X Strategy Supply Routing]                           |
|      - Dynamically routes convoys across coastal territory. |
|      - Balances path distance with local threat levels.      |
|                                                             |
+-------------------------------------------------------------+
\`\`\`

### 8.1 Genetic Algorithms (GA) for Fortress Wall Layout Optimization
In the procedural generation pipeline, creating a challenging layout for defensive levels is formulated as a constrained evolutionary search. The game engine must evolve a layout of static blockages (walls) that maximizes the path distance for enemies while adhering to building budget constraints.
*   **Chromosome Representation**: A binary array $C = \\{c_1, c_2, \\dots, c_N\\}$ of length $N$ (where $N = \\text{Width} \\times \\text{Height}$ of the grid), where $c_i = 1$ indicates a wall and $c_i = 0$ indicates open ground.
*   **Fitness Function**: Maximize the shortest path length from spawn points to the HQ while penalizing layouts that exceed the maximum wall budget $B$ or block the path entirely:
    $$f(C) = \\begin{cases} \\text{PathLength}(S_{\\text{spawn}} \\to T_{\\text{HQ}}) & \\text{if } \\sum_{i=1}^N c_i \\le B \\text{ and PathExists}(S \\to T) \\\\ 0 & \\text{otherwise} \\end{cases}$$
*   **Operators**:
    *   *Tournament Selection*: Lobbies of size $k=5$ compete to select parents based on fitness.
    *   *Uniform Crossover*: Parent chromosomes swap tiles with a probability of $p_c = 0.5$ to combine path features.
    *   *Spatial Mutation*: Individual bits are flipped with probability $p_m = 0.05$. To maintain spatial coherence, mutation is weighted to expand existing wall clusters rather than scattering random single walls.

### 8.2 Ant Colony Optimization (ACO) for Strategic Supply Line Routing
In the 4X Strategic Loop, players coordinate raw material convoys (e.g., iron, timber, rice, silver) across dynamic coastal provinces. Ant Colony Optimization is run on the server to automatically determine the optimal paths for supply convoys, bypassing pirate-contested waters and high-threat patrol lines.
*   **Graph Definition**: The East Asian coastline (the Zhejiang/Fujian littoral and surrounding waters in the default Ming setting) is represented as a weighted graph $G = (V, E)$, where vertices $V$ are coastal provinces/harbors and edges $E$ are connecting trade routes. Each route $(i, j)$ has a distance $d_{ij}$ and a threat modifier $h_{ij} \\in [1.0, 10.0]$ representing active Wōkòu skirmish activity.
*   **State Transition Probability**: A simulated convoy $k$ at province $i$ decides to move to province $j$ based on pheromone concentration $\\tau$ and a route visibility heuristic $\\eta$:
    $$p_{ij}^k(t) = \\frac{[\\tau_{ij}(t)]^\\alpha [\\eta_{ij}]^\\beta}{\\sum_{l \\in \\text{allowed}_k} [\\tau_{il}(t)]^\\alpha [\\eta_{il}]^\\beta}$$
    Where the visibility heuristic is defined as the inverse of path distance scaled by threat:
    $$\\eta_{ij} = \\frac{1}{d_{ij} \\cdot h_{ij}}$$
    The parameters $\\alpha$ and $\\beta$ control the relative influence of historical player success (pheromones) versus static route safety (heuristics).
*   **Pheromone Evaporation & Deposition**: After all convoys complete traversal, pheromones evaporate, and routes successfully navigated deposit new pheromones proportional to the volume of materials safely delivered:
    $$\\tau_{ij}(t+1) = (1 - \\rho)\\tau_{ij}(t) + \\sum_{k=1}^M \\Delta\\tau_{ij}^k(t)$$
    $$\\Delta\\tau_{ij}^k(t) = \\begin{cases} \\frac{Q}{\\text{TotalCost}_k} & \\text{if convoy } k \\text{ successfully navigated edge } (i, j) \\\\ 0 & \\text{otherwise} \\end{cases}$$
    Where $\\text{TotalCost}_k = \\sum d_{ij} \\cdot h_{ij}$ along the route, and $Q$ is a scaling constant.

---

## 9. Codebase Analysis & Integration Roadmap

### 9.1 Current Codebase State
*   **Android (\`android/\`)**:
    *   Entry: [MainActivity.kt](file:///home/pkhunter/Repositories/Repos/Project-Mobile-Fortress/android/app/src/main/java/com/acfharbinger/mobilefortress/MainActivity.kt) hosting [GameView.kt](file:///home/pkhunter/Repositories/Repos/Project-Mobile-Fortress/android/app/src/main/java/com/acfharbinger/mobilefortress/GameView.kt) (SurfaceView).
    *   Loop: [GameLoop.kt](file:///home/pkhunter/Repositories/Repos/Project-Mobile-Fortress/android/app/src/main/java/com/acfharbinger/mobilefortress/GameLoop.kt) running a fixed-timestep game thread.
    *   Engine: [GameEngine.kt](file:///home/pkhunter/Repositories/Repos/Project-Mobile-Fortress/android/app/src/main/java/com/acfharbinger/mobilefortress/engine/GameEngine.kt) rendering a single bouncing \`Ball\` entity.
    *   State: Bare [GameState.kt](file:///home/pkhunter/Repositories/Repos/Project-Mobile-Fortress/android/app/src/main/java/com/acfharbinger/mobilefortress/engine/GameState.kt) recording coordinate positions.
*   **iOS (\`ios/\`)**:
    *   Entry: \`MyGameApp.swift\` hosting SpriteKit's \`SKScene\` within a SwiftUI view.
    *   Engine: \`GameScene.swift\` rendering a basic moving sprite and shooting projectiles.
*   **Core (\`core/\`)**:
    *   Contains static asset specifications and basic game state descriptions in [game-state-machine.md](file:///home/pkhunter/Repositories/Repos/Project-Mobile-Fortress/core/src/game-state-machine.md).
    *   No shared compiled library; each app implements logic independently.

### 9.2 Architectural Gaps
1.  **Simulation Divergence**: The physics and logical calculations are completely decoupled. Android runs a custom Canvas looping calculation; iOS runs SpriteKit's physics engine.
2.  **No Netcode Implementation**: Real-time communication structures, UDP bindings, and delta-compression frameworks do not exist.
3.  **No Shared Simulation Engine**: The planned C++ core needs initialization and integration via JNI (Android) / Swift C++ interop (iOS) bindings.
4.  **No Procedural Assets or ML Models**: The WFC and Reinforcement Learning architectures are completely unrepresented in the code.

### 9.3 Integration Roadmap

\`\`\`
+-----------------------------------------------------------------------------------+
| Phase 1: Native Parity & Setup                                                    |
| - Standardize game-state machine states (Menu, Playing, Paused, GameOver).         |
| - Build shared levels asset JSON reading framework into both native modules.      |
+-----------------------------------------------------------------------------------+
                                         |
                                         v
+-----------------------------------------------------------------------------------+
| Phase 2: C++ Core Simulation Engine                                               |
| - Create C++20 library containing headless ECS simulation and pathfinding (Flow Field)|
| - Build JNI/Swift-C++-interop bindings. Expose simulation states as FlatBuffers.   |
| - Replace native Canvas/SpriteKit update loops with calls to the C++ simulation.   |
+-----------------------------------------------------------------------------------+
                                         |
                                         v
+-----------------------------------------------------------------------------------+
| Phase 3: Cooperative Netcode & AWS Infrastructure                                 |
| - Integrate UDP socket layers. Implement delta compressed state replication.      |
| - Spin up Amazon GameLift integration. Build FlexMatch rulesets.                   |
+-----------------------------------------------------------------------------------+
                                         |
                                         v
+-----------------------------------------------------------------------------------+
| Phase 4: Machine Learning & Mathematical Optimization Core                         |
| - Train and deploy offline PCGRL PPO agent. Deploy nested WFC local solvers.      |
| - Integrate the Imitation-Adversarial DDA loops on local player devices.          |
| - Deploy Genetic Algorithms for dynamic layout generation and ACO for supply route |
|   optimization on server-authoritative matchmaking.                                |
+-----------------------------------------------------------------------------------+
\`\`\`

---
*Document Version: 3.1*  
*Target Platforms: Android API 24+, iOS 16+*  
*Authoritative Reference: .agent/AGENTS.md*
`;export{e as default};
