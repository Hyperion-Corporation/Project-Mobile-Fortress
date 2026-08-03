import SwiftUI

/// Shown after `GameManager.endGame()` fires. Score submission to
/// `HighScoreStore` already happened inside `GameManager` (see
/// `endGame()`), so this view is purely presentational — mirrors keeping
/// persistence out of Android's Compose `GameOverScreen` equivalent.
struct GameOverView: View {
    let score: Int
    @EnvironmentObject private var gameManager: GameManager

    private var isNewHighScore: Bool {
        score > 0 && score >= HighScoreStore.shared.topScore
    }

    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Game Over")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.primaryText)

                Text("Score: \(score)")
                    .font(.title2)
                    .foregroundStyle(Theme.secondaryText)

                if isNewHighScore {
                    Text("New High Score!")
                        .font(.headline)
                        .foregroundStyle(Theme.accent)
                }

                VStack(spacing: 16) {
                    Button("Play Again") { gameManager.startNewGame() }
                        .buttonStyle(PrimaryButtonStyle())

                    Button("Main Menu") { gameManager.returnToMenu() }
                        .buttonStyle(PrimaryButtonStyle())
                }
                .padding(.top, 12)
            }
            .padding()
        }
    }
}

#Preview {
    GameOverView(score: 240).environmentObject(GameManager.shared)
}
