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

  testWithGame<InvaderGame>('should not fire an enemy bullet before the shot interval elapses',
      () => InvaderGame(session: GameSession()), (game) async {
    game.spawnWave(1);
    await game.ready();

    game.update(0.001);
    await game.ready();

    final enemyBullets = game.children.whereType<BulletComponent>().where((b) => b.isEnemy);
    expect(enemyBullets, isEmpty);
  });

  testWithGame<InvaderGame>('should fire an enemy bullet once the shot interval has elapsed',
      () => InvaderGame(session: GameSession()), (game) async {
    game.spawnWave(1);
    await game.ready();
    game.enemyShotAtMs = 0;

    game.update(0.001);
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

  // These two run under `testWidgets` (rather than `testWithGame`, which uses
  // a plain `test`) because clearing the last enemy in a wave schedules the
  // next wave via `Future.delayed(1300ms)`. `testWidgets` runs its body in a
  // FakeAsync zone, so `tester.pump(duration)` deterministically advances
  // that timer without a real wall-clock wait.
  //
  // NOTE: unlike the `testWithGame` cases above, these do NOT call
  // `await game.ready()`. `ready()` internally loops on
  // `await Future<void>.delayed(Duration.zero)`, and a zero-duration timer
  // created inside a FakeAsync zone never fires unless the fake clock is
  // explicitly elapsed — so awaiting it here would hang the test forever.
  // `game.update(0)` calls `processLifecycleEvents()` synchronously
  // (see FlameGame.updateTree in the installed flame package), which is
  // enough to flush pending add/remove operations without waiting on a Future.
  testWidgets('should advance to the next wave after the delayed timer elapses when not stopped',
      (tester) async {
    final session = GameSession();
    final game = await initializeGame<InvaderGame>(() => InvaderGame(session: session));
    game.spawnWave(1);
    game.update(0);

    for (final enemy in game.liveEnemies.toList()) {
      game.registerHit(enemy);
    }
    expect(game.liveEnemies, isEmpty);
    expect(session.wave, 1);

    await tester.pump(const Duration(milliseconds: 1300));
    game.update(0);

    expect(session.wave, 2);
    expect(game.liveEnemies, isNotEmpty);
  });

  testWidgets('should not advance the wave once stop() has been called, guarding a stale timer',
      (tester) async {
    final session = GameSession();
    final game = await initializeGame<InvaderGame>(() => InvaderGame(session: session));
    game.spawnWave(1);
    game.update(0);

    for (final enemy in game.liveEnemies.toList()) {
      game.registerHit(enemy);
    }
    expect(game.liveEnemies, isEmpty);
    expect(session.wave, 1);

    // Simulate the run ending (e.g. player died, screen torn down) before
    // the 1300ms wave-transition timer fires.
    expect(() => game.stop(), returnsNormally);

    await tester.pump(const Duration(milliseconds: 1300));
    game.update(0);

    // The stale timer must be a no-op: no new wave spawned, HUD untouched.
    expect(session.wave, 1);
    expect(game.liveEnemies, isEmpty);
  });
}
