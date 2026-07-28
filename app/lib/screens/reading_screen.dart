import 'package:flutter/material.dart';
import '../data/avatar.dart';
import '../data/reading_passages.dart';
import '../services/progress_service.dart';
import '../theme.dart';
import '../widgets/velvet.dart';
import '../widgets/challenge_quiz.dart';
import '../widgets/floating_card.dart';
import '../widgets/skeleton.dart';
import '../widgets/speak_button.dart';
import '../widgets/state_message.dart';
import 'tools_hub_screen.dart' show velvetToolsTheme;

/// Progressive list of reading passages — pass one to unlock the next.
class ReadingListScreen extends StatefulWidget {
  /// When true, show only the folklore (Anansesɛm) passages, ungated.
  final bool folkloreOnly;
  const ReadingListScreen({super.key, this.folkloreOnly = false});

  @override
  State<ReadingListScreen> createState() => _ReadingListScreenState();
}

class _ReadingListScreenState extends State<ReadingListScreen> {
  final _service = ProgressService();
  Set<String> _passed = {};
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    try {
      final passed = await _service.loadReadingPassed();
      if (!mounted) return;
      setState(() {
        _passed = passed;
        _loading = false;
        _error = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  List<ReadingPassage> get _passages => widget.folkloreOnly
      ? kReadingPassages.where((p) => p.level == 'Folklore').toList()
      : kReadingPassages;

  bool _unlocked(int i) =>
      widget.folkloreOnly || i == 0 || _passed.contains(_passages[i - 1].id);

  Future<void> _open(ReadingPassage p) async {
    final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => ReadingDetailScreen(passage: p)));
    if (result == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SkeletonListView(rows: 5);
    if (_error) {
      return StateMessage(
        icon: Icons.wifi_off_rounded,
        title: 'Couldn’t load your reading',
        subtitle: 'Check your connection and try again.',
        actionLabel: 'Retry',
        onAction: () {
          setState(() => _loading = true);
          _reload();
        },
      );
    }
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
              widget.folkloreOnly
                  ? 'Anansesɛm — Spider Tales'
                  : 'Reading & Comprehension',
              style: displayFont(
                  fontSize: 26, fontWeight: FontWeight.w800, color: kVelvetInk)),
          const SizedBox(height: 4),
          Text(
              widget.folkloreOnly
                  ? 'Pull up to the fire and hear a folktale. '
                      '${_passages.length} stories to explore.'
                  : '${_passed.length} / ${_passages.length} passages passed. '
                      'Score 60% or more to pass and unlock the next.',
              style: const TextStyle(color: kVelvetMuted, fontSize: 13.5, height: 1.5)),
          const SizedBox(height: 16),
          for (int i = 0; i < _passages.length; i++)
            _PassageRow(
              passage: _passages[i],
              unlocked: _unlocked(i),
              passed: _passed.contains(_passages[i].id),
              onOpen: () => _open(_passages[i]),
            ),
        ],
      ),
    );
  }
}

class _PassageRow extends StatelessWidget {
  final ReadingPassage passage;
  final bool unlocked;
  final bool passed;
  final VoidCallback onOpen;
  const _PassageRow({
    required this.passage,
    required this.unlocked,
    required this.passed,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color iconColor;
    if (passed) {
      icon = Icons.check_circle;
      iconColor = const Color(0xFF2E6B3B);
    } else if (unlocked) {
      icon = passage.level == 'Folklore'
          ? Icons.local_fire_department_rounded // Story Stop
          : Icons.menu_book_outlined;
      iconColor = terracotta;
    } else {
      icon = Icons.lock_outline;
      iconColor = silver;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FloatingCard(
        onTap: unlocked ? onOpen : null,
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(passage.title,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: unlocked ? kVelvetInk : kVelvetMuted)),
                  Text(
                      unlocked
                          ? '${passage.level}  ·  pass ${passage.passMark}/${passage.questions.length}'
                          : 'Locked — pass the previous passage',
                      style: const TextStyle(color: kVelvetMuted, fontSize: 12.5)),
                ],
              ),
            ),
            if (unlocked)
              const Icon(Icons.chevron_right, color: Colors.white30),
          ],
        ),
      ),
    );
  }
}

