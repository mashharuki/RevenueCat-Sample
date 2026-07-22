import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_game/game/models/enemy_type.dart';
import 'package:my_first_game/theme/app_theme.dart';

void main() {
  test('should award 30 points and pink color for alpha enemies', () {
    expect(EnemyType.alpha.points, 30);
    expect(EnemyType.alpha.color, AppTheme.pink);
  });

  test('should award 20 points and cyan color for beta enemies', () {
    expect(EnemyType.beta.points, 20);
    expect(EnemyType.beta.color, AppTheme.cyan);
  });

  test('should award 10 points and orange color for gamma enemies', () {
    expect(EnemyType.gamma.points, 10);
    expect(EnemyType.gamma.color, AppTheme.orange);
  });
}
