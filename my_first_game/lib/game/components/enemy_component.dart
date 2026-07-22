import 'package:flame/components.dart';
import 'package:my_first_game/game/models/enemy_type.dart';
import 'package:my_first_game/game/pixel_sprite.dart';
import 'package:my_first_game/game/wave_generator.dart';
import 'pixel_sprite_component.dart';

class EnemyComponent extends PixelSpriteComponent {
  final EnemyType type;
  final int points;
  bool alive = true;

  EnemyComponent({required EnemySpec spec})
      : type = spec.type,
        points = spec.type.points,
        super(
          sprite: _spriteFor(spec.type),
          pixelSize: 4,
          color: spec.type.color,
          position: Vector2(spec.x, spec.y),
        );

  static PixelSprite _spriteFor(EnemyType type) => switch (type) {
        EnemyType.alpha => InvaderSprites.enemyAlpha,
        EnemyType.beta => InvaderSprites.enemyBeta,
        EnemyType.gamma => InvaderSprites.enemyGamma,
      };
}