/// A single passage: read (with audio) → reveal translation → comprehension.
class ReadingDetailScreen extends StatefulWidget {
  final ReadingPassage passage;
  const ReadingDetailScreen({super.key, required this.passage});

  @override
  State<ReadingDetailScreen> createState() => _ReadingDetailScreenState();
}

class _ReadingDetailScreenState extends State<ReadingDetailScreen> {
  final _service = ProgressService();
  bool _showEnglish = false;
  bool _started = false;

  Future<void> _onPassed() async {
    await _service.markReadingPassed(widget.passage.id);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.passage;
    // Pushed as its own route, so re-apply the Tools dark theme here.
    return Theme(
      data: velvetToolsTheme(context),
      child: Scaffold(
        appBar: AppBar(title: Text(p.title)),
        body: SafeArea(
          child: _started ? _buildQuiz(p) : _buildReading(p),
        ),
      ),
    );
  }

  // ── Reading view ──
  Widget _buildReading(ReadingPassage p) {
    final folklore = p.culturalContext.isNotEmpty;
    // Beginner/Elementary read best line-by-line (interlinear); higher levels
    // and folklore graduate to a flowing paragraph to build reading fluency.
    final interlinear = (p.level == 'Beginner' || p.level == 'Elementary') &&
        p.lineGloss.length == p.lines.length;
    return ListView(
      padding: EdgeInsets.fromLTRB(20, folklore ? 12 : 20, 20, 20),
      children: [
        if (folklore) ...[
          const _StoryStopHeader(),
          const SizedBox(height: 16),
        ] else ...[
          Text(p.level.toUpperCase(),
              style: const TextStyle(
                  color: terracotta,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 1.2)),
          const SizedBox(height: 10),
        ],
        if (interlinear) ...[
          // ── A · Interlinear: each Twi line with its English beneath ──
          FloatingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < p.lines.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 22, color: Color(0x14FFFFFF)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.lines[i],
                                style: const TextStyle(
                                    fontSize: 18,
                                    height: 1.4,
                                    fontWeight: FontWeight.w600,
                                    color: kVelvetInk)),
                            const SizedBox(height: 3),
                            Text(p.lineGloss[i],
                                style: const TextStyle(
                                    fontSize: 13.5,
                                    height: 1.35,
                                    color: kVelvetMuted)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      SpeakButton(text: p.lines[i], size: 22),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Text('English sits under each line · tap 🔊 to hear it.',
              style: TextStyle(color: kVelvetMuted, fontSize: 12)),
        ] else ...[
          // ── C · Flowing paragraph: read the whole passage as continuous Twi ──
          FloatingCard(
            child: Text(p.lines.join(' '),
                style: const TextStyle(
                    fontSize: 18, height: 1.7, color: kVelvetInk)),
          ),
          const SizedBox(height: 10),
          _ListenStrip(lines: p.lines),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _showEnglish = !_showEnglish),
              icon: Icon(
                  _showEnglish
                      ? Icons.visibility_off_outlined
                      : Icons.translate,
                  size: 18),
              label:
                  Text(_showEnglish ? 'Hide translation' : 'Show translation'),
            ),
          ),
          if (_showEnglish) ...[
            const SizedBox(height: 4),
            FloatingCard(
              child: Text(p.english,
                  style: const TextStyle(
                      fontSize: 15, height: 1.6, color: kVelvetMuted)),
            ),
          ],
        ],
        // ── Folklore framework: cultural note + key words ──
        if (p.culturalContext.isNotEmpty) ...[
          const SizedBox(height: 18),
          const Text('CULTURAL NOTE',
              style: TextStyle(
                  color: terracotta,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 1.2)),
          const SizedBox(height: 6),
          FloatingCard(
            child: Text(p.culturalContext,
                style: const TextStyle(fontSize: 14, height: 1.55, color: kVelvetInk)),
          ),
        ],
        if (p.vocab.isNotEmpty) ...[
          const SizedBox(height: 18),
          const Text('KEY WORDS',
              style: TextStyle(
                  color: terracotta,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 1.2)),
          const SizedBox(height: 6),
          FloatingCard(
            child: Column(
              children: [
                for (int i = 0; i < p.vocab.length; i++) ...[
                  if (i > 0) const Divider(height: 14, color: const Color(0x1FFFFFFF)),
                  Row(
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 14, color: kVelvetInk, height: 1.4),
                            children: [
                              TextSpan(
                                  text: p.vocab[i].key,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800, color: kVelvetInk)),
                              TextSpan(
                                  text: '  —  ${p.vocab[i].value}',
                                  style: const TextStyle(color: kVelvetMuted)),
                            ],
                          ),
                        ),
                      ),
                      SpeakButton(text: p.vocab[i].key, size: 20),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        _PassLegend(passMark: p.passMark, total: p.questions.length),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => setState(() => _started = true),
          child: const Text('Start comprehension'),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── Quiz view (with listen-again strip + pass legend) ──
  Widget _buildQuiz(ReadingPassage p) {
    return Column(
      children: [
        _ListenStrip(lines: p.lines),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: _PassLegend(passMark: p.passMark, total: p.questions.length),
        ),
        Expanded(
          child: ChallengeQuiz(
            challenges: p.questions,
            maxQuestions: p.questions.length,
            kicker: 'Comprehension · ${p.title}',
            passMode: true,
            passThreshold: 0.6,
            onPassed: _onPassed,
            passButtonLabel: 'Done',
          ),
        ),
      ],
    );
  }
}

