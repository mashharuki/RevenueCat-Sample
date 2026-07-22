import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_game/state/game_session.dart';
import 'package:my_first_game/ui/screens/leaderboard_screen.dart';

void main() {
  testWidgets('should list each row with rank and name', (tester) async {
    const rows = [
      LeaderboardRow(rank: 1, name: 'ACE', score: 9800, isPlayer: false),
      LeaderboardRow(rank: 2, name: 'YOU', score: 500, isPlayer: true),
    ];
    await tester.pumpWidget(const MaterialApp(
      home: LeaderboardScreen(rows: rows, onBack: _noop),
    ));
    expect(find.text('ACE'), findsOneWidget);
    expect(find.text('YOU'), findsOneWidget);
  });
}

void _noop() {}
