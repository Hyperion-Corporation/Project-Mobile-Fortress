# Pull Request

## Summary

<!-- What does this PR change and why? Link the roadmap item (moon/ROADMAP.md or a module roadmap in moon/roadmaps/). -->

## Affected Area(s)

- [ ] Android game loop / rendering (`android/app/.../GameLoop`, `GameView`, `engine/`)
- [ ] Android lifecycle (Activity, SurfaceView, save/restore)
- [ ] Android UI (Compose menus/HUD)
- [ ] iOS game loop / rendering (`ios/MyGame/Scenes/GameLevel/GameScene.swift`, `Engine/`)
- [ ] iOS lifecycle (`AppDelegate`, SpriteKit/SwiftUI scene teardown, save/restore)
- [ ] iOS UI (SwiftUI menus/HUD)
- [ ] Shared assets / spec (`core/`)
- [ ] Optional backend (`infra/`)
- [ ] Tooling / docs / CI

## Type of Change

- [ ] 🐛 Bug fix
- [ ] ✨ New feature
- [ ] ♻️ Refactor
- [ ] ⚡ Performance
- [ ] 📚 Documentation
- [ ] 🔧 Tooling / CI

## Verification

- [ ] `just lint-check` and `just unit-test` pass (Android).
- [ ] `just test-instrumented` run for Android lifecycle/UI-affecting changes.
- [ ] `just ios-check` and `just ios-test` pass (iOS) — requires a macOS host, see `.devcontainer/README.md`.
- [ ] No allocations introduced in a per-frame update/render hot path (Android `GameLoop`, iOS `GameScene.update(_:)`) — see `.agent/rules/game_loop_performance.md`.
- [ ] If this changes shared behavior (state machine, level schema), `core/src/game-state-machine.md` or `core/src/level-schema.json` updated and both platforms kept in sync.
- [ ] Docs / roadmap / `moon/CHANGELOG.md` updated where the public surface changed.