/// "Pass mark: X of Y correct" — sets expectations before/while testing.
class _PassLegend extends StatelessWidget {
  final int passMark;
  final int total;
  const _PassLegend({required this.passMark, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2A211C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_outlined, size: 18, color: kVelvetMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Pass mark: $passMark of $total correct (60%). '
              'Below that, you can retry.',
              style: const TextStyle(
                  color: kVelvetMuted, fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal strip of numbered speaker buttons so learners can re-hear any
/// line while answering the comprehension questions.
class _ListenStrip extends StatelessWidget {
  final List<String> lines;
  const _ListenStrip({required this.lines});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
      color: const Color(0xFF2A211C),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Listen again',
              style: TextStyle(
                  color: kVelvetMuted, fontSize: 11.5, fontWeight: FontWeight.w800)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < lines.length; i++)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${i + 1}',
                          style: const TextStyle(
                              color: kVelvetMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                      SpeakButton(text: lines[i], size: 18),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Evening "Story Stop" header for folklore passages: your equipped family
/// member walks up and settles by a campfire under a starry velvet sky, framing
/// the tale like an Anansesɛm told at night.
class _StoryStopHeader extends StatefulWidget {
  const _StoryStopHeader();

  @override
  State<_StoryStopHeader> createState() => _StoryStopHeaderState();
}

class _StoryStopHeaderState extends State<_StoryStopHeader>
    with TickerProviderStateMixin {
  late final AnimationController _c; // one-shot walk-up (from the left)
  late final AnimationController _bob; // gentle idle bob once by the fire
  Avatar _avatar = avatarById(kDefaultAvatarId); // your equipped family member

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..forward();
    _bob = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    try {
      final cos = await ProgressService().loadCosmetics();
      final a = avatarById(cos.equipped['avatar']);
      if (mounted) setState(() => _avatar = a);
    } catch (_) {
      // Keep the default storyteller if cosmetics can't load.
    }
  }

  @override
  void dispose() {
    _c.dispose();
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 172,
        width: double.infinity,
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF141110), // velvet night sky
                      Color(0xFF1E1712),
                      Color(0xFF3A241A), // warm ember glow toward the ground
                    ],
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 14,
              left: 0,
              right: 0,
              child: Center(
                child: Text('STORY STOP · ANANSESƐM',
                    style: TextStyle(
                        color: Color(0xFFF3ECDD),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5)),
              ),
            ),
            Positioned(
              top: 24,
              right: 28,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Color(0xFFF0E6C8)),
              ),
            ),
            const Positioned(
                top: 42, left: 44, child: _Star(9)),
            const Positioned(
                top: 60, left: 150, child: _Star(7)),
            const Positioned(
                top: 34, left: 208, child: _Star(8)),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(height: 42, color: const Color(0xFF17130F)),
            ),
            const Positioned(
              bottom: 12,
              right: 40,
              child: _Campfire(),
            ),
            // Anansesɛm are the spider-tales told round the evening fire, so your
            // equipped family member walks up and settles by the campfire with a
            // gentle idle bob to open the tale.
            AnimatedBuilder(
              animation: Listenable.merge([_c, _bob]),
              builder: (_, __) {
                final t = Curves.easeOutCubic.transform(_c.value);
                final x = -150 + 235 * t;
                final bob = 4.0 * Curves.easeInOut.transform(_bob.value);
                return Positioned(
                  bottom: 8,
                  left: x,
                  child: Transform.translate(
                    offset: Offset(0, -bob),
                    child: Image.asset(
                      _avatar.assetReference,
                      height: 128,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox(
                          width: 90, height: 128),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Star extends StatelessWidget {
  final double size;
  const _Star(this.size);
  @override
  Widget build(BuildContext context) => Text('✦',
      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: size));
}

/// A small hand-drawn campfire — crossed logs + three flame layers that flicker.
class _Campfire extends StatefulWidget {
  const _Campfire();
  @override
  State<_Campfire> createState() => _CampfireState();
}

class _CampfireState extends State<_Campfire>
    with SingleTickerProviderStateMixin {
  late final AnimationController _f = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1300))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 46,
        height: 54,
        child: AnimatedBuilder(
          animation: _f,
          builder: (_, __) =>
              CustomPaint(painter: _CampfirePainter(_f.value)),
        ),
      );
}

class _CampfirePainter extends CustomPainter {
  final double t; // 0..1 flicker
  _CampfirePainter(this.t);

  @override
  void paint(Canvas c, Size s) {
    final cx = s.width / 2;
    final baseY = s.height - 12;
    // ember glow
    c.drawCircle(
        Offset(cx, s.height - 8),
        15,
        Paint()
          ..color = const Color(0x33FF8A2B)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    // crossed logs
    final log = Paint()
      ..color = const Color(0xFF5A3A24)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(cx - 16, s.height - 4), Offset(cx + 16, s.height - 11), log);
    c.drawLine(Offset(cx + 16, s.height - 4), Offset(cx - 16, s.height - 11), log);
    // flames (sway + height flicker)
    final sway = (t - 0.5) * 4;
    final hf = 1.0 + 0.10 * (t - 0.5) * 2;
    Path flame(double w, double h) {
      final tipx = cx + sway * (h / 40);
      return Path()
        ..moveTo(cx - w / 2, baseY)
        ..quadraticBezierTo(cx - w * 0.55, baseY - h * 0.55, tipx, baseY - h)
        ..quadraticBezierTo(cx + w * 0.55, baseY - h * 0.55, cx + w / 2, baseY)
        ..quadraticBezierTo(cx, baseY + 2, cx - w / 2, baseY)
        ..close();
    }

    c.drawPath(flame(28, 40 * hf), Paint()..color = const Color(0xFFD64525));
    c.drawPath(flame(19, 29 * hf), Paint()..color = const Color(0xFFF0862A));
    c.drawPath(flame(10, 16 * hf), Paint()..color = const Color(0xFFFFD23F));
  }

  @override
  bool shouldRepaint(covariant _CampfirePainter old) => old.t != t;
}
