import 'package:flame/components.dart';
import 'package:my_first_game/game/pixel_sprite.dart';
import 'package:my_first_game/theme/app_theme.dart';
import 'pixel_sprite_component.dart';

class BossComponent extends PixelSpriteComponent {
  int hp;
  final int maxHp;
  double dir = 1;
  double vx = 1.1;
  double shootAtMs = 0;

  BossComponent({required this.hp, required this.maxHp})
      : super(
          sprite: InvaderSprites.boss,
          pixelSize: 4,
          color: AppTheme.purple,
          position: Vector2(0, 70),
        );
}
