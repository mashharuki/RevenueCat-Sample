import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_game/game/components/bullet_component.dart';
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

  testWithGame<InvaderGame>('should advance the enemy formation horizontally on update',
      () => InvaderGame(session: GameSession()), (game) async {
    game.spawnWave(1);
    await game.ready();
    final before = game.liveEnemies.map((e) => e.position.x).toList();

    game.update(1.0);

    final after = game.liveEnemies.map((e) => e.position.x).toList();
    expect(after, isNot(equals(before)));
  });

  testWithGame<InvaderGame>('should fire an enemy bullet once the shot interval has elapsed',
      () => InvaderGame(session: GameSession()), (game) async {
    game.spawnWave(1);
    await game.ready();

    game.update(2.0);
    await game.ready();

    final enemyBullets = game.children.whereType<BulletComponent>().where((b) => b.isEnemy);
    expect(enemyBullets, isNotEmpty);
  });

  testWithGame<InvaderGame>('should move the boss horizontally on update during a boss wave',
      () => InvaderGame(session: GameSession()), (game) async {
    game.spawnWave(5);
    await game.ready();
    final boss = game.boss;
    expect(boss, isNotNull);
    final beforeX = boss!.position.x;

    game.update(1.0);

    expect(boss.position.x, isNot(equals(beforeX)));
  });
}
