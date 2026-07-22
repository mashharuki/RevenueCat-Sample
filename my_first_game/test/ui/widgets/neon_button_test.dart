import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_game/ui/widgets/neon_button.dart';

void main() {
  testWidgets('should call onPressed when tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: NeonButton(label: 'START', onPressed: () => tapped = true),
    ));
    await tester.tap(find.text('START'));
    expect(tapped, true);
  });
}
