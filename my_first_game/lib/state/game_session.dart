import 'package:flutter/foundation.dart';
import 'package:my_first_game/game/models/game_result.dart';
import 'package:my_first_game/game/models/leaderboard_entry.dart';
import 'package:my_first_game/services/purchase_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

enum AppScreen { title, playing, paused, gameOver, leaderboard, paywall, weeklyChallenge }

class LeaderboardRow {
  final int rank;
  final String name;
  final int score;
  final bool isPlayer;

  const LeaderboardRow({
    required this.rank,
    required this.name,
    required this.score,
    required this.isPlayer,
  });
}

class GameSession extends ChangeNotifier {
  /// Free players can clear waves up to and including this one. Reaching the
  /// next wave without [isPremiumUnlocked] routes to the paywall instead.
  static const int freeWaveLimit = 3;

  AppScreen screen = AppScreen.title;
  int runId = 0;
  int score = 0;
  int lives = 3;
  int wave = 1;
  bool bossActive = false;
  int bossHp = 0;
  int bossMaxHp = 0;
  bool hitFlash = false;
  int highScore = 4200;
  GameResult? bestRun;
  GameResult lastResult = const GameResult(score: 0, wave: 1);

  /// RevenueCat purchase state. Updated reactively by
  /// [Purchases.addCustomerInfoUpdateListener] so the purchase flow and the
  /// restore flow share one source of truth (see revenuecat-entitlements-gate).
  bool isPremiumUnlocked = false;
  bool hasWeeklyChallenge = false;

  /// Consumable balance. RevenueCat only confirms the transaction; tracking
  /// how many tokens the player has is the app's responsibility, so this is
  /// kept in memory alongside the rest of this session's non-persisted state
  /// (score, highScore, etc.).
  int continueTokens = 0;

  /// Context message shown on the paywall screen (e.g. why it was triggered).
  String? paywallBanner;

  CustomerInfoUpdateListener? _customerInfoListener;

  GameSession() {
    if (isPurchasesSupported) {
      final listener = _applyCustomerInfo;
      _customerInfoListener = listener;
      Purchases.addCustomerInfoUpdateListener(listener);
      Purchases.getCustomerInfo().then(_applyCustomerInfo).catchError((_) {
        // Network/auth error on first load; the listener will still fire on
        // the next successful refresh.
      });
    }
  }

  void _applyCustomerInfo(CustomerInfo info) {
    final premium = info.entitlements.active.containsKey(RevenueCatEntitlements.premium);
    final weekly = info.entitlements.active.containsKey(RevenueCatEntitlements.weeklyChallenge);
    if (premium == isPremiumUnlocked && weekly == hasWeeklyChallenge) return;
    isPremiumUnlocked = premium;
    hasWeeklyChallenge = weekly;
    notifyListeners();
  }

  @override
  void dispose() {
    final listener = _customerInfoListener;
    if (listener != null) {
      Purchases.removeCustomerInfoUpdateListener(listener);
    }
    super.dispose();
  }

  final List<LeaderboardEntry> leaderboard = const [
    LeaderboardEntry(name: 'ACE', score: 9800),
    LeaderboardEntry(name: 'NOVA', score: 8700),
    LeaderboardEntry(name: 'RYU', score: 7600),
    LeaderboardEntry(name: 'ZERO', score: 6400),
    LeaderboardEntry(name: 'KAI', score: 5300),
    LeaderboardEntry(name: 'MIA', score: 4700),
    LeaderboardEntry(name: 'LEO', score: 3900),
    LeaderboardEntry(name: 'YUI', score: 3200),
    LeaderboardEntry(name: 'REN', score: 2600),
    LeaderboardEntry(name: 'SORA', score: 2100),
  ];

  void startGame() {
    runId++;
    screen = AppScreen.playing;
    score = 0;
    lives = 3;
    wave = 1;
    bossActive = false;
    bossHp = 0;
    bossMaxHp = 0;
    hitFlash = false;
    notifyListeners();
  }

