import 'package:flutter/material.dart';
import 'package:my_first_game/theme/app_theme.dart';

enum EnemyType { alpha, beta, gamma }

extension EnemyTypeStats on EnemyType {
  int get points => switch (this) {
        EnemyType.alpha => 30,
        EnemyType.beta => 20,
        EnemyType.gamma => 10,
      };

  Color get color => switch (this) {
        EnemyType.alpha => AppTheme.pink,
        EnemyType.beta => AppTheme.cyan,
        EnemyType.gamma => AppTheme.orange,
      };
}
