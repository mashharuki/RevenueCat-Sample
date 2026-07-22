import CoreGraphics

enum GameMath {
    static func clamp(_ value: CGFloat, min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
        Swift.min(Swift.max(value, minValue), maxValue)
    }

    static func rotated(_ vector: CGVector, byDegrees degrees: CGFloat) -> CGVector {
        let radians = degrees * .pi / 180
        let cosValue = cos(radians)
        let sinValue = sin(radians)
        return CGVector(
            dx: vector.dx * cosValue - vector.dy * sinValue,
            dy: vector.dx * sinValue + vector.dy * cosValue
        )
    }
}
