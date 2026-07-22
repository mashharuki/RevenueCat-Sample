import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_game/game/models/game_result.dart';
import 'package:my_first_game/ui/screens/game_over_screen.dart';

void main() {
  testWidgets('should display the final score and wave', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: GameOverScreen(
        result: const GameResult(score: 1234, wave: 5),
        onRetry: () {},
        onShowLeaderboard: () {},
        onHome: () {},
      ),
    ));
    expect(find.text('1234'), findsOneWidget);
    expect(find.textContaining('5'), findsWidgets);
  });

  testWidgets('should show a NEW RECORD badge when isNewHigh is true', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: GameOverScreen(
        result: const GameResult(score: 1234, wave: 5, isNewHigh: true),
        onRetry: () {},
        onShowLeaderboard: () {},
        onHome: () {},
      ),
    ));
    expect(find.text('NEW RECORD'), findsOneWidget);
  });

  testWidgets('should call onRetry when RETRY is tapped', (tester) async {
    var retried = false;
    await tester.pumpWidget(MaterialApp(
      home: GameOverScreen(
        result: const GameResult(score: 0, wave: 1),
        onRetry: () => retried = true,
        onShowLeaderboard: () {},
        onHome: () {},
      ),
    ));
    await tester.tap(find.text('RETRY'));
    expect(retried, true);
  });
}
