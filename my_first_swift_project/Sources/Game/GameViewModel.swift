import Foundation
import RevenueCat

enum GameState: Equatable {
  case menu
  case playing
  case gameOver
  case win
  case paywall
  case weeklyChallenge
}

enum LevelClearOutcome: Equatable {
  case nextLevel(Int)
  case finalWin
  case paywall
}

final class GameViewModel: ObservableObject {
  static let startingLives = 3
  static let brickScoreValue = 10

  /// Free (non-premium) runs can clear levels up to and including this
  /// one. Clearing it routes to the paywall instead of advancing.
  static let freeLevelLimit = 1
  static let maxLevel = 3

  @Published var score: Int = 0
  @Published var lives: Int = GameViewModel.startingLives
  @Published var state: GameState = .menu
  @Published var activePowerUps: Set<PowerUpType> = []
  @Published var currentLevel: Int = 1

  /// RevenueCat purchase state. Updated reactively by
  /// `observeEntitlements()` so the purchase flow and the restore flow
  /// share one source of truth (see revenuecat-entitlements-gate).
  @Published var isPremiumUnlocked = false
  @Published var hasWeeklyChallenge = false

  /// Consumable balance. RevenueCat only confirms the transaction;
  /// tracking how many tokens the player has is the app's responsibility,
  /// so this is kept in memory alongside the rest of this session's
  /// non-persisted state (score, lives, etc.).
  @Published var continueTokens = 0

  /// Context message shown on the paywall screen (e.g. why it was triggered).
  @Published var paywallBanner: String?

  private var stateBeforePaywall: GameState = .menu

  func resetForNewGame() {
    score = 0
    lives = GameViewModel.startingLives
    state = .playing
    activePowerUps.removeAll()
    currentLevel = 1
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

  /// Called when the current level's bricks are all cleared. Free
  /// (non-premium) runs stop at `freeLevelLimit` and route to the paywall
  /// instead of advancing; direct `markAsWon()` calls (e.g. testing the
  /// final win state) intentionally bypass this gate.
  @discardableResult
  func handleLevelCleared() -> LevelClearOutcome {
    if currentLevel >= GameViewModel.maxLevel {
      markAsWon()
      return .finalWin
    }
    if !isPremiumUnlocked, currentLevel >= GameViewModel.freeLevelLimit {
      showPaywall(banner: "レベル\(GameViewModel.freeLevelLimit + 1)以降は全解放パックで遊べます", returnTo: .menu)
      return .paywall
    }
    currentLevel += 1
    return .nextLevel(currentLevel)
  }

  func showPaywall(banner: String? = nil, returnTo: GameState = .menu) {
    paywallBanner = banner
    stateBeforePaywall = returnTo
    state = .paywall
  }

  func closePaywall() {
    paywallBanner = nil
    state = stateBeforePaywall
  }

  func showWeeklyChallenge() {
    guard hasWeeklyChallenge else {
      showPaywall(banner: "ウィークリーチャレンジは週額プランで解放されます")
      return
    }
    state = .weeklyChallenge
  }

  /// Spends one continue token (consumable purchase) to resume the current
  /// level with full lives.
  func continueGame() {
    guard continueTokens > 0 else { return }
    continueTokens -= 1
    lives = GameViewModel.startingLives
    state = .playing
  }

  /// Applies a successful `continue_token` consumable purchase.
  func grantContinueToken() {
    continueTokens += 1
  }

  /// Subscribes to RevenueCat's `CustomerInfo` stream for the lifetime of
  /// the calling `.task {}`. Call from a SwiftUI `.task` modifier on the
  /// root view so it starts on appear and cancels on disappear.
  @MainActor
  func observeEntitlements() async {
    for await info in Purchases.shared.customerInfoStream {
      isPremiumUnlocked = info.entitlements[RevenueCatEntitlements.premium]?.isActive == true
      hasWeeklyChallenge = info.entitlements[RevenueCatEntitlements.weeklyChallenge]?.isActive == true
    }
  }
}
