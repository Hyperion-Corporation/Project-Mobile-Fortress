import SwiftUI

/// Character/skin selection screen — deliberately a simple static list stub
/// (no IAP wiring) so it's a clear extension point rather than a half-built
/// store integration. See `moon/roadmaps/ios.md` for the planned scope.
struct ShopSkin: Identifiable {
    let id = UUID()
    let name: String
    let symbolName: String
    let isUnlocked: Bool
}

struct ShopView: View {
    private let skins: [ShopSkin] = [
        ShopSkin(name: "Default", symbolName: "circle.fill", isUnlocked: true),
        ShopSkin(name: "Nova", symbolName: "star.fill", isUnlocked: true),
        ShopSkin(name: "Eclipse", symbolName: "moon.fill", isUnlocked: false),
        ShopSkin(name: "Prism", symbolName: "diamond.fill", isUnlocked: false),
    ]

    var body: some View {
        List(skins) { skin in
            HStack {
                Image(systemName: skin.symbolName)
                    .foregroundStyle(skin.isUnlocked ? Theme.accent : .gray)
                    .frame(width: 28)

                Text(skin.name)

                Spacer()

                Text(skin.isUnlocked ? "Owned" : "Locked")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Shop")
    }
}

#Preview {
    NavigationStack { ShopView() }
}
