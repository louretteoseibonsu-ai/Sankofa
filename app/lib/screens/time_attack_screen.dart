import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/lesson_catalog.dart';
import '../data/lesson_content.dart';
import '../data/quiz_master.dart';
import '../services/progress_service.dart';
import '../services/sound_service.dart';
import '../theme.dart';
import '../widgets/tappable_scale.dart';

const Color _green = Color(0xFF2E6B3B);
const Color _red = Color(0xFF9B2D2A);
const Color _terra = Color(0xFFBE5235);
const Color _gold = Color(0xFFE3A92C);

/// Time-Attack: each line has a countdown. Beat the clock to keep your combo
/// alive. Same content and scoring as a normal lesson — just faster and louder.
class TimeAttackScreen extends StatefulWidget {
  final Lesson lesson;

  /// Mastery Challenge: a shorter clock, and a perfect run earns a one-time
  /// mastery badge + bonus shards. Used to replay cleared stops.
  final bool mastery;

  const TimeAttackScreen(
      {super.key, required this.lesson, this.mastery = false});

  @override
  State<TimeAttackScreen> createState() => _TimeAttackScreenState();
}

class _TimeAttackScreenState extends State<TimeAttackScreen>
    with SingleTickerProviderStateMixin {
  Duration get _perQuestion => Duration(seconds: widget.mastery ? 6 : 8);
  final _progress = ProgressService();
  late final AnimationController _timer;

  UnitContent? _unit;
  List<Challenge> _challenges = [];
  int _i = 0;
  int? _picked; // null = unanswered; -1 = timed out; else option index
  bool _resolved = false;
  int _correct = 0;
  int _combo = 0;
  int _bestCombo = 0;
  int _keysEarned = 0;
  bool _done = false;
  bool _recorded = false;
  int _masteryAward = 0;
  bool _masteryPerfect = false;
  String? _feedback; // punchy per-line Quiz Master voice

  @override
  void initState() {
    super.initState();
    _timer = AnimationController(vsync: this, duration: _perQuestion)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && !_resolved) _onTimeout();
      });
    _load();
  }

  @override
  void dispose() {
    _timer.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final u = await loadUnit(widget.lesson.asset,
        category: widget.lesson.categoryId);
    if (!mounted) return;
    final r = Random();
    setState(() {
      _unit = u;
      _challenges = [for (final c in u.challenges) c.shuffledOptions(r)]
        ..shuffle(r);
    });
    _startQuestion();
  }

  void _startQuestion() {
    _resolved = false;
    _picked = null;
    _feedback = null;
    _timer.forward(from: 0);
    if (mounted) setState(() {});
  }

  void _onTimeout() {
    if (_resolved) return;
    _resolved = true;
    setState(() {
      _picked = -1;
      _combo = 0;
      _feedback = "Time's up — next stop!";
    });
    SoundService.instance.tap();
    HapticFeedback.heavyImpact();
    _scheduleAdvance(1100);
  }

  void _choose(int opt) {
    if (_resolved) return;
    _resolved = true;
    _timer.stop();
    final correct = opt == _challenges[_i].correctIndex;
    setState(() {
      _picked = opt;
      _feedback = correct ? quizCheer() : quizNudge();
      if (correct) {
        _correct += 1;
        _combo += 1;
        if (_combo > _bestCombo) _bestCombo = _combo;
        if (_combo % 3 == 0) {
          _keysEarned += 1;
          HapticFeedback.heavyImpact();
          SoundService.instance.complete();
        } else {
          HapticFeedback.selectionClick();
          SoundService.instance.correct();
        }
      } else {
        _combo = 0;
        HapticFeedback.heavyImpact();
        SoundService.instance.tap();
      }
    });
    _scheduleAdvance(900);
  }

  void _scheduleAdvance(int ms) {
    Future.delayed(Duration(milliseconds: ms), () {
      if (!mounted) return;
      if (_i >= _challenges.length - 1) {
        _finish();
      } else {
        setState(() => _i += 1);
        _startQuestion();
      }
    });
  }

  Future<void> _finish() async {
    _timer.stop();
    if (!_recorded) {
      _recorded = true;
      _progress.recordResult(widget.lesson.id, _correct,
          keysEarned: _keysEarned);
    }
    final perfect = _correct == _challenges.length;
    int award = 0;
    if (widget.mastery && perfect) {
      award = await _progress.markMastered(widget.lesson.id);
    }
    if (!mounted) return;
    setState(() {
      _done = true;
      _masteryPerfect = perfect;
      _masteryAward = award;
    });
  }

  void _restart() {
    final r = Random();
    setState(() {
      _i = 0;
      _correct = 0;
      _combo = 0;
      _bestCombo = 0;
      _keysEarned = 0;
      _done = false;
      _recorded = false;
      _masteryAward = 0;
      _masteryPerfect = false;
      if (_unit != null) {
        _challenges = [for (final c in _unit!.challenges) c.shuffledOptions(r)]
          ..shuffle(r);
      }
    });
    _startQuestion();
  }

  @override
  Widget build(BuildContext context) {
    final u = _unit;
    return Scaffold(
      appBar: AppBar(
          title: Text(
              '${widget.mastery ? 'Mastery' : 'Time-Attack'} · ${widget.lesson.title}')),
      body: u == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _done ? _result() : _battle(),
              ),
            ),
    );
  }

  Widget _battle() {
    final ch = _challenges[_i];
    final answered = _picked != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Countdown bar
        AnimatedBuilder(
          animation: _timer,
          builder: (context, _) {
            final left = (1 - _timer.value).clamp(0.0, 1.0);
            return ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: left,
                minHeight: 10,
                backgroundColor: silverLight,
                valueColor:
                    AlwaysStoppedAnimation(Color.lerp(_red, _green, left)!),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text('Line ${_i + 1} of ${_challenges.length}',
                style: const TextStyle(
                    color: slate, fontWeight: FontWeight.w700, fontSize: 13)),
            const Spacer(),
            if (_combo >= 2)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFFFBEEEA),
                    borderRadius: BorderRadius.circular(20)),
                child: Text('${_combo}x combo',
                    style: const TextStyle(
                        color: _terra,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
              ),
            const SizedBox(width: 8),
            Text('$_correct pts',
                style: const TextStyle(
                    color: ink, fontWeight: FontWeight.w800, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 18),
        Text(ch.prompt,
            style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 20, color: ink, height: 1.3)),
        const SizedBox(height: 18),
        Expanded(
          child: ListView(
            children: [
              for (int o = 0; o < ch.options.length; o++)
                _Option(
                  label: ch.options[o],
                  state: !answered
                      ? _OState.idle
                      : o == ch.correctIndex
                          ? _OState.correct
                          : o == _picked
                              ? _OState.wrong
                              : _OState.dimmed,
                  onTap: answered ? null : () => _choose(o),
                ),
            ],
          ),
        ),
        if (answered && _feedback != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _feedback!,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: _picked == ch.correctIndex ? _green : _terra),
            ),
          ),
      ],
    );
  }

  Widget _result() {
    final won = _correct >= kPassScore;
    final stars = _correct >= 10
        ? 3
        : _correct >= 8
            ? 2
            : won
                ? 1
                : 0;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.mastery ? Icons.workspace_premium_rounded : Icons.bolt_rounded,
              color: _gold, size: 64),
          const SizedBox(height: 12),
          if (widget.mastery) ...[
            Text(
                _masteryPerfect
                    ? (_masteryAward > 0 ? 'Mastered!' : 'Already mastered')
                    : 'Not yet mastered',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    color: _masteryPerfect ? _green : ink)),
            const SizedBox(height: 4),
            Text(
                _masteryPerfect
                    ? (_masteryAward > 0
                        ? '+$_masteryAward kente shards'
                        : 'You already mastered this stop.')
                    : 'A perfect run (${_challenges.length}/${_challenges.length}) masters this stop.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: slate, fontSize: 13)),
            const SizedBox(height: 12),
          ],
          Text('$_correct / ${_challenges.length}',
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 32, color: ink)),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < 3; i++)
                Icon(
                    i < stars
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: _gold,
                    size: 30),
            ],
          ),
          const SizedBox(height: 10),
          Text('Best combo: ${_bestCombo}x',
              style: const TextStyle(color: slate, fontSize: 14)),
          const SizedBox(height: 12),
          const Text('MASTERY REPORT',
              style: TextStyle(
                  color: slate,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1)),
          const SizedBox(height: 6),
          Builder(builder: (_) {
            final m = masteryTitleFor(
                _challenges.isEmpty ? 0 : _correct / _challenges.length);
            return Column(mainAxisSize: MainAxisSize.min, children: [
              Text(m.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: terracottaDeep)),
              const SizedBox(height: 2),
              Text(m.blurb,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: slate, fontSize: 13)),
            ]);
          }),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: charcoal,
                    side: const BorderSide(color: silverLight, width: 1.5),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Done',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _restart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: terracottaDeep,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Play again',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _OState { idle, correct, wrong, dimmed }

class _Option extends StatelessWidget {
  final String label;
  final _OState state;
  final VoidCallback? onTap;
  const _Option({required this.label, required this.state, this.onTap});

  @override
  Widget build(BuildContext context) {
    Color border = silver;
    Color bg = Colors.white;
    Color fg = ink;
    Widget? trailing;
    switch (state) {
      case _OState.idle:
        break;
      case _OState.correct:
        border = _green;
        bg = const Color(0xFFEAF3EC);
        fg = _green;
        trailing = const Icon(Icons.check_circle, color: _green, size: 20);
        break;
      case _OState.wrong:
        border = _red;
        bg = const Color(0xFFF7EAE9);
        fg = _red;
        trailing = const Icon(Icons.cancel, color: _red, size: 20);
        break;
      case _OState.dimmed:
        border = silverLight;
        fg = slate;
        break;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TappableScale(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 1.4),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        color: fg, fontWeight: FontWeight.w600, fontSize: 15)),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }
}
