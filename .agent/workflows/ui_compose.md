# Workflow: Compose Screen (Menu/HUD/Settings)

1. Sketch the composable tree and identify what state lives where (local `remember` vs. `ViewModel`-hosted).
2. Build the presentational composable first with mock/preview data (`@Preview`), verify it renders correctly in Android Studio's preview pane.
3. Wire it to real state via a `ViewModel`; handle loading, empty, and error states explicitly (especially for backend-dependent screens like leaderboards).
4. Add content descriptions/semantics for accessibility on every interactive control.
5. Add a Compose UI test (`createAndroidComposeRule`) for the golden path, then manually exercise it via `just install` on a running device/emulator.
