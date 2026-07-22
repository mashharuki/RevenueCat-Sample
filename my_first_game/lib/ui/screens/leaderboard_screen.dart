import 'package:flutter/material.dart';
import 'package:my_first_game/state/game_session.dart';
import 'package:my_first_game/theme/app_theme.dart';

class LeaderboardScreen extends StatelessWidget {
  final List<LeaderboardRow> rows;
  final VoidCallback onBack;

  const LeaderboardScreen({super.key, required this.rows, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      child: Column(
        children: [
          SizedBox(
            height: 64,
            child: Row(
              children: [
                IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back, color: Colors.white)),
                Text('RANKING', style: AppTheme.orbitron(fontSize: 15, letterSpacing: 4)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                for (final row in rows)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: row.isPlayer ? const Color(0x1A00E5FF) : Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: row.isPlayer ? AppTheme.cyan.withValues(alpha: 0.5) : Colors.white10,
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 26, child: Text('${row.rank}', style: AppTheme.orbitron(fontSize: 14))),
                        Expanded(child: Text(row.name, style: AppTheme.rajdhani(fontSize: 15))),
                        Text(
                          row.score.toString().padLeft(5, '0'),
                          style: AppTheme.orbitron(fontSize: 14, color: AppTheme.cyan),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
