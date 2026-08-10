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
| IOS1 | Godot iOS export project + signing notes | M | 📋 Pending |
| IOS2 | Touch/UI polish for dual-front isometric controls on iPhone/iPad | M | 📋 Pending |
| IOS3 | Consume shared C++ sim via godot-cpp/module (not UniFFI) | M | 📋 Pending |
| IOS4 | Haptics / platform services as needed | S | 📋 Deferred |
| IOS5 | App Store Connect / export automation on macOS CI | M | 📋 When collaborator joins |
| IOS6 | Co-Op networking client (post Slice-0) | L | 📋 Deferred |
| IOS7 | Feature parity with Android Godot export | M | 📋 Ongoing |

Legacy SpriteKit roadmap items (rebuild GameScene as TD, etc.) are **superseded** by Godot dual-front work in [`vertical_slice.md`](vertical_slice.md) and [`gameplay.md`](gameplay.md).
