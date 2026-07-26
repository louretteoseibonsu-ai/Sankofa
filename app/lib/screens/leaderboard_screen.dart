import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../data/adinkra_symbols.dart';
import '../data/special_avatars.dart';
import '../services/progress_service.dart';
import '../theme.dart';
import '../widgets/velvet.dart';

/// Pushed full-screen leaderboard (with its own app bar + back button).
class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF141110),
      appBar: null,
      body: SafeArea(
        child: Column(
          children: [
            _LbHeader(),
            Expanded(child: LeaderboardView()),
          ],
        ),
      ),
    );
  }
}

class _LbHeader extends StatelessWidget {
  const _LbHeader();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: kVelvetInk),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const Text('Leaderboard',
              style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 20, color: kVelvetInk)),
        ],
      ),
    );
  }
}

/// Body-only leaderboard (no Scaffold) — used inside the app shell tab.
class LeaderboardView extends StatefulWidget {
  const LeaderboardView({super.key});

  @override
  State<LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends State<LeaderboardView> {
  final _service = ProgressService();

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser?.uid;
    return Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(Icons.emoji_events_outlined, size: 18, color: terracotta),
                SizedBox(width: 8),
                Text('This week',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: kVelvetInk)),
                Spacer(),
                Text('Resets every Monday',
                    style: TextStyle(color: kVelvetMuted, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<LeaderboardEntry>>(
              stream: _service.weeklyTop(limit: 50),
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
                  color: isMe ? const Color(0xFF2C1D18) : const Color(0xFF211B17),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isMe ? terracotta : Colors.white10,
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
                          Row(
                            children: [
                              Flexible(
                                child: Text(isMe ? '${e.name}  (you)' : e.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: kVelvetInk)),
                              ),
                              if (e.isBot)
                                const Padding(
                                  padding: EdgeInsets.only(left: 5),
                                  child: Icon(Icons.circle,
                                      size: 5, color: silver),
                                ),
                            ],
                          ),
                          Text('Level ${e.level}',
                              style:
                                  const TextStyle(color: kVelvetMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text('${e.xp} XP',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: kVelvetInk)),
                  ],
                ),
              );
            },
          );
              },
            ),
          ),
        ],
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
            color: kVelvetMuted, fontWeight: FontWeight.w700, fontSize: 14));
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
              style: const TextStyle(color: kVelvetMuted, height: 1.5)),
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
      final svg = glyphId == kAnanseGlyphId
          ? kAnanseSvg
          : kAdinkraSymbols
              .firstWhere((s) => s.id == glyphId,
                  orElse: () => kAdinkraSymbols.first)
              .svg;
      return CircleAvatar(
        radius: radius,
        backgroundColor: Color(value),
        child: SizedBox(
          width: radius * 1.2,
          height: radius * 1.2,
          child: SvgPicture.string(svg,
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
      backgroundColor: kVelvetMuted,
      child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'S',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: radius * 0.85)),
    );
  }
}
