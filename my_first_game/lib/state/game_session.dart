import 'package:flutter/foundation.dart';
import 'package:my_first_game/game/models/game_result.dart';
import 'package:my_first_game/game/models/leaderboard_entry.dart';

enum AppScreen { title, playing, paused, gameOver, leaderboard }

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
  AppScreen screen = AppScreen.title;
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
