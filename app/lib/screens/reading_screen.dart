import 'package:flutter/material.dart';
import '../data/reading_passages.dart';
import '../services/progress_service.dart';
import '../theme.dart';
import '../widgets/challenge_quiz.dart';
import '../widgets/floating_card.dart';
import '../widgets/speak_button.dart';
import '../widgets/state_message.dart';
import '../widgets/tintable_trotro.dart';

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
    if (_loading) return const Center(child: CircularProgressIndicator());
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
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 26, color: ink)),
          const SizedBox(height: 4),
          Text(
              widget.folkloreOnly
                  ? 'Pull up to the fire and hear a folktale. '
                      '${_passages.length} stories to explore.'
                  : '${_passed.length} / ${_passages.length} passages passed. '
                      'Score 60% or more to pass and unlock the next.',
              style: const TextStyle(color: slate, fontSize: 13.5, height: 1.5)),
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
                          color: unlocked ? ink : slate)),
                  Text(
                      unlocked
                          ? '${passage.level}  ·  pass ${passage.passMark}/${passage.questions.length}'
                          : 'Locked — pass the previous passage',
                      style: const TextStyle(color: slate, fontSize: 12.5)),
                ],
              ),
            ),
            if (unlocked)
              const Icon(Icons.chevron_right, color: Colors.black26),
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
    return Scaffold(
      appBar: AppBar(title: Text(p.title)),
      body: SafeArea(
        child: _started ? _buildQuiz(p) : _buildReading(p),
      ),
    );
  }

  // ── Reading view ──
  Widget _buildReading(ReadingPassage p) {
    final folklore = p.culturalContext.isNotEmpty;
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
        FloatingCard(
          child: Column(
            children: [
              for (int i = 0; i < p.lines.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, color: silverLight),
                Row(
                  children: [
                    Expanded(
                      child: Text(p.lines[i],
                          style: const TextStyle(
                              fontSize: 18, height: 1.5, color: ink)),
                    ),
                    SpeakButton(text: p.lines[i], size: 22),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text('Tap 🔊 to hear each line.',
            style: TextStyle(color: slate, fontSize: 12)),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _showEnglish = !_showEnglish),
            icon: Icon(
                _showEnglish ? Icons.visibility_off_outlined : Icons.translate,
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
                    fontSize: 15, height: 1.6, color: slate)),
          ),
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
                style: const TextStyle(fontSize: 14, height: 1.55, color: ink)),
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
                  if (i > 0) const Divider(height: 14, color: silverLight),
                  Row(
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 14, color: ink, height: 1.4),
                            children: [
                              TextSpan(
                                  text: p.vocab[i].key,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800, color: ink)),
                              TextSpan(
                                  text: '  —  ${p.vocab[i].value}',
                                  style: const TextStyle(color: slate)),
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
        color: glyphTile,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_outlined, size: 18, color: slate),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Pass mark: $passMark of $total correct (60%). '
              'Below that, you can retry.',
              style: const TextStyle(
                  color: slate, fontSize: 12.5, fontWeight: FontWeight.w600),
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
      color: const Color(0xFFF7F5F0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Listen again',
              style: TextStyle(
                  color: slate, fontSize: 11.5, fontWeight: FontWeight.w800)),
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
                              color: slate,
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

/// Evening "Story Stop" header for folklore passages: the celebratory tro tro
/// drives in and parks by a campfire under a starry sky, framing the tale like
/// an Anansesɛm told at night.
class _StoryStopHeader extends StatefulWidget {
  const _StoryStopHeader();

  @override
  State<_StoryStopHeader> createState() => _StoryStopHeaderState();
}

class _StoryStopHeaderState extends State<_StoryStopHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..forward();
  }

  @override
  void dispose() {
    _c.dispose();
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
                      Color(0xFF241B3A),
                      Color(0xFF3D2A4D),
                      Color(0xFF7A3F36),
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
              child: Container(height: 42, color: const Color(0xFF2C1D24)),
            ),
            const Positioned(
              bottom: 12,
              right: 40,
              child: _Campfire(),
            ),
            // Celebratory mascot drives in and parks by the fire.
            AnimatedBuilder(
              animation: _c,
              builder: (_, child) {
                final t = Curves.easeOutCubic.transform(_c.value);
                final x = -160 + 260 * t;
                return Positioned(bottom: 16, left: x, child: child!);
              },
              child: Image.asset(
                'assets/mascot/stageclear/trotro_tada.png',
                width: 122,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const TintableTroTro(bodyColor: terracotta, width: 118),
              ),
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
