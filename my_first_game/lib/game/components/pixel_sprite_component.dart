import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:my_first_game/game/pixel_sprite.dart';

class PixelSpriteComponent extends PositionComponent {
  final PixelSprite sprite;
  final double pixelSize;
  final Color color;

  PixelSpriteComponent({
    required this.sprite,
    required this.pixelSize,
    required this.color,
    super.position,
    super.anchor = Anchor.topLeft,
  }) : super(
          size: Vector2(
            sprite.columns * pixelSize,
            sprite.rowCount * pixelSize,
          ),
        );

  @override
  void render(Canvas canvas) {
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final solidPaint = Paint()..color = color;

    for (final cell in sprite.filledCells()) {
      final rect = Rect.fromLTWH(
        cell.dx * pixelSize,
        cell.dy * pixelSize,
        pixelSize,
        pixelSize,
      );
      canvas.drawRect(rect, glowPaint);
      canvas.drawRect(rect, solidPaint);
    }
  }
}
