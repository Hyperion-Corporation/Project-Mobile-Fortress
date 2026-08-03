import SwiftUI

/// SwiftUI entry point. Mirrors `MainActivity` on the Android side: owns the
/// top-level `GameManager` and routes to Menu/GameLevel/GameOver based on its
/// published state. See `docs/adr/0003-ios-rendering-approach.md`.
@main
struct MyGameApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var gameManager = GameManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(gameManager)
        }
    }
}

/// Switches between the three top-level screens based on `GameManager.state`.
private struct RootView: View {
    @EnvironmentObject private var gameManager: GameManager

    var body: some View {
        switch gameManager.state {
        case .menu:
            MainMenuView()
        case .playing, .paused:
            GameContainerView()
        case .gameOver(let score):
            GameOverView(score: score)
        }
    }
}
