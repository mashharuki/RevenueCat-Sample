import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_game/app/invader_app.dart';

void main() {
  testWidgets('should show the title screen on launch', (tester) async {
    await tester.pumpWidget(const InvaderApp());
    expect(find.text('INVADERS'), findsOneWidget);
  });

  testWidgets('should navigate to the leaderboard screen from the title screen', (tester) async {
    await tester.pumpWidget(const InvaderApp());
    await tester.tap(find.text('🏆 RANKING'));
    await tester.pump();
    expect(find.text('RANKING'), findsOneWidget);
  });
}
