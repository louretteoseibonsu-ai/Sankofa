import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/progress_service.dart';
import '../theme.dart';
import '../widgets/composable_trotro.dart';

const Color _terra = Color(0xFFBE5235);
const Color _gold = Color(0xFFE3A92C);

/// "Tro Tro Rally" — the weekly leaderboard as a race track. Each learner is a
/// tro tro positioned by their weekly XP; yours is highlighted. Built on the
/// existing weekly board, so no new backend.
class TroTroRallyScreen extends StatelessWidget {
  const TroTroRallyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = ProgressService();
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Tro Tro Rally')),
      body: StreamBuilder<List<LeaderboardEntry>>(
        stream: service.weeklyTop(limit: 12),
        builder: (context, snap) {
          final entries = snap.data ?? const <LeaderboardEntry>[];
          if (entries.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final topXp = entries
              .map((e) => e.xp)
              .fold<int>(1, (a, b) => math.max(a, b));
          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('THIS WEEK',
                      style: TextStyle(
                          color: _terra,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5)),
                  Text('${entries.length} racers',
                      style: const TextStyle(color: slate, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),
              for (int i = 0; i < entries.length; i++)
                _Lane(
                  rank: i + 1,
                  entry: entries[i],
                  progress: (entries[i].xp / topXp).clamp(0.05, 1.0),
                  isMe: entries[i].uid == myUid,
                ),
              const SizedBox(height: 10),
              const Center(
                child: Text('Top racers promote on Sunday. Yɛn kɔ!',
                    style: TextStyle(color: slate, fontSize: 12.5)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Lane extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;
  final double progress;
  final bool isMe;
  const _Lane({
    required this.rank,
    required this.entry,
    required this.progress,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFF7E6DF) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isMe ? _terra : silverLight, width: isMe ? 2 : 1.5),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text('$rank',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isMe ? _terra : charcoal)),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 68,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isMe ? 'You' : entry.name.split(' ').first,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: ink)),
                Text('${entry.xp} XP',
                    style: const TextStyle(color: slate, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: LayoutBuilder(builder: (context, c) {
              const busW = 44.0;
              final travel = (c.maxWidth - busW - 16).clamp(0.0, double.infinity);
              return SizedBox(
                height: 34,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 14,
                      top: 16,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                            color: silverLight,
                            borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const Positioned(
                      right: 0,
                      top: 6,
                      child: Icon(Icons.sports_score_rounded,
                          color: _gold, size: 20),
                    ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      left: travel * progress,
                      top: 2,
                      child: const ComposableTroTro(
                          skin: TroTroSkin(), width: busW),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
