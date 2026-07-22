import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_game/ui/widgets/lives_indicator.dart';

void main() {
  testWidgets('should render one icon per life', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: LivesIndicator(lives: 3),
    ));
    expect(find.byKey(const ValueKey('life-icon')), findsNWidgets(3));
  });

  testWidgets('should render nothing when lives is zero', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: LivesIndicator(lives: 0),
    ));
    expect(find.byKey(const ValueKey('life-icon')), findsNothing);
  });
}
