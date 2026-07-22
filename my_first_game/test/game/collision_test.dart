import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_game/game/collision.dart';

void main() {
  test('should report a hit when two boxes overlap', () {
    final hit = aabbIntersects(
      ax: 0, ay: 0, aw: 10, ah: 10,
      bx: 5, by: 5, bw: 10, bh: 10,
    );
    expect(hit, true);
  });

  test('should report no hit when boxes only touch edges', () {
    final hit = aabbIntersects(
      ax: 0, ay: 0, aw: 10, ah: 10,
      bx: 10, by: 0, bw: 10, bh: 10,
    );
    expect(hit, false);
  });

  test('should report no hit when boxes are far apart', () {
    final hit = aabbIntersects(
      ax: 0, ay: 0, aw: 10, ah: 10,
      bx: 100, by: 100, bw: 10, bh: 10,
    );
    expect(hit, false);
  });
}
