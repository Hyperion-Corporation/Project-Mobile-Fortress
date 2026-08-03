# Shared Core Roadmap (future option, not started)

Today `core/` is assets + documentation only — see [`core/README.md`](../../core/README.md). This roadmap tracks the option of making it a real compiled shared module. **Read `core/README.md` in full before starting any of this** — it changes both clients' architecture substantially and is a multi-week undertaking, not a template default.

## Option A — Kotlin Multiplatform (KMP)

Move `GameManager`/`GameEngine`-equivalent logic into a KMP module compiled to a JVM target (consumed directly by `android/app/`) and an iOS framework (consumed from Swift via `import Shared`). Pros: one Kotlin codebase for game logic; Android integration is nearly free. Cons: iOS interop still requires an Obj-C/Swift-facing API layer, and the Kotlin/Native toolchain adds real build complexity and iteration-speed cost on the iOS side.

## Option B — Rust or C++ core with per-platform bindings

Shared core in Rust (via UniFFI or cbindgen) or C++, linked into Android via JNI and into iOS via a bridging header / Swift Package. Pros: genuinely platform-neutral, reusable beyond just these two clients. Cons: highest setup cost of the three options; neither client team gets to write the core logic in their primary language.

## Option C — stay documentation-only (current state)

Keep `core/src/` as schema/spec documents (`level-schema.json`, `game-state-machine.md`) that both native implementations follow by convention, enforced only by code review and the `Tests/` suites on each side independently asserting the documented behavior. Pros: zero build complexity, zero new toolchain. Cons: the two implementations *can* drift, and nothing catches it automatically except tests/review — already true today (see the Android/iOS state-machine asymmetry noted in `core/src/game-state-machine.md`).

## Recommendation

Stay on Option C until the game's actual gameplay logic (not just this template's minimal demo) is complex enough that keeping two implementations in sync by hand is regularly causing bugs — then revisit A vs. B based on which platform's team is doing more of the core-logic work at that point.
