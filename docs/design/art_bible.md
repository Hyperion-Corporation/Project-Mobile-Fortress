# Art Bible: Mobile Fortress
*Ukiyo-e-Influenced Visual Styles, Native HUD Wireframes, and 2D Animation Guidelines*

---

## 1. Visual Style & Art Direction

Mobile Fortress uses a distinct 2D aesthetic inspired by 16th-century East Asian *Ukiyo-e*-style woodblock prints, deliberately collided with 16th-century Iberian Age-of-Sail imagery for the Western-allied units and ships. The visual identity incorporates parchment paper backdrops, bold brushwork ink contours, and traditional watercolor paint color palettes for both traditions.

```
+--------------------------------------------------------------+
|                    VISUAL TRANSITION STATE                   |
+--------------------------------------------------------------+
|                                                              |
|   Raid in Progress         ===>       Coast Secured          |
|   - Smoke-choked, storm-lit           - Rich watercolors     |
|   - Dark crimson outlines             - Clear gold daylight  |
|   - Heavy smoke/fog                   - Calm harbor waters   |
|                                                              |
+--------------------------------------------------------------+
```

### 1.1 Color Palette Guidelines
*   **Ink Outlines**: Soft charcoal black (`#1c1a17`) rather than absolute digital black.
*   **Parchment Texture**: Distressed tan base (`#e8d8b8`) used for level UI and backdrops.
*   **East Asian Garrison Accents**: Crimson (`#d90429`), gold (`#f4d35e`), and indigo (`#1d3557`).
*   **Western Allied Accents**: Deep navy (`#14213d`) and weathered brass (`#c9a227`), evoking Portuguese carrack livery without reading as modern.
*   **Wōkòu Raider Accents**: Ash grey (`#4a4e69`) and dull crimson (`#9d0208`) — grounded, not supernatural.

---

## 2. UI/UX Wireframe Guidelines

The user interface wraps around the native game rendering canvases (`SurfaceView` on Android, `SKScene` on iOS).

### 2.1 Native HUD Layers
*   **HQ Health Indicator**: Top-left, formatted like a fortress-crest outline, filling with red lacquer.
*   **Outpost Status Strip**: Top-center, compact icons for each active Resource Outpost and Trading Outpost showing HP and currency generation rate.
*   **Unit Placement Panel**: Bottom deck, horizontal scrolling list of available defenders (Ming Garrison Spearmen, Fo-lang-ji Cannon Crews, Portuguese Arquebusiers) with card borders mimicking ink stamps.
*   **Tactical Radar Map**: Top-right, circular projection displaying the active land/naval vector pathways and spawn gates.

```
+-------------------------------------------------------------+
| [HQ Health: 100%]  [Outposts: 3/3]                 [Radar Map]|
|                                                             |
|                                                             |
|                   (Native Canvas Area)                      |
|                                                             |
|                                                             |
|                                                             |
|                                                             |
| [Card: Spearmen]  [Card: Fo-lang-ji]  [Card: Arquebusier]   |
| (Cost: 25 Gold)   (Cost: 75 Gold)     (Cost: 60 Gold)       |
+-------------------------------------------------------------+
```

---

## 3. 2D Sprite Animation Requirements

All characters and enemies are rendered using highly optimized 2D spritesheets to prevent memory overhead during massive raids.

### 3.1 Spritesheet Animation States
Every defender and Wōkòu raider character requires:
1.  **Idle**: 8-frame loop representing natural breathing and weapon posturing.
2.  **Locomotion (Run/Sprint)**: 12-frame looping walk/run cycles, incorporating dynamic dust cloud particles behind feet (or wake ripples for naval units).
3.  **Attack Execution**: 10-frame high-intensity strike pose, accompanied by sword swoops, matchlock/arquebus smoke particle spawns, or cannon-fire flashes.
4.  **Defeat**: 6-frame collapse/sink animation — land units fall, naval units list and sink beneath the waterline.

---
*Document Version: 3.0*  
*Authoritative Reference: docs/design/game_design_document.md*
