import Foundation

/// Decodes level/wave-layout JSON. The canonical source file lives at
/// `game/assets/levels/` (see `game/README.md`) and is referenced directly
/// into this Xcode target — not copied — so there is exactly one copy of
/// each level on disk. Implements the shape documented in
/// `game/src/level-schema.json`. Kept as a thin, framework-free loader (no
/// SpriteKit imports) so it's trivially unit-testable — see
/// `Tests/LevelLoaderTests.swift`.
struct LevelWave: Codable, Equatable {
    let delaySeconds: Double
    let enemyCount: Int
    let spawnPattern: String
}

struct LevelDefinition: Codable, Equatable {
    let id: String
    let displayName: String
    let enemySpawnIntervalSeconds: Double
    let waves: [LevelWave]
}

enum LevelLoaderError: Error {
    case resourceNotFound(String)
}

enum LevelLoader {
    /// Loads and decodes `<name>.json` from the app bundle's `Resources/Levels/` group.
    static func load(named name: String, bundle: Bundle = .main) throws -> LevelDefinition {
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw LevelLoaderError.resourceNotFound(name)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(LevelDefinition.self, from: data)
    }
}
