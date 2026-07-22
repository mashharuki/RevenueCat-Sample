import XCTest
@testable import BreakoutGame

final class GameViewModelTests: XCTestCase {
    func testAddBrickScoreIncrementsByBrickScoreValue() {
        let viewModel = GameViewModel()
        viewModel.addBrickScore()
        XCTAssertEqual(viewModel.score, GameViewModel.brickScoreValue)
    }

    func testLoseLifeDecrementsLivesAndReturnsTrueWhileLivesRemain() {
        let viewModel = GameViewModel()
        viewModel.resetForNewGame()
        let hasLivesRemaining = viewModel.loseLife()
        XCTAssertEqual(viewModel.lives, GameViewModel.startingLives - 1)
        XCTAssertTrue(hasLivesRemaining)
        XCTAssertEqual(viewModel.state, .playing)
    }

    func testLoseLifeSetsGameOverWhenLivesReachZero() {
        let viewModel = GameViewModel()
        for _ in 0..<GameViewModel.startingLives {
            _ = viewModel.loseLife()
        }
        XCTAssertEqual(viewModel.lives, 0)
        XCTAssertEqual(viewModel.state, .gameOver)
    }

    func testMarkAsWonSetsWinState() {
        let viewModel = GameViewModel()
        viewModel.markAsWon()
        XCTAssertEqual(viewModel.state, .win)
    }
}
