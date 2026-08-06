# Art Bible: Mobile Fortress
*Ukiyo-e Visual Styles, Native HUD Wireframes, and 2D Animation Guidelines*

---

## 1. Visual Style & Art Direction

Mobile Fortress uses a distinct 2D aesthetic inspired by 16th-century Japanese *Ukiyo-e* woodblock prints. The visual identity incorporates parchment paper backdrops, bold brushwork ink contours, and traditional watercolor paint color palettes.

```
+--------------------------------------------------------------+
|                    VISUAL TRANSITION STATE                   |
+--------------------------------------------------------------+
|                                                              |
|   Yokai Defiled Zone       ===>       Purified Land          |
|   - Monochromatic ash                 - Rich watercolors     |
|   - Dark crimson outlines             - Glowing gold sparks  |
|   - Heavy smoke/fog                   - Cherry blossoms      |
|                                                              |
+--------------------------------------------------------------+
```

### 1.1 Color Palette Guidelines
*   **Ink Outlines**: Soft charcoal black (`#1c1a17`) rather than absolute digital black.
*   **Parchment Texture**: Distressed tan base (`#e8d8b8`) used for level UI and backdrops.
*   **Sengoku Armor Accents**: Crimson (`#d90429`), gold (`#f4d35e`), and indigo (`#1d3557`).
*   **Yokai Spirits**: Ghostly purple (`#c77dff`) and pale toxic green (`#70e000`).

---

## 2. UI/UX Wireframe Guidelines

The user interface wraps around the native game rendering canvases (`SurfaceView` on Android, `SKScene` on iOS).

### 2.1 Native HUD Layers
*   **Daimyo Keep Health Indicator**: Top-left, formatted like a family crest (Kamom) outline, filling with red lacquer.
*   **Unit Placement Panel**: Bottom deck, horizontal scrolling list of available defenders (Ashigaru, Archers, Shamans) with card borders mimicking ink stamps.
*   **Tactical Radar Map**: Top-right, circular projection displaying the active vector pathways and spawn gates.

```
+-------------------------------------------------------------+
| [Crest Health: 100%]                              [Radar Map]|
|                                                             |
|                                                             |
|                   (Native Canvas Area)                      |
|                                                             |
|                                                             |
|                                                             |
|                                                             |
| [Card: Ashigaru]  [Card: Gunner]  [Card: Shaman]            |
| (Cost: 25 Gold)   (Cost: 75 Gold)  (Cost: 60 Gold)          |
+-------------------------------------------------------------+
```

---

## 3. 2D Sprite Animation Requirements

All characters and enemies are rendered using highly optimized 2D spritesheets to prevent memory overhead during massive sieges.

### 3.1 Spritesheet Animation States
Every defender and Yokai character requires:
1.  **Idle**: 8-frame loop representing natural breathing and weapon posturing.
2.  **Locomotion (Run/Sprint)**: 12-frame looping walk/run cycles, incorporating dynamic dust cloud particles behind feet.
3.  **Attack Execution**: 10-frame high-intensity strike pose, accompanied by sword swoops or matchlock smoke particle spawns.
4.  **Death/Purification**: 6-frame dissolving animation where entities fade into spiritual particles.

---
*Document Version: 2.0*  
*Authoritative Reference: design/game_design_document.md*
