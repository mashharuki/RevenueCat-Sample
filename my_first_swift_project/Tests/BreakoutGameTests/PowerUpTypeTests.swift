@testable import BreakoutGame
import XCTest

final class PowerUpTypeTests: XCTestCase {
    func testAllCasesHaveANonEmptyDisplayName() {
        for type in PowerUpType.allCases {
            XCTAssertFalse(type.displayName.isEmpty)
        }
    }

    func testAllCasesAreDistinct() {
        XCTAssertEqual(Set(PowerUpType.allCases).count, PowerUpType.allCases.count)
    }
}
