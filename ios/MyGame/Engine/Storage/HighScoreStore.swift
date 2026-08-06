import Foundation

/// Local high-score persistence via `UserDefaults` + `Codable` — the iOS
/// counterpart to the Android `GameState.saveTo`/`loadFrom` pair in
/// `engine/GameState.kt`, but scoped to just the high-score table rather than
/// full mid-run state (see `SettingsStore` for the settings equivalent, and
/// `GameManager` for in-run state, which intentionally is NOT persisted here).
struct HighScoreEntry: Codable, Identifiable {
    let id: UUID
    let score: Int
    let date: Date
}

final class HighScoreStore {
    static let shared = HighScoreStore()

    private let defaultsKey = "com.acfharbinger.mobilefortress.highscores"
    private let maxEntries = 10
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private(set) lazy var entries: [HighScoreEntry] = load()

    /// Records a new score, keeping only the top `maxEntries`, highest first.
    @discardableResult
    func submit(score: Int) -> [HighScoreEntry] {
        var current = load()
        current.append(HighScoreEntry(id: UUID(), score: score, date: Date()))
        current.sort { $0.score > $1.score }
        current = Array(current.prefix(maxEntries))
        save(current)
        entries = current
        return current
    }

    var topScore: Int {
        entries.first?.score ?? 0
    }

    private func load() -> [HighScoreEntry] {
        guard let data = defaults.data(forKey: defaultsKey),
              let decoded = try? JSONDecoder().decode([HighScoreEntry].self, from: data) else {
            return []
        }
        return decoded
    }

    private func save(_ entries: [HighScoreEntry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        defaults.set(data, forKey: defaultsKey)
    }
}
