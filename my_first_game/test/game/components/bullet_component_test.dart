import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:my_first_game/game/components/bullet_component.dart';

void main() {
  test('should allow shooting when cooldown has elapsed', () {
    expect(canShoot(nowMs: 1000, lastShotMs: 600, cooldownMs: 320), true);
  });

  test('should block shooting when still within cooldown', () {
    expect(canShoot(nowMs: 1000, lastShotMs: 900, cooldownMs: 320), false);
  });

  test('should mark an upward player bullet offscreen once above the canvas', () {
    final bullet = BulletComponent(
      position: Vector2(10, -25),
      velocityY: -9,
      canvasHeight: 670,
    );
    expect(bullet.isOffscreen, true);
  });

  test('should mark a downward enemy bullet offscreen once below the canvas', () {
    final bullet = BulletComponent(
      position: Vector2(10, 700),
      velocityY: 4.5,
      isEnemy: true,
      canvasHeight: 670,
    );
    expect(bullet.isOffscreen, true);
  });
}
