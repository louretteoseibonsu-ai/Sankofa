import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../data/adinkra_symbols.dart';
import '../data/lesson_catalog.dart';
import '../services/progress_service.dart';
import '../theme.dart';
import '../widgets/animations.dart';
import '../widgets/floating_card.dart';
import '../widgets/pedis_store.dart';
import '../widgets/tappable_scale.dart';
import '../widgets/trotro_dashboard.dart';
import 'customization_shop_screen.dart';
import 'lesson_quiz_screen.dart';
import 'trotro_rally_screen.dart';
import 'upgrade_screen.dart';

const Color _gold = Color(0xFFE3A92C);
const Color _green = Color(0xFF2E6B3B);
const Color _red = Color(0xFF9B2D2A);

class ProgressDashboardScreen extends StatefulWidget {
  const ProgressDashboardScreen({super.key});

  @override
  State<ProgressDashboardScreen> createState() =>
      _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends State<ProgressDashboardScreen> {
  final _service = ProgressService();
  Stats _s = Stats.empty;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final s = await _service.loadStats();
    if (!mounted) return;
    setState(() {
      _s = s;
      _loading = false;
    });
  }

  Widget _dashPill(IconData icon, String label) => Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: silverLight, width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: charcoal),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: charcoal, fontWeight: FontWeight.w700)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final p = _s.progress;
    final totalLessons = kLessonsFlat.length;

    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!_s.premium) ...[
            _GoPremiumBanner(),
            const SizedBox(height: 14),
          ],

          // Tro tro dashboard HUD — at-a-glance speedometer + fuel.
          TroTroDashboard(
            progress:
                totalLessons == 0 ? 0 : _s.lessonsCompleted / totalLessons,
            streak: _s.streak,
            tokens: _s.pedis,
            shards: _s.shards,
            atRisk: _s.streakAtRisk,
            onRefuel: () {
              if (kLessonsFlat.isEmpty) return;
              final l = kLessonsFlat.firstWhere(
                (x) => p.unlocked(x.id) && !p.passed(x.id),
                orElse: () => kLessonsFlat.first,
              );
              Navigator.of(context)
                  .push(MaterialPageRoute(
                      builder: (_) => LessonQuizScreen(lesson: l)))
                  .then((_) => _reload());
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TappableScale(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const TroTroRallyScreen())),
                  child: _dashPill(Icons.emoji_events_rounded, 'Rally'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TappableScale(
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const CustomizationShopScreen()));
                    _reload();
                  },
                  child: _dashPill(Icons.directions_bus_rounded, 'Garage'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _LevelHero(p: p),
          const SizedBox(height: 8),

          _Section('Today', initiallyExpanded: true, children: [
            _StreakCard(s: _s),
            const SizedBox(height: 12),
            _DailyQuests(s: _s),
          ]),
          _Section('Rewards', children: [
            _TreasureCard(keys: _s.keys, onChanged: _reload),
            const SizedBox(height: 12),
            _WalletCard(pedis: _s.pedis, onChanged: _reload),
          ]),
          _Section('Stats & mastery', children: [
            Row(children: [
              _Metric(label: 'Day streak', value: '${_s.streak}', icon: '🔥'),
              const SizedBox(width: 10),
              _Metric(label: 'Total XP', value: '${p.totalXp}', icon: '⭐'),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _Metric(
                  label: 'Lessons',
                  value: '${_s.lessonsCompleted}/$totalLessons',
                  icon: '📘'),
              const SizedBox(width: 10),
              _Metric(label: 'Words', value: '${_s.wordsLearned}', icon: '🗣'),
            ]),
            const SizedBox(height: 16),
            const _SectionTitle('Mastery by subject'),
            const SizedBox(height: 8),
            for (final c in kCategories) _MasteryRow(category: c, p: p),
            const SizedBox(height: 14),
            const _SectionTitle('Adinkra badges'),
            const SizedBox(height: 10),
            _BadgeGrid(s: _s),
          ]),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

/// A collapsible section — groups related cards so the tab scans at a glance.
class _Section extends StatelessWidget {
  final String title;
  final bool initiallyExpanded;
  final List<Widget> children;
  const _Section(this.title,
      {this.initiallyExpanded = false, required this.children});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 16, color: ink)),
        initiallyExpanded: initiallyExpanded,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        shape: const Border(),
        collapsedShape: const Border(),
        children: children,
      ),
    );
  }
}

