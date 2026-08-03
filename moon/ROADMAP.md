# Mobile-Game-Template Roadmap

[![Kotlin](https://img.shields.io/badge/Kotlin-2.0-7F52FF?logo=kotlin&logoColor=white)](https://kotlinlang.org/)
[![Android](https://img.shields.io/badge/Android-API_24%2B-3DDC84?logo=android&logoColor=white)](https://developer.android.com/)
[![Swift](https://img.shields.io/badge/Swift-5.0-F05138?logo=swift&logoColor=white)](https://swift.org/)
[![iOS](https://img.shields.io/badge/iOS-16%2B-000000?logo=apple&logoColor=white)](https://developer.apple.com/ios/)

> **Version**: 2.0
> **Date**: 2026-08-03
> **Status**: Template

## Overview

This document tracks planned scaffolding work for `Mobile-Game-Template` itself — a two-client (Android/Kotlin under `android/`, iOS/Swift under `ios/`) mobile game monorepo sharing raw assets and a documented (not compiled) state-machine/schema spec under `core/`. Once this template seeds a real game, replace this file's contents with that project's actual roadmap — per-topic detail then lives in `moon/roadmaps/<topic>.md`. Completed items move to [`moon/CHANGELOG.md`](CHANGELOG.md).

Status markers: ✅ Done · 🚧 In Progress · 📋 Pending

---

## Track: Template Scaffolding

| # | Item | Effort | Status |
| --- | --- | --- | --- |
| T1 | Root scaffolding: LICENSE, README, `.pre-commit-config.yaml`, `.gitignore` | S | ✅ Done |
| T2 | `.github/` CI/CD: workflows, issue/PR templates, dependabot | M | ✅ Done |
| T3 | `docs/` documentation portal: MkDocs, ADRs | M | ✅ Done |
| T4 | `moon/` roadmap and changelog | S | ✅ Done |
| T5 | `infra/{docker,k8s,helm,terraform,ansible}/` optional backend scaffolding | M | ✅ Done |
| T6 | `.agent/` LLM coding-agent scaffolding | M | ✅ Done |
| T7 | Root `justfile` wrapping Gradle + Xcode tasks | S | ✅ Done |
| T8 | `.devcontainer/` Dev Container definition (Android SDK, JDK 17, emulator) — iOS/Xcode builds require a native macOS host, documented as a known limitation | S | ✅ Done |
| T9 | Standard Android `app/` module skeleton (SurfaceView game loop, one demo entity) — now under `android/` | M | ✅ Done |
| T10 | Unit test + instrumented test skeleton (Android) | S | ✅ Done |
| T11 | `release.yml` signed AAB/APK pipeline + optional fastlane Play Store upload (Android) | M | ✅ Done |
| T12 | iOS `MyGame` app skeleton under `ios/` (SpriteKit + SwiftUI chrome, feature-parity with Android where the two platforms' scope overlaps) | M | ✅ Done |
| T13 | iOS `XCTest` unit test skeleton + shared Xcode scheme for CI | S | ✅ Done |
| T14 | `core/` shared-assets module + documented (non-compiled) state-machine/level-schema spec | S | ✅ Done |

## Track: Post-Template Adoption

> **TODO:** Once a real game is generated from this template, replace this section with that game's actual feature roadmap.

See per-topic detail in [`moon/roadmaps/`](roadmaps/): [`gameplay.md`](roadmaps/gameplay.md), [`ui_ux.md`](roadmaps/ui_ux.md), [`performance.md`](roadmaps/performance.md), [`monetization.md`](roadmaps/monetization.md), [`backend.md`](roadmaps/backend.md), [`qa_testing.md`](roadmaps/qa_testing.md), [`ios.md`](roadmaps/ios.md), [`shared_core.md`](roadmaps/shared_core.md).
