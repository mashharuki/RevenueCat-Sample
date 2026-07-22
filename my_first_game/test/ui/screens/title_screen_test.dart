import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_game/ui/screens/title_screen.dart';

void main() {
  testWidgets('should show the game title and call onStart when START is tapped', (tester) async {
    var started = false;
    await tester.pumpWidget(MaterialApp(
      home: TitleScreen(onStart: () => started = true, onShowLeaderboard: () {}),
    ));
    expect(find.text('INVADERS'), findsOneWidget);
    await tester.tap(find.text('▶ START'));
    expect(started, true);
  });

  testWidgets('should call onShowLeaderboard when ranking is tapped', (tester) async {
    var shown = false;
    await tester.pumpWidget(MaterialApp(
      home: TitleScreen(onStart: () {}, onShowLeaderboard: () => shown = true),
    ));
    await tester.tap(find.text('🏆 RANKING'));
    expect(shown, true);
  });
}