class _GoPremiumBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: charcoal,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const UpgradeScreen())),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _gold, width: 1.5),
          ),
          child: const Row(
            children: [
              Text('✦', style: TextStyle(color: _gold, fontSize: 22)),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Go Premium',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                    Text('All lessons, AI Translate, no ads — 7-day free trial',
                        style: TextStyle(color: Color(0xFFC9CCD1), fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: _gold),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Level + league ─────────────────────────────────────────────────────────
class _LevelHero extends StatelessWidget {
  final Progress p;
  const _LevelHero({required this.p});

  ({String name, String meaning}) _league(int xp) {
    if (xp >= 800) return (name: 'Ahenfie', meaning: 'the royal court');
    if (xp >= 300) return (name: 'Nkɔsoɔ', meaning: 'progress');
    return (name: 'Asɛmpa', meaning: 'good news');
  }

  @override
  Widget build(BuildContext context) {
    final lg = _league(p.totalXp);
    final pct = p.xpIntoLevel / p.xpForNextLevel;
    return FloatingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: terracotta,
                    borderRadius: BorderRadius.circular(15)),
                child: Text('${p.level}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 22)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Level ${p.level}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: ink)),
                    Text('${p.totalXp} XP total',
                        style: const TextStyle(color: slate, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: const Color(0xFFFBF1D8),
                    borderRadius: BorderRadius.circular(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('🏆 ${lg.name}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: Color(0xFF8A6A12))),
                    Text(lg.meaning,
                        style: const TextStyle(
                            color: Color(0xFFA98A3A), fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 9,
              backgroundColor: silverLight,
              valueColor: const AlwaysStoppedAnimation(terracotta),
            ),
          ),
          const SizedBox(height: 6),
          Text('${p.xpIntoLevel} / ${p.xpForNextLevel} XP to level ${p.level + 1}',
              style: const TextStyle(color: slate, fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Streak + kente cloth ────────────────────────────────────────────────────
class _StreakCard extends StatelessWidget {
  final Stats s;
  const _StreakCard({required this.s});

  @override
  Widget build(BuildContext context) {
    return FloatingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const PulseEmoji('🔥', size: 26),
              const SizedBox(width: 10),
              Text('${s.streak}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 26, color: ink)),
              const SizedBox(width: 6),
              const Text('day streak',
                  style: TextStyle(color: slate, fontSize: 14)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: glyphTile,
                    borderRadius: BorderRadius.circular(10)),
                child: Text('❄ ${s.freezes} freeze${s.freezes == 1 ? '' : 's'}',
                    style: const TextStyle(
                        color: slate,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('YOUR KENTE CLOTH',
              style: TextStyle(
                  color: slate,
                  fontWeight: FontWeight.w700,
                  fontSize: 10.5,
                  letterSpacing: 0.6)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CustomPaint(
              size: Size(double.infinity, (s.streak.clamp(1, 21)) * 9.0 + 6),
              painter: _KenteClothPainter(s.streak),
            ),
          ),
          const SizedBox(height: 6),
          Text(
              s.streak == 0
                  ? 'Finish a lesson today to start weaving your cloth.'
                  : 'Each day you practise weaves another row. Keep it going!',
              style: const TextStyle(color: slate, fontSize: 12)),
        ],
      ),
    );
  }
}

class _KenteClothPainter extends CustomPainter {
  final int streak;
  const _KenteClothPainter(this.streak);
  static const _cols = [_gold, _red, _green, Color(0xFF2B2B2D)];

  @override
  void paint(Canvas canvas, Size size) {
    final rows = streak.clamp(1, 21);
    const rowH = 9.0;
    for (int r = 0; r < rows; r++) {
      final filled = r < streak;
      final y = r * rowH;
      const seg = 6;
      final w = size.width / seg;
      for (int c = 0; c < seg; c++) {
        final base = _cols[(r + c) % _cols.length];
        final paint = Paint()
          ..color = filled ? base : silverLight;
        canvas.drawRect(Rect.fromLTWH(c * w, y, w - 1, rowH - 1), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _KenteClothPainter old) =>
      old.streak != streak;
}

// ── Daily quests ────────────────────────────────────────────────────────────
class _DailyQuests extends StatelessWidget {
  final Stats s;
  const _DailyQuests({required this.s});

  @override
  Widget build(BuildContext context) {
    final quests = <({String label, double progress, bool done})>[
      (
        label: 'Finish a lesson',
        progress: s.dailyLessons >= 1 ? 1 : 0,
        done: s.dailyLessons >= 1
      ),
      (
        label: 'Earn 50 XP',
        progress: (s.dailyXp / 50).clamp(0.0, 1.0),
        done: s.dailyXp >= 50
      ),
      (
        label: 'Ace a quiz (10/10)',
        progress: s.dailyPerfect ? 1 : 0,
        done: s.dailyPerfect
      ),
    ];
    final doneCount = quests.where((q) => q.done).length;
    return FloatingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Daily quests',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16, color: ink)),
              const Spacer(),
              Text('$doneCount / 3',
                  style: const TextStyle(
                      color: slate, fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          for (final q in quests)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(
                      q.done
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: q.done ? _green : silver,
                      size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(q.label,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: q.done ? slate : ink)),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: q.progress,
                            minHeight: 5,
                            backgroundColor: silverLight,
                            valueColor: AlwaysStoppedAnimation(
                                q.done ? _green : terracotta),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (doneCount == 3)
            const Text('All done — Ayɛkoo! Come back tomorrow.',
                style: TextStyle(
                    color: _green, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Pedis wallet ────────────────────────────────────────────────────────────
class _WalletCard extends StatefulWidget {
  final int pedis;
  final Future<void> Function() onChanged;
  const _WalletCard({required this.pedis, required this.onChanged});

  @override
  State<_WalletCard> createState() => _WalletCardState();
}

class _WalletCardState extends State<_WalletCard> {
  bool _busy = false;

  Future<void> _buyFreeze() async {
    setState(() => _busy = true);
    final ok = await ProgressService().buyFreezeWithPedis();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'Bought a streak freeze ❄ for ${ProgressService.kFreezeCost} pedis.'
            : 'Not enough pedis — earn more by finishing lessons.')));
    if (ok) await widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final canBuy = widget.pedis >= ProgressService.kFreezeCost;
    return FloatingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('◈', style: TextStyle(fontSize: 22, color: _gold)),
              const SizedBox(width: 10),
              const Text('Pedis wallet',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16, color: ink)),
              const Spacer(),
              Text('${widget.pedis}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: charcoal)),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
              'Earn pedis as you learn. Spend them on AI Translate & Lens '
              'top-ups, streak freezes, and avatars.',
              style: TextStyle(color: slate, fontSize: 12.5, height: 1.4)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: (canBuy && !_busy) ? _buyFreeze : null,
                  icon: const Icon(Icons.ac_unit, size: 16),
                  label: const Text('Freeze · ${ProgressService.kFreezeCost}'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    final bought = await showPedisStore(context,
                        currentPedis: widget.pedis);
                    if (bought > 0) await widget.onChanged();
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Get more'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Treasure chest (wisdom keys from combos) ───────────────────────────────
class _TreasureCard extends StatefulWidget {
  final int keys;
  final Future<void> Function() onChanged;
  const _TreasureCard({required this.keys, required this.onChanged});

  @override
  State<_TreasureCard> createState() => _TreasureCardState();
}

class _TreasureCardState extends State<_TreasureCard> {
  bool _busy = false;

  Future<void> _open() async {
    setState(() => _busy = true);
    final reward = await ProgressService().openChest();
    if (!mounted) return;
    setState(() => _busy = false);
    if (reward != null) {
      celebrateBurst(context);
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Text('Adaka! (Treasure)'),
          content: Text(
              'The chest opens with a drumroll — you found '
              '$reward streak freeze${reward == 1 ? '' : 's'} ❄.\n\n'
              'Use them to protect your streak on a busy day.'),
          actions: [
            FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Ayɛkoo!')),
          ],
        ),
      );
      await widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = widget.keys >= 3;
    return FloatingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🗝', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              const Text('Wisdom keys',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16, color: ink)),
              const Spacer(),
              Text('${widget.keys}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: _gold)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
              ready
                  ? 'You have enough keys to open a treasure chest!'
                  : 'Chain 3 correct answers in a lesson to earn a key. Collect 3 to open a chest.',
              style: const TextStyle(color: slate, fontSize: 12.5, height: 1.4)),
          const SizedBox(height: 10),
          Row(
            children: [
              for (int i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(i < widget.keys ? '🗝' : '▫️',
                      style: TextStyle(
                          fontSize: 18,
                          color: i < widget.keys ? null : silver)),
                ),
              const Spacer(),
              FilledButton.icon(
                onPressed: ready && !_busy ? _open : null,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.lock_open, size: 18),
                label: const Text('Open chest'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Small pieces ────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style:
          const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: ink));
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  const _Metric(
      {required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
            color: glyphTile, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 22, color: ink)),
            Text(label, style: const TextStyle(color: slate, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _MasteryRow extends StatelessWidget {
  final LessonCategory category;
  final Progress p;
  const _MasteryRow({required this.category, required this.p});
  @override
  Widget build(BuildContext context) {
    final m = p.categoryMastery(category);
    final full = m >= 1.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
              width: 26,
              child: Text(category.emoji,
                  style: const TextStyle(fontSize: 18))),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        color: ink)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: m.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: silverLight,
                    valueColor:
                        AlwaysStoppedAnimation(full ? _green : charcoal),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text('${(m * 100).round()}%',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                  color: full ? _green : slate)),
        ],
      ),
    );
  }
}

// ── Adinkra badges ──────────────────────────────────────────────────────────
class _BadgeGrid extends StatelessWidget {
  final Stats s;
  const _BadgeGrid({required this.s});

  @override
  Widget build(BuildContext context) {
    final masteredAny =
        kCategories.any((c) => s.progress.categoryMastery(c) >= 1.0);
    final badges = <({String title, String glyph, bool earned})>[
      (title: 'First Steps', glyph: 'akoma', earned: s.lessonsCompleted >= 1),
      (title: 'Streak x3', glyph: 'sankofa', earned: s.streak >= 3),
      (title: 'On Fire', glyph: 'gyenyame', earned: s.streak >= 7),
      (
        title: 'Perfectionist',
        glyph: 'dwennimmen',
        earned: s.perfectLessons >= 1
      ),
      (title: 'Scholar', glyph: 'nyame_dua', earned: s.lessonsCompleted >= 5),
      (title: 'Polyglot', glyph: 'akoma', earned: s.lessonsCompleted >= 10),
      (
        title: 'Loremaster',
        glyph: 'sankofa',
        earned: masteredAny
      ),
      (
        title: 'Centurion',
        glyph: 'dwennimmen',
        earned: s.progress.totalXp >= 1000
      ),
    ];
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.78,
      children: [for (final b in badges) _BadgeTile(b: b)],
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final ({String title, String glyph, bool earned}) b;
  const _BadgeTile({required this.b});

  @override
  Widget build(BuildContext context) {
    final svg = kAdinkraSymbols
        .firstWhere((s) => s.id == b.glyph, orElse: () => kAdinkraSymbols.first)
        .svg;
    final color = b.earned ? _gold : silver;
    return Column(
      children: [
        Container(
          width: 54,
          height: 54,
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: b.earned ? const Color(0xFF2B2B2D) : glyphTile,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: SvgPicture.string(svg,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn)),
        ),
        const SizedBox(height: 5),
        Text(b.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
                fontSize: 10.5,
                height: 1.1,
                fontWeight: FontWeight.w600,
                color: b.earned ? ink : slate)),
      ],
    );
  }
}
