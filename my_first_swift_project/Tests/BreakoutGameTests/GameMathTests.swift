import XCTest
@testable import BreakoutGame

final class GameMathTests: XCTestCase {
    func testClampReturnsValueWhenWithinRange() {
        XCTAssertEqual(GameMath.clamp(5, min: 0, max: 10), 5)
    }

    func testClampReturnsMinWhenBelowRange() {
        XCTAssertEqual(GameMath.clamp(-5, min: 0, max: 10), 0)
    }

    func testClampReturnsMaxWhenAboveRange() {
        XCTAssertEqual(GameMath.clamp(15, min: 0, max: 10), 10)
    }
}
