# Art Bible: AI Soccer Simulator (AISS)
*Visual Style, UI/UX Guidelines, and Character Animation Standards for UE5*

---

## 1. Visual Style & Art Direction

AISS targets a hyper-realistic, televised-broadcast visual representation. The engine leverages Unreal Engine 5's Nanite and Lumen features to create an immersive, photorealistic matchday atmosphere.

```
+--------------------------------------------------------------+
|                    PBR MATERIAL PIPELINE                     |
+--------------------------------------------------------------+
|                                                              |
|   Turf Materials           Kit Textiles          Leather Ball|
|   - Multi-layered grass    - Anisotropic weave   - Scratched |
|   - Dynamic mud/wetness    - Subsurface sweat    - Specular  |
|                                                              |
+--------------------------------------------------------------+
```

### 1.1 Rendering Pipeline Specs
*   **Global Illumination**: *Lumen* is used for real-time stadium light bounces, adjusting dynamically as the sun moves during day-night cycles.
*   **Geometry Optimization**: *Nanite* is enabled for high-poly stadium seat geometry, crowd actors, and complex architectural structures.
*   **Post-Processing**: Film grain, chromatic aberration, and high-quality motion blur are balanced to match standard television broadcast cameras (e.g., dynamic depth of field focusing on the ball owner).

---

## 2. UI/UX Wireframe & Design Guidelines

The interface consists of two distinct segments: the **Match HUD** (overlay during play) and the **Tactical Console** (for managing team strategy).

### 2.1 The Match HUD Layout
*   **Score/Timer Board**: Positioned top-left, flat design, semi-transparent black backing (`#111116` at 80% opacity), with team logo markers.
*   **Radar Map (Mini-Pitch)**: Bottom-center, circular 2D orthographic projection of all 22 player positions.
*   **Manager Console Bar**: Bottom-left, displays current tactical posture (e.g., Pressing Line, Attack Mentality) and a slider for team focus.

```
+-------------------------------------------------------------+
| [Score Board 2 - 1]                                         |
| [Time: 74:12]                                               |
|                                                             |
|                                                             |
|                                                             |
|                                                             |
|                                                             |
|                                                             |
|                                                             |
| (Strategy Panel)                    [  (Pitch Radar)  ]     |
| [Pressing Line: High]                                       |
+-------------------------------------------------------------+
```

---

## 3. Character Animation & Kinematics

Animation quality directly impacts physics fidelity. The game uses a hybrid animation blueprint integrating standard blend spaces with procedural IK solvers.

### 3.1 Motion Matching locomotion
*   Rather than manual transitions between animations, the locomotion engine uses **Motion Matching** to query a data library of pre-recorded motion captures.
*   The system matches current velocity, future path direction, and stride posture, yielding fluid turns, rapid decelerations, and realistic foot planting on the turf.

### 3.2 Procedural Foot-to-Ball Alignment
*   **Full-Body IK (Control Rig)**: Handles player interactions with the ball.
*   **Foot Placement**: Inverse Kinematics aligns player feet dynamically with uneven terrain or mud surfaces.
*   **Kicking Pose**: When an agent executes a kick, the leg trajectory is calculated procedurally using foot-to-ball intercept coordinates to guarantee the foot visually impacts the ball model at the exact physics contact point.

---
*Document Version: 1.0*  
*Authoritative Reference: design/GDD.md*
