import 'package:flutter/material.dart';
import 'package:my_first_game/game/pixel_sprite.dart';
import 'pixel_sprite_component.dart';

class PlayerComponent extends PixelSpriteComponent {
  PlayerComponent()
      : super(
          sprite: InvaderSprites.player,
          pixelSize: 3,
          color: const Color(0xFFD6F8FF),
        );

  double clampX(double targetX, double canvasWidth) {
    final half = size.x / 2;
    if (targetX < half) return half;
    if (targetX > canvasWidth - half) return canvasWidth - half;
    return targetX;
  }

  void moveTo(double targetX, double canvasWidth) {
    position.x = clampX(targetX, canvasWidth) - size.x / 2;
  }
}
