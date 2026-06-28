import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../data/adinkra_symbols.dart';
import '../services/progress_service.dart';
import '../theme.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final _service = ProgressService();
  bool _weekly = true;

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('This week')),
                ButtonSegment(value: false, label: Text('All time')),
              ],
              selected: {_weekly},
              onSelectionChanged: (s) => setState(() => _weekly = s.first),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<LeaderboardEntry>>(
              stream: _weekly
                  ? _service.weeklyTop(limit: 50)
                  : _service.leaderboard(),
              builder: (context, snap) {
          if (snap.hasError) {
            return const _Message(
                'Leaderboard unavailable.\nPublish the Firestore rules to enable it.');
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final entries = snap.data!;
          if (entries.isEmpty) {
            return const _Message(
                'No scores yet.\nFinish a lesson to claim the top spot!');
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final e = entries[i];
              final isMe = e.uid == me;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isMe ? const Color(0xFFFBEEEA) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isMe ? terracotta : silverLight,
                    width: isMe ? 1.6 : 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: _RankBadge(rank: i + 1),
                    ),
                    const SizedBox(width: 8),
                    _LbAvatar(photoURL: e.photoURL, name: e.name, radius: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isMe ? '${e.name}  (you)' : e.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: ink)),
                          Text('Level ${e.level}',
                              style:
                                  const TextStyle(color: slate, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text('${e.xp} XP',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: charcoal)),
                  ],
                ),
              );
            },
          );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    const medals = {1: Color(0xFFE3A92C), 2: Color(0xFFB7BCC2), 3: Color(0xFFC68A4E)};
    final c = medals[rank];
    if (c != null) {
      return CircleAvatar(
        radius: 13,
        backgroundColor: c,
        child: Text('$rank',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800)),
      );
    }
    return Text('$rank',
        textAlign: TextAlign.center,
        style: const TextStyle(
            color: slate, fontWeight: FontWeight.w700, fontSize: 14));
  }
}

class _Message extends StatelessWidget {
  final String text;
  const _Message(this.text);
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: slate, height: 1.5)),
        ),
      );
}

/// Avatar from a leaderboard entry's photoURL (adinkra token, http, or initials).
class _LbAvatar extends StatelessWidget {
  final String? photoURL;
  final String name;
  final double radius;
  const _LbAvatar(
      {required this.photoURL, required this.name, this.radius = 18});

  @override
  Widget build(BuildContext context) {
    final p = photoURL;
    if (p != null && p.startsWith('adinkra://')) {
      final parts = p.substring('adinkra://'.length).split('/');
      final glyphId = parts.isNotEmpty ? parts[0] : 'gyenyame';
      final hex = parts.length > 1 ? parts[1] : '2B2B2D';
      final value = int.tryParse('FF${hex.replaceAll('#', '')}', radix: 16) ??
          0xFF5A5E63;
      final sym = kAdinkraSymbols.firstWhere((s) => s.id == glyphId,
          orElse: () => kAdinkraSymbols.first);
      return CircleAvatar(
        radius: radius,
        backgroundColor: Color(value),
        child: SizedBox(
          width: radius * 1.2,
          height: radius * 1.2,
          child: SvgPicture.string(sym.svg,
              fit: BoxFit.contain,
              colorFilter:
                  const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
        ),
      );
    }
    if (p != null && p.startsWith('http')) {
      return CircleAvatar(radius: radius, backgroundImage: NetworkImage(p));
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: slate,
      child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'S',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: radius * 0.85)),
    );
  }
}
