import Foundation

enum PowerUpType: CaseIterable, Hashable {
    case multiBall
    case paddleGrow
    case laser

    var displayName: String {
        switch self {
        case .multiBall: "Multi-Ball"
        case .paddleGrow: "Paddle+"
        case .laser: "Laser"
        }
    }
}
