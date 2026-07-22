import XCTest
import CoreGraphics
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

    func testRotatedPreservesVectorMagnitude() {
        let vector = CGVector(dx: 0, dy: 300)
        let rotated = GameMath.rotated(vector, byDegrees: 20)
        let originalMagnitude = sqrt(vector.dx * vector.dx + vector.dy * vector.dy)
        let rotatedMagnitude = sqrt(rotated.dx * rotated.dx + rotated.dy * rotated.dy)
        XCTAssertEqual(rotatedMagnitude, originalMagnitude, accuracy: 0.001)
    }

    func testRotatedByNinetyDegreesSwapsAxes() {
        let vector = CGVector(dx: 0, dy: 1)
        let rotated = GameMath.rotated(vector, byDegrees: 90)
        XCTAssertEqual(rotated.dx, -1, accuracy: 0.001)
        XCTAssertEqual(rotated.dy, 0, accuracy: 0.001)
    }
}
