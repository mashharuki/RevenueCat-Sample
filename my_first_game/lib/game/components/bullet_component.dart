import 'package:flame/components.dart';
import 'package:flutter/material.dart';

bool canShoot({
  required double nowMs,
  required double lastShotMs,
  double cooldownMs = 320,
}) {
  return nowMs - lastShotMs >= cooldownMs;
}

class BulletComponent extends PositionComponent {
  final double velocityY;
  final bool isEnemy;
  final double canvasHeight;
  final Color color;

  BulletComponent({
    required Vector2 position,
    required this.velocityY,
    required this.canvasHeight,
    this.isEnemy = false,
    this.color = const Color(0xFFD6F8FF),
  }) : super(position: position, size: Vector2(3, 14), anchor: Anchor.topLeft);

  bool get isOffscreen => isEnemy ? position.y > canvasHeight + 20 : position.y < -20;

  @override
  void update(double dt) {
    position.y += velocityY * dt * 60;
    if (isOffscreen) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = isEnemy ? const Color(0xFFFF3B5C) : color;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), paint);
  }
}
