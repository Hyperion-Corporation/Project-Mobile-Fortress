# Glossary

| Term | Meaning |
| --- | --- |
| ADR | Architecture Decision Record — a short document capturing a significant, hard-to-reverse technical decision and its rationale. |
| AGP | Android Gradle Plugin — the Gradle plugin (`com.android.application`) that builds Android app modules. |
| AAB | Android App Bundle — the publishing format (`.aab`) uploaded to the Play Store, superseding raw APK uploads. |
| Fixed timestep | A game loop pattern where the simulation (`update()`) always advances by the same fixed time increment regardless of actual frame rate, keeping physics/logic deterministic. |
| `GameLoop` | This template's dedicated thread running the fixed-timestep update/render cycle for the `SurfaceView` game surface. |
| Interpolation (rendering) | Blending between the previous and current simulation state when rendering happens more often than fixed updates, for smoother visuals. |
| `SurfaceView` | An Android View subclass that provides a dedicated drawing surface on a separate thread from the UI thread — the rendering approach this template uses for the game surface. |
| R8 | Android's code shrinker/obfuscator/optimizer, applied to `release` builds. |
| Play Store track | A release channel in Google Play Console (internal, closed, open, production) that a signed AAB is promoted through. |
| SpriteKit | Apple's first-party 2D game framework — the rendering approach this template uses for the iOS game surface (`ios/MyGame/Scenes/GameLevel/GameScene.swift`). |
| `SKScene` | SpriteKit's scene class; its `update(_:)` method is called once per display refresh — the iOS equivalent of Android's `GameLoop` tick, without a hand-rolled thread. |
| `xcodebuild` | Apple's command-line build tool for Xcode projects — used by `just ios-build`/`ios-test`/`ios-archive` and the `ios-test` CI job. |
| `.xcarchive` | The archived-build format `xcodebuild archive` produces, the input to exporting a signed `.ipa` for TestFlight/App Store distribution. |
| `core/` | This template's shared-assets-and-spec module — canonical raw game data plus a documented (not compiled) state-machine/level-schema spec both clients implement independently. See `core/README.md`. |

> **TODO:** Add project-specific domain terms once this template is used to seed a real game.
