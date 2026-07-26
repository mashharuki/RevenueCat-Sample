import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_game/game/models/game_result.dart';
import 'package:my_first_game/ui/screens/game_over_screen.dart';

void main() {
  testWidgets('should display the final score and wave', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GameOverScreen(
          result: const GameResult(score: 1234, wave: 5),
          continueTokens: 0,
          onRetry: () {},
          onContinue: () {},
          onBuyContinueToken: () {},
          onShowLeaderboard: () {},
          onHome: () {},
        ),
      ),
    );
    expect(find.text('1234'), findsOneWidget);
    expect(find.textContaining('5'), findsWidgets);
  });

  testWidgets('should show a NEW RECORD badge when isNewHigh is true', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GameOverScreen(
          result: const GameResult(score: 1234, wave: 5, isNewHigh: true),
          continueTokens: 0,
          onRetry: () {},
          onContinue: () {},
          onBuyContinueToken: () {},
          onShowLeaderboard: () {},
          onHome: () {},
        ),
      ),
    );
    expect(find.text('NEW RECORD'), findsOneWidget);
  });

  testWidgets('should call onRetry when RETRY is tapped', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: GameOverScreen(
          result: const GameResult(score: 0, wave: 1),
          continueTokens: 0,
          onRetry: () => retried = true,
          onContinue: () {},
          onBuyContinueToken: () {},
          onShowLeaderboard: () {},
          onHome: () {},
        ),
      ),
    );
    await tester.tap(find.text('RETRY'));
    expect(retried, true);
  });

  testWidgets('should show a buy-token button when continueTokens is 0', (
    tester,
  ) async {
    var buyTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: GameOverScreen(
          result: const GameResult(score: 0, wave: 1),
          continueTokens: 0,
          onRetry: () {},
          onContinue: () {},
          onBuyContinueToken: () => buyTapped = true,
          onShowLeaderboard: () {},
          onHome: () {},
        ),
      ),
    );
    expect(find.textContaining('コンティニュートークンを購入'), findsOneWidget);
    await tester.tap(find.textContaining('コンティニュートークンを購入'));
    expect(buyTapped, true);
  });

  testWidgets(
    'should call onContinue when CONTINUE is tapped and tokens remain',
    (tester) async {
      var continued = false;
      await tester.pumpWidget(
        MaterialApp(
          home: GameOverScreen(
            result: const GameResult(score: 0, wave: 1),
            continueTokens: 2,
            onRetry: () {},
            onContinue: () => continued = true,
            onBuyContinueToken: () {},
            onShowLeaderboard: () {},
            onHome: () {},
          ),
        ),
      );
      expect(find.textContaining('CONTINUE'), findsOneWidget);
      await tester.tap(find.textContaining('CONTINUE'));
      expect(continued, true);
    },
  );
}
