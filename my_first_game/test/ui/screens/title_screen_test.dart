import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_game/ui/screens/title_screen.dart';

void main() {
  testWidgets('should show the game title and call onStart when START is tapped', (tester) async {
    var started = false;
    await tester.pumpWidget(MaterialApp(
      home: TitleScreen(
        onStart: () => started = true,
        onShowLeaderboard: () {},
        onShowPaywall: () {},
        onShowWeeklyChallenge: () {},
        hasWeeklyChallenge: false,
      ),
    ));
    expect(find.text('INVADERS'), findsOneWidget);
    await tester.tap(find.text('▶ START'));
    expect(started, true);
  });

  testWidgets('should call onShowLeaderboard when ranking is tapped', (tester) async {
    var shown = false;
    await tester.pumpWidget(MaterialApp(
      home: TitleScreen(
        onStart: () {},
        onShowLeaderboard: () => shown = true,
        onShowPaywall: () {},
        onShowWeeklyChallenge: () {},
        hasWeeklyChallenge: false,
      ),
    ));
    await tester.tap(find.text('🏆 RANKING'));
    expect(shown, true);
  });

  testWidgets('should call onShowPaywall when UPGRADE is tapped', (tester) async {
    var shown = false;
    await tester.pumpWidget(MaterialApp(
      home: TitleScreen(
        onStart: () {},
        onShowLeaderboard: () {},
        onShowPaywall: () => shown = true,
        onShowWeeklyChallenge: () {},
        hasWeeklyChallenge: false,
      ),
    ));
    await tester.tap(find.text('⭐ UPGRADE'));
    expect(shown, true);
  });

  testWidgets('should show a locked icon for WEEKLY CHALLENGE when not subscribed', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: TitleScreen(
        onStart: () {},
        onShowLeaderboard: () {},
        onShowPaywall: () {},
        onShowWeeklyChallenge: () {},
        hasWeeklyChallenge: false,
      ),
    ));
    expect(find.text('🔒 WEEKLY CHALLENGE'), findsOneWidget);
  });
}
