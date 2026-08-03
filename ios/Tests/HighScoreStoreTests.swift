import XCTest
@testable import MyGame

final class HighScoreStoreTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var store: HighScoreStore!

    override func setUp() {
        super.setUp()
        suiteName = "HighScoreStoreTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        store = HighScoreStore(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testSubmitKeepsHighestScoreFirst() {
        store.submit(score: 100)
        store.submit(score: 250)
        store.submit(score: 50)

        XCTAssertEqual(store.topScore, 250)
        XCTAssertEqual(store.entries.map(\.score), [250, 100, 50])
    }

    func testSubmitCapsAtTenEntries() {
        for score in 1...15 {
            store.submit(score: score)
        }
        XCTAssertEqual(store.entries.count, 10)
        XCTAssertEqual(store.topScore, 15)
    }
}
