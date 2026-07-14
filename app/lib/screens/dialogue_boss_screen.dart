import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/lesson_catalog.dart';
import '../data/lesson_content.dart';
import '../data/quiz_master.dart';
import '../services/progress_service.dart';
import '../services/sound_service.dart';
import '../theme.dart';
import '../widgets/celebration.dart';
import '../widgets/composable_trotro.dart';
import '../widgets/tappable_scale.dart';

const Color _green = Color(0xFF2E6B3B);
const Color _red = Color(0xFF9B2D2A);
const Color _terra = Color(0xFFBE5235);
const Color _gold = Color(0xFFE3A92C);

/// A "Dialogue Boss Battle": the region's boss speaks a Twi line and you must
/// choose the right response. Every correct answer drives the tro tro further
/// down the road; clear enough of them to defeat the boss and open the next
/// region. Same content and scoring as a normal lesson — just a game frame.
class DialogueBossScreen extends StatefulWidget {
  final Lesson lesson;
  const DialogueBossScreen({super.key, required this.lesson});

  @override
  State<DialogueBossScreen> createState() => _DialogueBossScreenState();
}

class _DialogueBossScreenState extends State<DialogueBossScreen> {
  final _progress = ProgressService();
  UnitContent? _unit;
  List<Challenge> _challenges = [];
  TroTroSkin _skin = const TroTroSkin();

  int _i = 0;
  int? _picked;
  int _correct = 0;
  int _combo = 0;
  int _bestCombo = 0;
  int _keysEarned = 0;
  bool _done = false;
  bool _recorded = false;
  String? _feedback; // punchy per-answer line from the Quiz Master

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = await loadUnit(widget.lesson.asset,
        category: widget.lesson.categoryId);
    final cos = await _progress.loadCosmetics();
    if (!mounted) return;
    final r = Random();
    setState(() {
      _unit = u;
      _challenges = [for (final c in u.challenges) c.shuffledOptions(r)]
        ..shuffle(r);
      _skin = TroTroSkin.fromEquipped(cos.equipped);
    });
  }

  double get _troPos =>
      _challenges.isEmpty ? 0 : _correct / _challenges.length;

  void _choose(int opt) {
    if (_picked != null) return;
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
  }

  void _next() {
    if (_i >= _challenges.length - 1) {
      setState(() => _done = true);
      _recordAndCelebrate();
    } else {
      setState(() {
        _i += 1;
        _picked = null;
        _feedback = null;
      });
    }
  }

  Future<void> _recordAndCelebrate() async {
    if (_recorded) return;
    _recorded = true;
    final o = await _progress.recordResult(widget.lesson.id, _correct,
        keysEarned: _keysEarned);
    if (!mounted) return;
    if (_correct >= kPassScore) {
      celebrateMilestone(context,
          headline: 'Boss defeated!',
          subline: o.leveledUp ? 'Level ${o.level} reached' : 'Region cleared');
    }
  }

  void _restart() {
    final r = Random();
    setState(() {
      _i = 0;
      _picked = null;
      _correct = 0;
      _combo = 0;
      _bestCombo = 0;
      _keysEarned = 0;
      _done = false;
      _recorded = false;
      _feedback = null;
      if (_unit != null) {
        _challenges = [for (final c in _unit!.challenges) c.shuffledOptions(r)]
          ..shuffle(r);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final u = _unit;
    return Scaffold(
      appBar: AppBar(title: Text('Boss · ${widget.lesson.title}')),
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

  Widget _track() {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      const troW = 74.0;
      return SizedBox(
        height: 76,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 52,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                    color: _terra, borderRadius: BorderRadius.circular(3)),
              ),
            ),
            Positioned(
              right: 0,
              top: 24,
              child: Icon(Icons.account_balance_rounded,
                  color: _done && _correct >= kPassScore ? _green : _terra,
                  size: 40),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              left: (w - troW - 44) * _troPos,
              top: 10,
              child: ComposableTroTro(skin: _skin, width: troW),
            ),
          ],
        ),
      );
    });
  }

  Widget _battle() {
    final ch = _challenges[_i];
    final answered = _picked != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _track(),
        const SizedBox(height: 8),
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
          ],
        ),
        const SizedBox(height: 14),
        // Boss speech bubble
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundColor: charcoal,
              child: Icon(Icons.person, color: _gold, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: glyphTile,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                ),
                child: Text(ch.prompt,
                    style: const TextStyle(
                        color: ink, fontSize: 15, height: 1.35)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Your response',
            style: TextStyle(color: slate, fontSize: 12.5)),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            children: [
              for (int o = 0; o < ch.options.length; o++)
                _Response(
                  label: ch.options[o],
                  state: !answered
                      ? _RState.idle
                      : o == ch.correctIndex
                          ? _RState.correct
                          : o == _picked
                              ? _RState.wrong
                              : _RState.dimmed,
                  onTap: answered ? null : () => _choose(o),
                ),
            ],
          ),
        ),
        if (answered && _feedback != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              _feedback!,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: _picked == ch.correctIndex ? _green : _terra),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: answered ? _next : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: terracottaDeep,
              foregroundColor: Colors.white,
              disabledBackgroundColor: silverLight,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
                _i >= _challenges.length - 1 ? 'Finish the battle' : 'Drive on',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 16)),
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
          ComposableTroTro(skin: _skin, width: 220),
          const SizedBox(height: 18),
          Text(won ? 'Boss defeated!' : 'The road is still blocked',
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 24, color: ink)),
          const SizedBox(height: 8),
          if (won)
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
          Text(
            won
                ? 'You scored $_correct/${_challenges.length}. The next region is open — Ayɛɛ!'
                : 'You scored $_correct/${_challenges.length}. Answer $kPassScore+ correctly to clear the boss.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: slate, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 14),
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
            return Column(children: [
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (won) {
                  Navigator.of(context).pop();
                } else {
                  _restart();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: won ? _green : terracottaDeep,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(won ? 'Continue the journey' : 'Try the boss again',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

enum _RState { idle, correct, wrong, dimmed }

class _Response extends StatelessWidget {
  final String label;
  final _RState state;
  final VoidCallback? onTap;
  const _Response({required this.label, required this.state, this.onTap});

  @override
  Widget build(BuildContext context) {
    Color border = silver;
    Color bg = Colors.white;
    Color fg = ink;
    Widget? trailing;
    switch (state) {
      case _RState.idle:
        break;
      case _RState.correct:
        border = _green;
        bg = const Color(0xFFEAF3EC);
        fg = _green;
        trailing = const Icon(Icons.check_circle, color: _green, size: 20);
        break;
      case _RState.wrong:
        border = _red;
        bg = const Color(0xFFF7EAE9);
        fg = _red;
        trailing = const Icon(Icons.cancel, color: _red, size: 20);
        break;
      case _RState.dimmed:
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
                          color: fg,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
        ),
    );
  }
}
