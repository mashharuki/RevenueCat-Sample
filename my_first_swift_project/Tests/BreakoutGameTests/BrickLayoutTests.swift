import XCTest
@testable import BreakoutGame

final class BrickLayoutTests: XCTestCase {
    func testStandardLayoutGeneratesExpectedBrickCount() {
        let placements = BrickLayout.standardLayout(in: CGSize(width: 400, height: 700))
        XCTAssertEqual(placements.count, BrickLayout.columns * BrickLayout.rows)
    }

    func testStandardLayoutKeepsBricksWithinSceneBounds() {
        let sceneSize = CGSize(width: 400, height: 700)
        let placements = BrickLayout.standardLayout(in: sceneSize)
        let halfWidth = BrickLayout.brickSize.width / 2

        for placement in placements {
            XCTAssertGreaterThanOrEqual(placement.position.x, halfWidth)
            XCTAssertLessThanOrEqual(placement.position.x, sceneSize.width - halfWidth)
        }
    }

    func testStandardLayoutAssignsRowIndicesWithinRange() {
        let placements = BrickLayout.standardLayout(in: CGSize(width: 400, height: 700))
        for placement in placements {
            XCTAssertGreaterThanOrEqual(placement.row, 0)
            XCTAssertLessThan(placement.row, BrickLayout.rows)
        }
    }
}
