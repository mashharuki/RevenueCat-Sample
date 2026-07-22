import 'package:flutter/material.dart';
import 'package:my_first_game/game/models/game_result.dart';
import 'package:my_first_game/theme/app_theme.dart';
import 'package:my_first_game/ui/widgets/neon_button.dart';

class GameOverScreen extends StatelessWidget {
  final GameResult result;
  final VoidCallback onRetry;
  final VoidCallback onShowLeaderboard;
  final VoidCallback onHome;

  const GameOverScreen({
    super.key,
    required this.result,
    required this.onRetry,
    required this.onShowLeaderboard,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('GAME OVER', style: AppTheme.orbitron(fontSize: 34, color: AppTheme.danger)),
            const SizedBox(height: 26),
            Container(
              width: 260,
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: const Color(0xD90E1224),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Text('FINAL SCORE', style: AppTheme.rajdhani(fontSize: 10, color: Colors.white38)),
                  Text(result.score.toString(), style: AppTheme.orbitron(fontSize: 36, color: AppTheme.cyan)),
                  Text('到達ウェーブ ${result.wave}', style: AppTheme.rajdhani(fontSize: 12)),
                  if (result.isNewHigh) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0x26FFB84D),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'NEW RECORD',
                        style: AppTheme.orbitron(fontSize: 10, color: AppTheme.orange),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: 260,
              child: Column(
                children: [
                  NeonButton(label: 'RETRY', onPressed: onRetry),
                  const SizedBox(height: 12),
                  NeonButton(label: 'RANKING', onPressed: onShowLeaderboard, primary: false),
                  const SizedBox(height: 12),
                  NeonButton(label: 'HOME', onPressed: onHome, primary: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
