import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class ParticleComponent extends PositionComponent {
  final Vector2 velocity;
  final Color color;
  double life;
  final double maxLife;

  ParticleComponent({
    required Vector2 position,
    required this.velocity,
    required this.color,
    required this.life,
  })  : maxLife = life,
        super(position: position, size: Vector2.all(4), anchor: Anchor.center);

  bool get isExpired => life <= 0;

  @override
  void update(double dt) {
    position += velocity * dt * 60;
    life -= dt * 60;
    if (isExpired) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = color.withValues(alpha: (life / maxLife).clamp(0, 1));
    canvas.drawCircle(Offset.zero, 2.2, paint);
  }
}
