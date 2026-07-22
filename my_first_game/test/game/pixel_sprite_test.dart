import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_game/game/pixel_sprite.dart';

void main() {
  test('should report column and row counts from the bit pattern', () {
    const sprite = PixelSprite(['010', '111']);
    expect(sprite.columns, 3);
    expect(sprite.rowCount, 2);
  });

  test('should return one offset per filled cell in row-major order', () {
    const sprite = PixelSprite(['010', '101']);
    final cells = sprite.filledCells();
    expect(cells, [
      const Offset(1, 0),
      const Offset(0, 1),
      const Offset(2, 1),
    ]);
  });

  test('should expose the five prototype sprites with correct sizes', () {
    expect(InvaderSprites.enemyAlpha.rowCount, 8);
    expect(InvaderSprites.player.rowCount, 8);
    expect(InvaderSprites.boss.rowCount, 10);
    expect(InvaderSprites.boss.columns, 16);
  });
}