  void pauseGame() {
    screen = AppScreen.paused;
    notifyListeners();
  }

  void resumeGame() {
    screen = AppScreen.playing;
    notifyListeners();
  }

  void restartGame() => startGame();

  void goHome() {
    screen = AppScreen.title;
    notifyListeners();
  }

  void showLeaderboard() {
    screen = AppScreen.leaderboard;
    notifyListeners();
  }

  void backToTitle() {
    screen = AppScreen.title;
    notifyListeners();
  }

  AppScreen _paywallReturnScreen = AppScreen.title;

  void showPaywall({String? banner, AppScreen returnTo = AppScreen.title}) {
    paywallBanner = banner;
    _paywallReturnScreen = returnTo;
    screen = AppScreen.paywall;
    notifyListeners();
  }

  void closePaywall() {
    paywallBanner = null;
    screen = _paywallReturnScreen;
    notifyListeners();
  }

  void showWeeklyChallenge() {
    if (!hasWeeklyChallenge) {
      showPaywall(banner: 'ウィークリーチャレンジは週額プランで解放されます');
      return;
    }
    screen = AppScreen.weeklyChallenge;
    notifyListeners();
  }

  /// Called when the enemy formation would advance past [freeWaveLimit]
  /// without [isPremiumUnlocked]. Ends the run at its current score/wave and
  /// routes to the paywall instead of spawning the next wave.
  void reachWaveLimit() {
    lastResult = GameResult(score: score, wave: wave, isNewHigh: score > highScore);
    if (score > highScore) highScore = score;
    if (bestRun == null || score > bestRun!.score) {
      bestRun = GameResult(score: score, wave: wave);
    }
    showPaywall(banner: 'WAVE ${freeWaveLimit + 1}以降は全解放パックでプレイできます');
  }

  /// Spends one continue token (consumable purchase) to resume the run at
  /// the current score/wave with full lives.
  void continueGame() {
    if (continueTokens <= 0) return;
    continueTokens--;
    runId++;
    lives = 3;
    hitFlash = false;
    screen = AppScreen.playing;
    notifyListeners();
  }

  /// Applies a successful `continue_token` consumable purchase.
  void grantContinueToken() {
    continueTokens++;
    notifyListeners();
  }

  void updateHud({
    int? score,
    int? lives,
    int? wave,
    bool? bossActive,
    int? bossHp,
    int? bossMaxHp,
  }) {
    if (score != null) this.score = score;
    if (lives != null) this.lives = lives;
    if (wave != null) this.wave = wave;
    if (bossActive != null) this.bossActive = bossActive;
    if (bossHp != null) this.bossHp = bossHp;
    if (bossMaxHp != null) this.bossMaxHp = bossMaxHp;
    notifyListeners();
  }

  void triggerHitFlash() {
    hitFlash = true;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 220), () {
      hitFlash = false;
      notifyListeners();
    });
  }

  void endGame({required int finalScore, required int finalWave}) {
    final isNewHigh = finalScore > highScore;
    lastResult = GameResult(
      score: finalScore,
      wave: finalWave,
      isNewHigh: isNewHigh,
    );
    if (isNewHigh) highScore = finalScore;
    if (bestRun == null || finalScore > bestRun!.score) {
      bestRun = GameResult(score: finalScore, wave: finalWave);
    }
    lives = 0;
    screen = AppScreen.gameOver;
    notifyListeners();
  }

  List<LeaderboardRow> get leaderboardRows {
    final entries = [
      for (final e in leaderboard) (name: e.name, score: e.score, isPlayer: false),
      if (bestRun != null) (name: 'YOU', score: bestRun!.score, isPlayer: true),
    ]..sort((a, b) => b.score.compareTo(a.score));

    return entries.take(10).toList().asMap().entries.map((entry) {
      final row = entry.value;
      return LeaderboardRow(
        rank: entry.key + 1,
        name: row.name,
        score: row.score,
        isPlayer: row.isPlayer,
      );
    }).toList();
  }
}
