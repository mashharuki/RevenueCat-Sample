import 'package:flutter/material.dart';
import 'package:my_first_game/state/game_session.dart';
import 'package:my_first_game/theme/app_theme.dart';
import 'package:my_first_game/ui/screens/game_over_screen.dart';
import 'package:my_first_game/ui/screens/gameplay_screen.dart';
import 'package:my_first_game/ui/screens/leaderboard_screen.dart';
import 'package:my_first_game/ui/screens/paywall_screen.dart';
import 'package:my_first_game/ui/screens/title_screen.dart';
import 'package:my_first_game/ui/screens/weekly_challenge_screen.dart';

class InvaderApp extends StatefulWidget {
  const InvaderApp({super.key});

  @override
  State<InvaderApp> createState() => _InvaderAppState();
}

class _InvaderAppState extends State<InvaderApp> {
  final _session = GameSession();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: AppTheme.background),
      home: Scaffold(
        body: AnimatedBuilder(
          animation: _session,
          builder: (context, _) {
            return switch (_session.screen) {
              AppScreen.title => TitleScreen(
                  onStart: _session.startGame,
                  onShowLeaderboard: _session.showLeaderboard,
                  onShowPaywall: _session.showPaywall,
                  onShowWeeklyChallenge: _session.showWeeklyChallenge,
                  hasWeeklyChallenge: _session.hasWeeklyChallenge,
                ),
              AppScreen.playing || AppScreen.paused => GameplayScreen(
                  key: ValueKey(_session.runId),
                  session: _session,
                ),
              AppScreen.gameOver => GameOverScreen(
                  result: _session.lastResult,
                  continueTokens: _session.continueTokens,
                  onRetry: _session.restartGame,
                  onContinue: _session.continueGame,
                  onBuyContinueToken: () => _session.showPaywall(
                    banner: 'コンティニュートークンを購入すると続きからプレイできます',
                    returnTo: AppScreen.gameOver,
                  ),
                  onShowLeaderboard: _session.showLeaderboard,
                  onHome: _session.goHome,
                ),
              AppScreen.leaderboard => LeaderboardScreen(
                  rows: _session.leaderboardRows,
                  onBack: _session.backToTitle,
                ),
              AppScreen.paywall => PaywallScreen(session: _session),
              AppScreen.weeklyChallenge => WeeklyChallengeScreen(onBack: _session.goHome),
            };
          },
        ),
      ),
    );
  }
}
