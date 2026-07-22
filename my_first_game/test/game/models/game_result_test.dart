import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_game/game/models/game_result.dart';

void main() {
  test('should consider two results with the same fields equal', () {
    const a = GameResult(score: 500, wave: 3, isNewHigh: true);
    const b = GameResult(score: 500, wave: 3, isNewHigh: true);
    expect(a, b);
  });

  test('should default isNewHigh to false when omitted', () {
    const result = GameResult(score: 100, wave: 1);
    expect(result.isNewHigh, false);
  });
}
