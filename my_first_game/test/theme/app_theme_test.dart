import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_game/theme/app_theme.dart';

void main() {
  test('should expose the neon palette from the design spec', () {
    expect(AppTheme.cyan, const Color(0xFF00E5FF));
    expect(AppTheme.pink, const Color(0xFFFF2EA6));
    expect(AppTheme.orange, const Color(0xFFFFB84D));
    expect(AppTheme.purple, const Color(0xFFB026FF));
    expect(AppTheme.background, const Color(0xFF05060F));
    expect(AppTheme.danger, const Color(0xFFFF3B5C));
  });

  testWidgets('should build an Orbitron text style with requested size', (WidgetTester tester) async {
    final style = AppTheme.orbitron(fontSize: 22, color: AppTheme.cyan);
    expect(style.fontSize, 22);
    expect(style.color, AppTheme.cyan);
  });

  testWidgets('should build a Rajdhani text style with requested size', (WidgetTester tester) async {
    final style = AppTheme.rajdhani(fontSize: 14);
    expect(style.fontSize, 14);
  });
}
