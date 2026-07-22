import Foundation

enum GameState: Equatable {
    case menu
    case playing
    case gameOver
    case win
}

final class GameViewModel: ObservableObject {
    static let startingLives = 3
    static let brickScoreValue = 10

    @Published var score: Int = 0
    @Published var lives: Int = GameViewModel.startingLives
    @Published var state: GameState = .menu
    @Published var activePowerUps: Set<PowerUpType> = []

    func resetForNewGame() {
        score = 0
        lives = GameViewModel.startingLives
        state = .playing
        activePowerUps.removeAll()
    }

    func activatePowerUp(_ type: PowerUpType) {
        activePowerUps.insert(type)
    }

    func deactivatePowerUp(_ type: PowerUpType) {
        activePowerUps.remove(type)
    }

    func resetPowerUps() {
        activePowerUps.removeAll()
    }

    func addBrickScore() {
        score += GameViewModel.brickScoreValue
    }

    func loseLife() -> Bool {
        lives -= 1
        let hasLivesRemaining = lives > 0
        if !hasLivesRemaining {
            state = .gameOver
        }
        return hasLivesRemaining
    }

    func markAsWon() {
        state = .win
    }
}
