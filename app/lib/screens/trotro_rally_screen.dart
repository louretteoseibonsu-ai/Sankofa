import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/velvet.dart';
import 'leaderboard_screen.dart' show LeaderboardView;

/// Weekly Rally — the weekly leaderboard. Finish lessons to climb the board;
/// the top learners promote on Sunday. Simplified from the old tro-tro race
/// track now that the bus is retired — it reuses the shared [LeaderboardView].
class TroTroRallyScreen extends StatelessWidget {
  const TroTroRallyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kVelvetTop,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: kVelvetInk,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text('Weekly Rally',
            style: displayFont(
                fontSize: 19, fontWeight: FontWeight.w700, color: kVelvetInk)),
      ),
      body: const Column(
        children: [
          Expanded(child: LeaderboardView()),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Text('Top learners promote on Sunday. Yɛn kɔ!',
                textAlign: TextAlign.center,
                style: TextStyle(color: kVelvetMuted, fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}
