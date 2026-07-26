@testable import BreakoutGame
import XCTest

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
    for _ in 0 ..< GameViewModel.startingLives {
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

  func testHandleLevelClearedRoutesToPaywallAtFreeLimitWithoutPremium() {
    let viewModel = GameViewModel()
    let outcome = viewModel.handleLevelCleared()
    XCTAssertEqual(outcome, .paywall)
    XCTAssertEqual(viewModel.state, .paywall)
    XCTAssertEqual(viewModel.currentLevel, 1)
  }

  func testHandleLevelClearedAdvancesWhenPremiumUnlocked() {
    let viewModel = GameViewModel()
    viewModel.resetForNewGame()
    viewModel.isPremiumUnlocked = true
    let outcome = viewModel.handleLevelCleared()
    XCTAssertEqual(outcome, .nextLevel(2))
    XCTAssertEqual(viewModel.currentLevel, 2)
    XCTAssertEqual(viewModel.state, .playing, "advancing a level must not touch state — GameScene stays in .playing")
  }

  func testHandleLevelClearedFinishesAtMaxLevel() {
    let viewModel = GameViewModel()
    viewModel.isPremiumUnlocked = true
    viewModel.currentLevel = GameViewModel.maxLevel
    let outcome = viewModel.handleLevelCleared()
    XCTAssertEqual(outcome, .finalWin)
    XCTAssertEqual(viewModel.state, .win)
  }

  func testShowPaywallSetsBannerAndClosePaywallReturnsToRequestedScreen() {
    let viewModel = GameViewModel()
    viewModel.showPaywall(banner: "test banner", returnTo: .gameOver)
    XCTAssertEqual(viewModel.state, .paywall)
    XCTAssertEqual(viewModel.paywallBanner, "test banner")
    viewModel.closePaywall()
    XCTAssertEqual(viewModel.state, .gameOver)
    XCTAssertNil(viewModel.paywallBanner)
  }

  func testShowPaywallDefaultsReturnScreenToMenu() {
    let viewModel = GameViewModel()
    viewModel.showPaywall()
    viewModel.closePaywall()
    XCTAssertEqual(viewModel.state, .menu)
  }

  func testShowWeeklyChallengeRoutesToPaywallWhenNotSubscribed() {
    let viewModel = GameViewModel()
    viewModel.showWeeklyChallenge()
    XCTAssertEqual(viewModel.state, .paywall)
  }

  func testShowWeeklyChallengeShowsScreenWhenSubscribed() {
    let viewModel = GameViewModel()
    viewModel.hasWeeklyChallenge = true
    viewModel.showWeeklyChallenge()
    XCTAssertEqual(viewModel.state, .weeklyChallenge)
  }

  func testContinueGameDoesNothingWithoutTokens() {
    let viewModel = GameViewModel()
    for _ in 0 ..< GameViewModel.startingLives {
      _ = viewModel.loseLife()
    }
    viewModel.continueGame()
    XCTAssertEqual(viewModel.state, .gameOver)
    XCTAssertEqual(viewModel.lives, 0)
  }

  func testContinueGameSpendsTokenRefillsLivesAndResumesPlaying() {
    let viewModel = GameViewModel()
    for _ in 0 ..< GameViewModel.startingLives {
      _ = viewModel.loseLife()
    }
    viewModel.grantContinueToken()
    XCTAssertEqual(viewModel.continueTokens, 1)

    viewModel.continueGame()

    XCTAssertEqual(viewModel.continueTokens, 0)
    XCTAssertEqual(viewModel.lives, GameViewModel.startingLives)
    XCTAssertEqual(viewModel.state, .playing)
  }
}
