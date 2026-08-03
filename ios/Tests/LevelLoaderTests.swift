import XCTest
@testable import MyGame

final class LevelLoaderTests: XCTestCase {
    func testLoadsBundledLevelOne() throws {
        let level = try LevelLoader.load(named: "level_01", bundle: .main)
        XCTAssertEqual(level.id, "level_01")
        XCTAssertFalse(level.waves.isEmpty)
    }

    func testThrowsForMissingLevel() {
        XCTAssertThrowsError(try LevelLoader.load(named: "does_not_exist", bundle: .main)) { error in
            guard case LevelLoaderError.resourceNotFound = error else {
                return XCTFail("expected .resourceNotFound, got \(error)")
            }
        }
    }
}
