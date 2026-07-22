import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_game/game/components/player_component.dart';

void main() {
  test('should clamp the player within the canvas bounds', () {
    final player = PlayerComponent();
    expect(player.clampX(-50, 358), greaterThanOrEqualTo(0));
    expect(player.clampX(9999, 358), lessThanOrEqualTo(358));
  });

  test('should return the requested x when within bounds', () {
    final player = PlayerComponent();
    expect(player.clampX(180, 358), 180);
  });
}
