import SwiftUI

/// Root menu screen — the SwiftUI/iOS counterpart to Android's Compose
/// `ui/MainMenuScreen.kt`. Delegates state changes to `GameManager` rather
/// than owning navigation itself.
struct MainMenuView: View {
    @EnvironmentObject private var gameManager: GameManager
    @StateObject private var viewModel = MainMenuViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()

                VStack(spacing: 24) {
                    Text("MyGame")
                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.primaryText)

                    Text("High Score: \(viewModel.highScore)")
                        .font(.headline)
                        .foregroundStyle(Theme.secondaryText)

                    VStack(spacing: 16) {
                        Button("Play") { gameManager.startNewGame() }
                            .buttonStyle(PrimaryButtonStyle())

                        NavigationLink("Shop") { ShopView() }
                            .buttonStyle(PrimaryButtonStyle())
                    }
                }
                .padding()
            }
        }
        .onAppear { viewModel.refresh() }
    }
}

/// Loads presentation-ready state from `HighScoreStore` so the view itself
/// stays a pure function of `@Published` state (no direct store access in
/// the view body).
@MainActor
final class MainMenuViewModel: ObservableObject {
    @Published private(set) var highScore: Int = 0

    func refresh() {
        highScore = HighScoreStore.shared.topScore
    }
}

#Preview {
    MainMenuView().environmentObject(GameManager.shared)
}
