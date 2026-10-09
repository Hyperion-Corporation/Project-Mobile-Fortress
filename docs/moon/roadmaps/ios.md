# iOS / Mobile Export Roadmap

**Owner:** TBD (macOS CI owned by collaborator when they join)

**2026-08-11 note:** Primary game client is **Godot 4** exported to iOS 17+. The existing SpriteKit `ios/MyGame` tree is **legacy template scaffolding** — keep for reference until Godot export replaces it; do not invest in SpriteKit fortress-defense rebuilds.

## Targets

- **iOS 17+** (and Android 13+ on the Godot Android export path)
- Offline campaign playable; online features optional

## Done (template scaffolding — historical)

- SpriteKit `GameScene`, SwiftUI chrome, `GameManager`, level JSON loader, XCTest skeleton, shared scheme for CI.

## Pending (Godot path)

| # | Item | Effort | Status |
| --- | --- | --- | --- |
| IOS1 | Godot iOS export project + signing notes | M | 🚧 **Partial** — iOS preset in `game/export_presets.cfg` (min 17); Android APK path verified on Linux; iOS export needs macOS |
| IOS2 | Touch/UI polish for dual-front isometric controls on iPhone/iPad | M | 🚧 **Partial** — Godot dual-grid touch placement (G10) landed; not device-tested on iPhone/iPad. Phone-scale touch targets (≥48dp rendered window pixels in width and height) and responsive reflow shipped across Main Menu, Settings Dialog, and Battle HUD (T46/T59 / U8). T70 (#12) resolved dual-grid landscape & portrait containment: LandGrid and SeaGrid reflow side-by-side in landscape ($s \approx 0.559$) and stacked in portrait with zero off-canvas clipping, zero inter-front overlap, and zero HUD overlap across `1280×720`, `844×390`, `720×1280`, and `390×844`. Documented ergonomics finding: phone-scale cell height drops below 40px (e.g. 44.3×22.1 px rendered on 844×390 window, 39.0×19.5 px on 390×844) due to 2:1 isometric aspect; mitigated by G10 drag-and-preview touch affordance. On-device iOS validation remains open. |
| IOS3 | Consume shared C++ sim via godot-cpp/module (not UniFFI) | M | 🚧 **Partial** — Android arm64 `.so` is built on Linux (T72, NDK r27c, `android.debug.arm64` / `android.release.arm64`); no ios.arm64 binary is declared yet; dylib build remains on macOS |
| IOS4 | Haptics / platform services as needed | S | 📋 Deferred |
| IOS5 | App Store Connect / export automation on macOS CI | M | 📋 When collaborator joins |
| IOS6 | Co-Op networking client (post Slice-0) | L | 📋 Deferred |
| IOS7 | Feature parity with Android Godot export | M | 📋 Ongoing |

Legacy SpriteKit roadmap items (rebuild GameScene as TD, etc.) are **superseded** by Godot dual-front work in [`vertical_slice.md`](vertical_slice.md) and [`gameplay.md`](gameplay.md).
