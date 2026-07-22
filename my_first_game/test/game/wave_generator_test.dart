import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_game/game/models/enemy_type.dart';
import 'package:my_first_game/game/wave_generator.dart';

void main() {
  test('should not treat wave 1 as a boss wave', () {
    expect(WaveGenerator.isBossWave(1), false);
  });

  test('should treat every fifth wave as a boss wave', () {
    expect(WaveGenerator.isBossWave(5), true);
    expect(WaveGenerator.isBossWave(10), true);
    expect(WaveGenerator.isBossWave(7), false);
  });

  test('should generate a 3x5 grid of enemies for wave 1', () {
    final enemies = WaveGenerator.enemiesForWave(1);
    expect(enemies.length, 15);
  });

  test('should grow the enemy grid as the wave number increases', () {
    final wave1 = WaveGenerator.enemiesForWave(1).length;
    final wave12 = WaveGenerator.enemiesForWave(12).length;
    expect(wave12, greaterThan(wave1));
  });

  test('should assign enemy types by row using type index mod 3', () {
    final enemies = WaveGenerator.enemiesForWave(1);
    final firstRowType = enemies.first.type;
    expect(firstRowType, EnemyType.alpha);
  });

  test('should increase enemy speed as the wave number increases', () {
    expect(
      WaveGenerator.enemySpeedForWave(10),
      greaterThan(WaveGenerator.enemySpeedForWave(1)),
    );
  });

  test('should scale boss hp with wave number', () {
    expect(WaveGenerator.bossHpForWave(5), 24 + 5 * 5);
    expect(WaveGenerator.bossHpForWave(10), 24 + 10 * 5);
  });
}
