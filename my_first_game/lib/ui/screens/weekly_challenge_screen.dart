import 'package:flutter/material.dart';

import 'package:my_first_game/theme/app_theme.dart';
import 'package:my_first_game/ui/widgets/neon_button.dart';

/// Placeholder screen unlocked by the `weekly_challenge` subscription
/// entitlement. Demonstrates gating a whole screen behind an active
/// RevenueCat subscription rather than a single feature toggle.
class WeeklyChallengeScreen extends StatelessWidget {
  final VoidCallback onBack;

  const WeeklyChallengeScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'WEEKLY CHALLENGE',
              style: AppTheme.orbitron(fontSize: 24, color: AppTheme.purple),
            ),
            const SizedBox(height: 16),
            Text(
              '今週のお題: ノーダメージでWAVE 7に到達せよ',
              style: AppTheme.rajdhani(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 220,
              child: NeonButton(
                label: 'HOME',
                onPressed: onBack,
                primary: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
