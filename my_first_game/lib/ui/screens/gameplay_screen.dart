import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:my_first_game/game/invader_game.dart';
import 'package:my_first_game/state/game_session.dart';
import 'package:my_first_game/theme/app_theme.dart';
import 'package:my_first_game/ui/widgets/hud_bar.dart';
import 'package:my_first_game/ui/widgets/neon_button.dart';

class GameplayScreen extends StatefulWidget {
  final GameSession session;

  const GameplayScreen({super.key, required this.session});

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  late InvaderGame _game;

  @override
  void initState() {
    super.initState();
    _game = InvaderGame(session: widget.session);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        return Container(
          color: AppTheme.background,
          child: Column(
            children: [
              HudBar(
                score: widget.session.score,
                wave: widget.session.wave,
                lives: widget.session.lives,
                onPause: widget.session.pauseGame,
              ),
              Expanded(
                child: Stack(
                  children: [
                    GameWidget(game: _game),
                    if (widget.session.hitFlash)
                      IgnorePointer(
                        child: Container(color: AppTheme.danger.withValues(alpha: 0.2)),
                      ),
                    if (widget.session.screen == AppScreen.paused) _PauseOverlay(session: widget.session),
                  ],
                ),
              ),
              Container(
                height: 40,
                alignment: Alignment.center,
                child: Text(
                  'ドラッグで移動・タップで発射',
                  style: AppTheme.rajdhani(fontSize: 11, color: Colors.white38),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  final GameSession session;

  const _PauseOverlay({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xB2030409),
      alignment: Alignment.center,
      child: Container(
        width: 280,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 26),
        decoration: BoxDecoration(
          color: const Color(0xE50E1224),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('PAUSED', style: AppTheme.orbitron(fontSize: 22, letterSpacing: 4)),
            const SizedBox(height: 18),
            NeonButton(label: 'RESUME', onPressed: session.resumeGame),
            const SizedBox(height: 12),
            NeonButton(label: 'RESTART', onPressed: session.restartGame, primary: false),
            const SizedBox(height: 12),
            NeonButton(label: 'HOME', onPressed: session.goHome, primary: false),
          ],
        ),
      ),
    );
  }
}
