import 'dart:ui' show ImageFilter;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../data/adinkra_symbols.dart';
import '../services/auth_service.dart';
import '../services/progress_service.dart';
import '../theme.dart';
import '../widgets/adinkra_glyph.dart';
import '../widgets/floating_card.dart';
import 'leaderboard_screen.dart';
import 'upgrade_screen.dart';

/// Symbols free up to this index; the rest require premium.
const int kFreeSymbols = 10;

class SymbolsScreen extends StatefulWidget {
  const SymbolsScreen({super.key});

  @override
  State<SymbolsScreen> createState() => _SymbolsScreenState();
}

class _SymbolsScreenState extends State<SymbolsScreen> {
  bool _premium = false;

  @override
  void initState() {
    super.initState();
    AuthService().isPremium().then((v) {
      if (mounted) setState(() => _premium = v);
    });
  }

  void _openUpgrade() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const UpgradeScreen()));

  /// Time-aware Akan greeting.
  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Maakye'; // good morning
    if (h < 17) return 'Maaha'; // good afternoon
    return 'Maadwo'; // good evening
  }

  String _firstName(User? u) {
    final dn = u?.displayName?.trim();
    if (dn != null && dn.isNotEmpty) return dn.split(' ').first;
    final email = u?.email;
    if (email != null && email.contains('@')) return email.split('@').first;
    return 'friend';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamBuilder<User?>(
          stream: FirebaseAuth.instance.userChanges(),
          builder: (context, snap) {
            final u = snap.data ?? FirebaseAuth.instance.currentUser;
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 2),
              child: Text(
                '${_greeting()}, ${_firstName(u)}',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 22, color: terracotta),
              ),
            );
          },
        ),
        const _WeeklyTop3Strip(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
          child: Text(
            'Adinkra Symbols',
            style: displayFont(fontSize: 26, fontWeight: FontWeight.w800),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Text(
            'Ancestral wisdom in visual form.',
            style: TextStyle(color: inkSoft, fontSize: 14.5),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: kAdinkraSymbols.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, i) {
              final s = kAdinkraSymbols[i];
              final locked = !_premium && i >= kFreeSymbols;
              return FloatingCard(
                onTap: locked ? _openUpgrade : () => _showDetail(context, s),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: glyphTile,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        // Locked symbols are blurred + faded so they read as a
                        // teaser, not a freebie.
                        child: locked
                            ? ImageFiltered(
                                imageFilter: ImageFilter.blur(
                                    sigmaX: 6, sigmaY: 6),
                                child: Opacity(
                                  opacity: 0.5,
                                  child: AdinkraGlyph(svg: s.svg, size: 48),
                                ),
                              )
                            : AdinkraGlyph(svg: s.svg, size: 48),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            // Hide the real name behind the paywall.
                            locked ? 'Premium symbol' : s.name,
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                color: locked ? slate : ink),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            locked ? 'Unlock with Premium' : s.value,
                            style: const TextStyle(
                                color: plantainGreen, fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Icon(locked ? Icons.lock : Icons.chevron_right,
                        color: locked ? const Color(0xFFE3A92C) : Colors.black26),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showDetail(BuildContext context, AdinkraSymbol s) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // Cap the sheet so long descriptions scroll instead of pushing content
      // off-screen on small phones.
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (ctx) => SafeArea(
        // Adds the device's bottom inset so the last line clears the gesture /
        // navigation bar.
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: glyphTile,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: AdinkraGlyph(svg: s.svg, size: 88),
                ),
              ),
              const SizedBox(height: 16),
              Text(s.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 22, color: ink)),
              Text('"${s.literal}"',
                  style: const TextStyle(
                      fontStyle: FontStyle.italic, color: Colors.black54)),
              const SizedBox(height: 8),
              Text(s.value,
                  style: const TextStyle(
                      color: plantainGreen, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Text(s.description,
                  style: const TextStyle(height: 1.5, color: ink)),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact "Top 3 this week" strip; taps through to the full leaderboard.
class _WeeklyTop3Strip extends StatelessWidget {
  const _WeeklyTop3Strip();

  static const _medals = [Color(0xFFE3A92C), Color(0xFFB7BCC2), Color(0xFFC68A4E)];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LeaderboardEntry>>(
      stream: ProgressService().weeklyTop(limit: 3),
      builder: (context, snap) {
        final list = snap.data ?? const [];
        if (list.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const LeaderboardScreen())),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: silverLight, width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.emoji_events_outlined,
                            size: 18, color: terracotta),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text('Top 3 this week',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: ink)),
                        ),
                        Row(
                          children: [
                            Text('Leaderboard',
                                style: TextStyle(color: slate, fontSize: 12)),
                            Icon(Icons.chevron_right,
                                size: 18, color: Colors.black26),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    for (int i = 0; i < list.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 11,
                              backgroundColor: _medals[i],
                              child: Text('${i + 1}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(list[i].name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: ink)),
                                  ),
                                  if (list[i].isBot)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 5),
                                      child: Icon(Icons.circle,
                                          size: 4.5, color: silver),
                                    ),
                                ],
                              ),
                            ),
                            Text('${list[i].xp} XP',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: charcoal)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
