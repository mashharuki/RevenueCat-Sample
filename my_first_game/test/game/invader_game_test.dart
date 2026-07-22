import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_game/game/invader_game.dart';
import 'package:my_first_game/state/game_session.dart';

void main() {
  final session = GameSession();
  final game = InvaderGame(session: session);

  testWithGame<InvaderGame>('should mount a player after onLoad', () => game, (game) async {
    expect(game.player, isNotNull);
  });

  testWithGame<InvaderGame>('should spawn 15 enemies for wave 1', () => InvaderGame(session: GameSession()),
      (game) async {
    game.spawnWave(1);
    await game.ready();
    expect(game.liveEnemies.length, 15);
  });

  testWithGame<InvaderGame>('should reduce live enemy count and add score on registerHit',
      () => InvaderGame(session: GameSession()), (game) async {
    game.spawnWave(1);
    await game.ready();
    final target = game.liveEnemies.first;
    final before = game.liveEnemies.length;
    game.registerHit(target);
    await game.ready();
    expect(game.liveEnemies.length, before - 1);
    expect(game.session.score, target.points);
  });
}
