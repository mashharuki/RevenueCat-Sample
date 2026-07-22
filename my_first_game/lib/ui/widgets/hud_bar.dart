import 'package:flutter/material.dart';
import 'package:my_first_game/theme/app_theme.dart';
import 'lives_indicator.dart';

class HudBar extends StatelessWidget {
  final int score;
  final int wave;
  final int lives;
  final VoidCallback onPause;

  const HudBar({
    super.key,
    required this.score,
    required this.wave,
    required this.lives,
    required this.onPause,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      color: const Color(0xE60A0E1C),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('SCORE', style: AppTheme.rajdhani(fontSize: 9, color: Colors.white54)),
              Text(
                score.toString().padLeft(6, '0'),
                style: AppTheme.orbitron(fontSize: 18, color: AppTheme.cyan),
              ),
            ],
          ),
          Text('WAVE $wave', style: AppTheme.orbitron(fontSize: 12, color: AppTheme.orange)),
          Row(
            children: [
              LivesIndicator(lives: lives),
              const SizedBox(width: 10),
              IconButton(
                onPressed: onPause,
                icon: const Icon(Icons.pause, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
