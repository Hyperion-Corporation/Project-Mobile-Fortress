# Glossary

| Term | Meaning |
| --- | --- |
| ADR | Architecture Decision Record — a short document capturing a significant, hard-to-reverse technical decision and its rationale. |
| AGP | Android Gradle Plugin — the Gradle plugin (`com.android.application`) that builds Android app modules. |
| AAB | Android App Bundle — the publishing format (`.aab`) uploaded to the Play Store, superseding raw APK uploads. |
| Fixed timestep | A game loop pattern where the simulation (`update()`) always advances by the same fixed time increment regardless of actual frame rate, keeping physics/logic deterministic. |
| `GameLoop` | The Android client's dedicated thread running the fixed-timestep update/render cycle for the `SurfaceView` game surface. |
| Interpolation (rendering) | Blending between the previous and current simulation state when rendering happens more often than fixed updates, for smoother visuals. |
| `SurfaceView` | An Android View subclass that provides a dedicated drawing surface on a separate thread from the UI thread — the rendering approach the Android client uses for the game surface. |
| R8 | Android's code shrinker/obfuscator/optimizer, applied to `release` builds. |
| Play Store track | A release channel in Google Play Console (internal, closed, open, production) that a signed AAB is promoted through. |
| SpriteKit | Apple's first-party 2D game framework — the rendering approach the iOS client uses for the game surface (`ios/MyGame/Scenes/GameLevel/GameScene.swift`). |
| `SKScene` | SpriteKit's scene class; its `update(_:)` method is called once per display refresh — the iOS equivalent of Android's `GameLoop` tick, without a hand-rolled thread. |
| `xcodebuild` | Apple's command-line build tool for Xcode projects — used by `just ios-build`/`ios-test`/`ios-archive` and the `ios-test` CI job. |
| `.xcarchive` | The archived-build format `xcodebuild archive` produces, the input to exporting a signed `.ipa` for TestFlight/App Store distribution. |
| `game/` | The shared-assets-and-spec module — canonical raw game data plus a documented (not yet compiled) state-machine/level-schema spec both clients implement independently today. See `game/README.md` and [`moon/roadmaps/shared_core.md`](moon/roadmaps/shared_core.md) for the planned C++ core. |
| Flow Field | A vector-field pathfinding technique that computes one movement direction per grid tile (via a Dijkstra distance map) instead of a per-unit path — lets hundreds of siege units navigate for roughly the cost of one pathfinding pass. See [`moon/roadmaps/gameplay.md`](moon/roadmaps/gameplay.md). |
| ECS | Entity-Component-System — a data-oriented architecture (entities as IDs, components as plain data, systems as stateless functions) used in Mobile Fortress' planned C++ core via [EnTT](https://github.com/skypjack/entt). |
| EnTT | A header-only C++ ECS library — provides the sparse-set entity/component storage for the planned shared simulation core. |
| FlatBuffers | Google's zero-copy, cross-language serialization format — used for state snapshots crossing the C++ core's JNI (Android) / Swift C++ interop (iOS) boundary and over the network. |
| JNI | Java Native Interface — the mechanism the Android client uses to call into the C++ core; the counterpart to Swift's native C++ interop on iOS. |
| Wōkòu (倭寇) / Wakō | Mixed-ethnicity pirate raider bands (Japanese rōnin, Chinese/Korean smugglers) that raided the East Asian coast in the 1540s–1560s Jiajing era; the antagonists Mobile Fortress is set against. |
| Main HQ / Citadel | The player's primary fortress; its HP reaching zero is the game-over condition. |
| Resource Outpost | An inland base structure that generates the currency used to buy/deploy land units; defendable separately from the HQ. |
| Trading Outpost | A coastal/harbor base structure that generates the currency used to buy/deploy naval units; defendable separately from the HQ. |
| Fo-lang-ji (Folangji) | A Portuguese-derived breech-loading swivel cannon adopted by the Ming military in this era; one of Mobile Fortress' ranged land units. |
| Ming Garrison Spearmen | Foot-soldier spearmen, the East Asian primary civilization's basic melee/blocker unit type. |
| Portuguese Arquebusiers | Matchlock-gunner ranged unit fielded by the supporting Western civilization (Portuguese by default). |

> **TODO:** Expand with further Mobile Fortress domain terms (gacha/hero-commander system, faction/territory meta-game) as those systems are implemented.
