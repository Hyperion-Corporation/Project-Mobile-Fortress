import Foundation

/// User-facing settings, persisted via `UserDefaults` + `Codable`, mirroring
/// the shape (if not the storage mechanism) of a Kotlin `DataStore`-backed
/// settings repository. Kept separate from `HighScoreStore` since the two
/// have unrelated read/write cadences and failure semantics.
struct GameSettings: Codable, Equatable {
    var isMusicEnabled: Bool = true
    var isEffectsEnabled: Bool = true
    var isHapticsEnabled: Bool = true

    static let `default` = GameSettings()
}

final class SettingsStore {
    static let shared = SettingsStore()

    private let defaultsKey = "com.acfharbinger.mobilefortress.settings"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> GameSettings {
        guard let data = defaults.data(forKey: defaultsKey),
              let decoded = try? JSONDecoder().decode(GameSettings.self, from: data) else {
            return .default
        }
        return decoded
    }

    func save(_ settings: GameSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: defaultsKey)
        AudioManager.shared.isMusicEnabled = settings.isMusicEnabled
        AudioManager.shared.isEffectsEnabled = settings.isEffectsEnabled
    }
}
