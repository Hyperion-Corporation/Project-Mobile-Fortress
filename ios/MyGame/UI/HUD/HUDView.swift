import SwiftUI

/// Heads-up display overlaid on `GameContainerView`: current score and a
/// pause button. Reads `GameManager.score` directly rather than through
/// `NotificationCenter`, since — unlike `GameScene` — this is a normal
/// SwiftUI view that can use `@EnvironmentObject`.
struct HUDView: View {
    @EnvironmentObject private var gameManager: GameManager

    var body: some View {
        HStack {
            Text("\(gameManager.score)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.primaryText)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(.black.opacity(0.4), in: Capsule())

            Spacer()

            Button {
                if gameManager.state == .playing {
                    gameManager.pause()
                } else {
                    gameManager.resume()
                }
            } label: {
                Image(systemName: gameManager.state == .playing ? "pause.fill" : "play.fill")
                    .foregroundStyle(Theme.primaryText)
                    .padding(10)
                    .background(.black.opacity(0.4), in: Circle())
            }
        }
        .padding()
    }
}

#Preview {
    HUDView().environmentObject(GameManager.shared)
}
