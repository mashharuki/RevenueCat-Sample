import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class _Star {
  double x;
  double y;
  final double radius;
  final double speed;

  _Star({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
  });
}

class StarfieldComponent extends PositionComponent {
  final int starCount;
  final _random = Random();
  final List<_Star> _stars = [];

  StarfieldComponent({this.starCount = 60, super.size});

  @override
  Future<void> onLoad() async {
    for (var i = 0; i < starCount; i++) {
      _stars.add(
        _Star(
          x: _random.nextDouble() * size.x,
          y: _random.nextDouble() * size.y,
          radius: _random.nextDouble() * 1.4 + 0.3,
          speed: _random.nextDouble() * 0.4 + 0.1,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    for (final star in _stars) {
      star.y += star.speed * dt * 60;
      if (star.y > size.y) star.y = 0;
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.5);
    for (final star in _stars) {
      canvas.drawCircle(Offset(star.x, star.y), star.radius, paint);
    }
  }
}
