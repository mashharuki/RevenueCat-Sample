import 'dart:math' as math;
import 'package:my_first_game/game/models/enemy_type.dart';

class EnemySpec {
  final double x;
  final double y;
  final double w;
  final double h;
  final EnemyType type;

  const EnemySpec({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.type,
  });
}

class WaveGenerator {
  static const double canvasWidth = 358;

  static bool isBossWave(int wave) => wave % 5 == 0;

  static double enemySpeedForWave(int wave) => 0.55 + wave * 0.05;

  static int bossHpForWave(int wave) => 24 + wave * 5;

  static List<EnemySpec> enemiesForWave(int wave) {
    final rows = math.min(3 + (wave / 3).floor(), 5);
    final cols = math.min(5 + (wave / 4).floor(), 8);
    const margin = 24.0;
    final colWidth = (canvasWidth - margin * 2) / cols;
    final specs = <EnemySpec>[];
    for (var r = 0; r < rows; r++) {
      final type = EnemyType.values[r % 3];
      for (var c = 0; c < cols; c++) {
        specs.add(EnemySpec(
          x: margin + c * colWidth + colWidth / 2 - 16,
          y: 84 + r * 42,
          w: 32,
          h: 32,
          type: type,
        ));
      }
    }
    return specs;
  }
}
