import Foundation

enum PowerUpType: CaseIterable, Hashable {
    case multiBall
    case paddleGrow
    case laser

    var displayName: String {
        switch self {
        case .multiBall: return "Multi-Ball"
        case .paddleGrow: return "Paddle+"
        case .laser: return "Laser"
        }
    }
}
