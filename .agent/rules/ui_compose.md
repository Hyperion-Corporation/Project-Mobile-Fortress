# UI (Jetpack Compose) Rules

Applies to `android/app/src/main/java/com/example/gametemplate/ui/` — menus, HUD overlays, settings, pause screens. Does **not** apply to the `SurfaceView` game surface itself (see [`game_loop_performance.md`](game_loop_performance.md)).

- Keep Compose screens presentation-only; game/business logic belongs in `engine/` or a `ViewModel`, called into from Composables — never inline gameplay logic in a `@Composable` body.
- Every interactive control (buttons, sliders for settings) needs a content description for accessibility (`Modifier.semantics` / `contentDescription`) — not just a touch target.
- Long-running work (asset preloading, backend calls for leaderboards) must run in a `ViewModel` scope (`viewModelScope.launch`), never blocking Compose's recomposition.
- HUD overlays drawn over the `SurfaceView` (score, health) should prefer a Compose overlay in an `AndroidView`-hosting layout over drawing text directly on the game `Canvas`, unless the HUD needs to be frame-locked with gameplay (e.g. a combo counter tied to the physics tick) — document the choice inline if you deviate.
- Match Material 3 theming already set up in `android/app/src/main/res/values/themes.xml`; don't introduce a second design system for one screen.
- Add a Compose UI test (`createAndroidComposeRule`) for each new screen's golden path.

## Anti-patterns

- Reading/writing `GameState` directly from a Composable without going through a `ViewModel` — couples recomposition timing to game state mutation and makes the screen untestable in isolation.
- Blocking the main thread in a `LaunchedEffect` with a synchronous network call instead of a suspend function.
