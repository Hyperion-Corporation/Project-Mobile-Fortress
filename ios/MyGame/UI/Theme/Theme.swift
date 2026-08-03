import SwiftUI

/// Design tokens shared across every SwiftUI screen — the iOS counterpart to
/// Android Compose's `ui/theme/` (`Color.kt`, `Theme.kt`). Centralizing these
/// keeps `MainMenuView`/`GameOverView`/`HUDView`/`ShopView` visually
/// consistent without duplicating literal colors.
enum Theme {
    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.7)
    static let accent = Color.yellow

    static let backgroundGradient = LinearGradient(
        colors: [Color(red: 0.05, green: 0.05, blue: 0.15), Color(red: 0.12, green: 0.05, blue: 0.25)],
        startPoint: .top,
        endPoint: .bottom
    )
}

/// Shared pill-shaped button style used by every primary CTA across the menu
/// flow (Play, Shop, Play Again, Main Menu).
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.black)
            .padding(.horizontal, 32)
            .padding(.vertical, 14)
            .background(Theme.accent.opacity(configuration.isPressed ? 0.7 : 1))
            .clipShape(Capsule())
    }
}
