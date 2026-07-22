import 'package:flutter/material.dart';
import 'package:my_first_game/theme/app_theme.dart';
import 'package:my_first_game/ui/widgets/neon_button.dart';

class TitleScreen extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onShowLeaderboard;

  const TitleScreen({
    super.key,
    required this.onStart,
    required this.onShowLeaderboard,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('NEON', style: AppTheme.orbitron(fontSize: 15, color: AppTheme.cyan, letterSpacing: 8)),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppTheme.cyan, AppTheme.pink],
              ).createShader(bounds),
              child: Text('INVADERS', style: AppTheme.orbitron(fontSize: 52, color: Colors.white)),
            ),
            Text(
              'PROTOTYPE BUILD',
              style: AppTheme.rajdhani(fontSize: 13, color: Colors.white38, letterSpacing: 5),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 260,
              child: Column(
                children: [
                  NeonButton(label: '▶ START', onPressed: onStart),
                  const SizedBox(height: 16),
                  NeonButton(label: '🏆 RANKING', onPressed: onShowLeaderboard, primary: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
