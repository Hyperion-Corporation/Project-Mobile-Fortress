# core/

Platform-agnostic shared game data and (aspirationally) shared logic for the
Android (`android/`) and iOS (`ios/`) clients.

## What's real today

- **`assets/`** — the canonical, single-sourced raw game assets referenced by
  both clients: level/wave layout JSON, and (as they're added) shared audio
  and texture source files. `ios/MyGame.xcodeproj` references
  `assets/levels/level_01.json` directly from here (via a relative file
  reference into the Xcode project, no copy/duplication) — see
  `ios/MyGame/Resources/Levels/LevelLoader.swift`. The Android client does not
  yet consume structured level JSON (its `GameEngine` only tracks a single
  `Ball` entity — see `android/app/.../engine/GameEngine.kt`); when Android
  gameplay grows past that, it should read from `assets/levels/` too rather
  than duplicating level data under `android/app/src/main/res/`.
- **`src/level-schema.json`** — a plain JSON Schema describing the shape of
  files under `assets/levels/`. Both platforms' native level loaders
  (`ios/.../LevelLoader.swift` today; a future Kotlin equivalent) implement
  against this schema by convention. It is documentation, not compiled code.

## What's aspirational

`src/` is **not** a compiled shared module — there is no build step that
turns anything in `core/src/` into code either client links against. Kotlin
and Swift have no natural shared-compilation boundary without real
engineering investment (Kotlin Multiplatform targeting an iOS framework, or a
Rust/C++ core with Kotlin/JNI + Swift/C bindings, are the two realistic
options). Neither is set up here — doing so properly is a multi-week project
in its own right, not something to bolt on as a template default. Until then,
"shared logic" (the state-machine shape in particular — see
`src/game-state-machine.md`) is kept in sync **by convention**: the Kotlin
`GameManager`-equivalent and Swift `GameManager` (`ios/MyGame/Core/GameManager.swift`)
independently implement the same states/transitions, and a change to one
should be mirrored in the other and in `src/game-state-machine.md`.

A real shared core (KMP or Rust/C++) is tracked as a future option in
[`moon/roadmaps/shared_core.md`](../moon/roadmaps/shared_core.md) — read that
before starting any such migration, since it changes both clients'
architecture substantially.
