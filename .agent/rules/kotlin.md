# Kotlin Rules

- Target Kotlin 2.0.20 / JVM 17, built via Gradle Kotlin DSL (`android/app/build.gradle.kts`).
- Format/lint with `ktlint` (`./android/gradlew ktlintCheck`, `./android/gradlew ktlintFormat`) and Android Lint (`./android/gradlew lint`).
- Prefer immutable data classes and `val` over `var`; avoid platform types leaking from Java interop (`androidx`/framework APIs) without an explicit null-check.
- Use coroutines (`kotlinx.coroutines`) for async work (asset loading, network calls to the optional backend) instead of raw threads or `AsyncTask` — the one deliberate exception is the `GameLoop` render thread itself, which uses a plain `Thread` for predictable, low-overhead frame timing (see [`game_loop_performance.md`](game_loop_performance.md)).
- Keep Gradle build logic in the version catalog (`gradle/libs.versions.toml`), not hardcoded versions scattered across `build.gradle.kts` files.
- Sealed classes/interfaces for finite game states (`GameState.Running`, `GameState.Paused`, `GameState.GameOver`) instead of boolean flags or magic ints.
- No `!!` outside test code — prefer safe calls, `requireNotNull` with a message, or restructuring to avoid the nullable in the first place.
