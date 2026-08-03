import SpriteKit
import SwiftUI

/// SwiftUI host for `GameScene`, with the `HUDView` chrome overlaid on top —
/// the iOS counterpart to how Android's Compose `MainMenuScreen`-style chrome
/// sits alongside the `GameView` `SurfaceView` rather than inside it.
struct GameContainerView: View {
    @EnvironmentObject private var gameManager: GameManager

    private let scene: SKScene = {
        let scene = GameScene()
        scene.scaleMode = .resizeFill
        return scene
    }()

    var body: some View {
        ZStack(alignment: .top) {
            SpriteView(scene: scene)
                .ignoresSafeArea()
                .onAppear { gameManager.startNewGame() }

            HUDView()
        }
    }
}
