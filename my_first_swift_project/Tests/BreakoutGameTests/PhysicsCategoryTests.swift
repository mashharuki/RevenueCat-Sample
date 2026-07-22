import XCTest
@testable import BreakoutGame

final class PhysicsCategoryTests: XCTestCase {
    func testAllCategoriesAreDistinctPowersOfTwo() {
        let categories = [
            PhysicsCategory.ball,
            PhysicsCategory.paddle,
            PhysicsCategory.brick,
            PhysicsCategory.wall,
            PhysicsCategory.powerUp,
            PhysicsCategory.laserBolt
        ]
        XCTAssertEqual(Set(categories).count, categories.count, "physics categories must not overlap")

        for category in categories {
            XCTAssertEqual(category & (category - 1), 0, "\(category) is not a power of two")
        }
    }
}
