import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_game/state/game_session.dart';

void main() {
  test('should start on the title screen', () {
    final session = GameSession();
    expect(session.screen, AppScreen.title);
  });

  test('should reset score/lives/wave and switch to playing on startGame', () {
    final session = GameSession()..updateHud(score: 999, lives: 0, wave: 9);
    session.startGame();
    expect(session.screen, AppScreen.playing);
    expect(session.score, 0);
    expect(session.lives, 3);
    expect(session.wave, 1);
  });

  test('should switch to paused on pauseGame and back to playing on resumeGame', () {
    final session = GameSession()..startGame();
    session.pauseGame();
    expect(session.screen, AppScreen.paused);
    session.resumeGame();
    expect(session.screen, AppScreen.playing);
  });

  test('should notify listeners when updateHud changes fields', () {
    final session = GameSession();
    var notified = false;
    session.addListener(() => notified = true);
    session.updateHud(score: 50, lives: 2, wave: 2);
    expect(notified, true);
    expect(session.score, 50);
    expect(session.lives, 2);
    expect(session.wave, 2);
  });

  test('should record a new high score and best run on endGame when beaten', () {
    final session = GameSession();
    final startingHigh = session.highScore;
    session.endGame(finalScore: startingHigh + 100, finalWave: 4);
    expect(session.screen, AppScreen.gameOver);
    expect(session.lastResult.isNewHigh, true);
    expect(session.highScore, startingHigh + 100);
    expect(session.bestRun?.score, startingHigh + 100);
  });

  test('should not flag a new high score on endGame when not beaten', () {
    final session = GameSession();
    session.endGame(finalScore: 1, finalWave: 1);
    expect(session.lastResult.isNewHigh, false);
  });

  test('should include the player as YOU in leaderboardRows after a best run', () {
    final session = GameSession();
    session.endGame(finalScore: 999999, finalWave: 20);
    final rows = session.leaderboardRows;
    expect(rows.length, lessThanOrEqualTo(10));
    expect(rows.first.name, 'YOU');
    expect(rows.first.isPlayer, true);
  });

  test('should navigate title/leaderboard/home screens', () {
    final session = GameSession();
    session.showLeaderboard();
    expect(session.screen, AppScreen.leaderboard);
    session.backToTitle();
    expect(session.screen, AppScreen.title);
    session.startGame();
    session.goHome();
    expect(session.screen, AppScreen.title);
  });
}
