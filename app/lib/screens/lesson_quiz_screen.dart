import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/lesson_catalog.dart';
import '../data/lesson_content.dart';
import '../data/twi_phonetics.dart';
import '../services/progress_service.dart';
import '../services/sound_service.dart';
import '../services/twi_speech.dart';
import '../theme.dart';
import '../widgets/continue_button.dart';
import '../widgets/floating_card.dart';

const Color _correctGreen = Color(0xFF2E6B3B);
const Color _wrongRed = Color(0xFF9B2D2A);

class LessonQuizScreen extends StatefulWidget {
  final Lesson lesson;
  const LessonQuizScreen({super.key, required this.lesson});

  @override
  State<LessonQuizScreen> createState() => _LessonQuizScreenState();
}

class _LessonQuizScreenState extends State<LessonQuizScreen> {
  final _progress = ProgressService();
  UnitContent? _unit;
  List<Challenge> _challenges = [];
  final Map<int, int> _selected = {};
  bool _recorded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = await loadUnit(widget.lesson.asset,
        category: widget.lesson.categoryId);
    if (!mounted) return;
    setState(() {
      _unit = u;
      _challenges = _shuffle(u.challenges);
    });
  }

  List<Challenge> _shuffle(List<Challenge> source) {
    final r = Random();
    final list = [for (final c in source) c.shuffledOptions(r)]..shuffle(r);
    return list;
  }

  int get _correct => _selected.entries
      .where((e) => e.value == _challenges[e.key].correctIndex)
      .length;
  bool get _allDone =>
      _challenges.isNotEmpty && _selected.length == _challenges.length;

  void _choose(int i, int opt) {
    if (_selected.containsKey(i)) return;
    setState(() => _selected[i] = opt);
    if (opt == _challenges[i].correctIndex) {
      HapticFeedback.selectionClick();
      SoundService.instance.correct();
    } else {
      HapticFeedback.heavyImpact();
      SoundService.instance.tap();
    }
    if (_allDone && !_recorded) {
      _recorded = true;
      _progress.recordResult(widget.lesson.id, _correct);
    }
  }

  void _restart() {
    setState(() {
      _selected.clear();
      _recorded = false;
      if (_unit != null) _challenges = _shuffle(_unit!.challenges);
    });
  }

  void _onContinue() {
    if (!_allDone) {
      final left = _challenges.length - _selected.length;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Answer all questions to finish ($left left).')));
      return;
    }
    SoundService.instance.complete();
    final passed = _correct >= kPassScore;
    final next = nextLessonAfter(widget.lesson.id);
    if (!passed) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Score $kPassScore+ to unlock the next lesson — try again!')));
      return;
    }
    if (next != null) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => LessonQuizScreen(lesson: next)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('You finished every lesson — Ayɛɛ! 🎉')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = _unit;
    return Scaffold(
      appBar: AppBar(title: Text(widget.lesson.title)),
      body: u == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (u.reviewRequired)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text('Draft content — pending language review',
                        style: TextStyle(color: slate, fontSize: 11.5)),
                  ),
                Text(u.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 22, color: ink)),
                const SizedBox(height: 14),
                _VocabCard(u: u),
                if (u.grammar != null) ...[
                  const SizedBox(height: 14),
                  _GrammarCard(grammar: u.grammar!),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Challenges',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: ink)),
                    Text('${_selected.length} / ${_challenges.length}',
                        style: const TextStyle(
                            color: slate,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 12),
                for (int i = 0; i < _challenges.length; i++)
                  _ChallengeCard(
                    index: i,
                    challenge: _challenges[i],
                    selected: _selected[i],
                    onChoose: (opt) => _choose(i, opt),
                  ),
                const SizedBox(height: 8),
                if (_allDone) ...[
                  Center(
                    child: Text(
                        'You scored $_correct / ${_challenges.length}'
                        '${_correct >= kPassScore ? '  ·  +${_correct * 10} XP' : ''}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: ink)),
                  ),
                  const SizedBox(height: 12),
                  if (_correct < kPassScore)
                    OutlinedButton(
                        onPressed: _restart,
                        child: const Text('Try again')),
                  const SizedBox(height: 8),
                ],
                ContinueButton(onPressed: _onContinue),
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}

class _VocabCard extends StatelessWidget {
  final UnitContent u;
  const _VocabCard({required this.u});

  @override
  Widget build(BuildContext context) {
    final keySounds =
        twiKeySounds('${u.headword} ${u.examples.join(' ')}');
    return FloatingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('VOCABULARY SPOTLIGHT',
              style: TextStyle(
                  color: slate,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.6)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(u.headword,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                        color: ink)),
              ),
              _SpeakButton(text: u.headword, size: 26),
            ],
          ),
          Row(
            children: [
              if (u.pronunciation.isNotEmpty &&
                  u.pronunciation != u.headword) ...[
                Text('/${u.pronunciation}/',
                    style: const TextStyle(color: slate, fontSize: 14)),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text('sounds like “${twiApproximate(u.headword)}”',
                    style: const TextStyle(
                        color: slate,
                        fontSize: 13,
                        fontStyle: FontStyle.italic)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(u.gloss, style: const TextStyle(height: 1.5, color: ink)),
          if (keySounds.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Key Twi sounds',
                style: TextStyle(
                    color: slate, fontWeight: FontWeight.w700, fontSize: 12)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final k in keySounds)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: glyphTile,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${k.key}  →  ${k.value}',
                        style: const TextStyle(fontSize: 12.5, color: ink)),
                  ),
              ],
            ),
          ],
          if (u.examples.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('In a sentence',
                style: TextStyle(
                    color: slate, fontWeight: FontWeight.w700, fontSize: 12)),
            const SizedBox(height: 4),
            for (final s in u.examples)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('•  $s',
                          style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                              color: ink)),
                    ),
                    _SpeakButton(text: s, size: 18),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SpeakButton extends StatefulWidget {
  final String text;
  final double size;
  const _SpeakButton({required this.text, this.size = 20});

  @override
  State<_SpeakButton> createState() => _SpeakButtonState();
}

class _SpeakButtonState extends State<_SpeakButton> {
  bool _busy = false;

  Future<void> _go() async {
    setState(() => _busy = true);
    final ok = await TwiSpeech.instance.speak(widget.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Could not load Twi audio — the server may be waking up. Try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: _busy ? null : _go,
      radius: 22,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: _busy
            ? SizedBox(
                width: widget.size,
                height: widget.size,
                child: const CircularProgressIndicator(strokeWidth: 2))
            : Icon(Icons.volume_up_rounded,
                size: widget.size, color: terracotta),
      ),
    );
  }
}

class _GrammarCard extends StatelessWidget {
  final Map<String, dynamic> grammar;
  const _GrammarCard({required this.grammar});

  @override
  Widget build(BuildContext context) {
    return FloatingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('GRAMMAR',
              style: TextStyle(
                  color: slate,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.6)),
          const SizedBox(height: 8),
          Text(grammar['focus'] as String,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 16, color: ink)),
          const SizedBox(height: 6),
          Text(grammar['explanation'] as String,
              style: const TextStyle(height: 1.5, color: ink)),
          if (grammar['patterns'] is List) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (grammar['patterns'] as List)
                  .cast<String>()
                  .map((p) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: glyphTile,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(p,
                            style:
                                const TextStyle(fontSize: 13, color: ink)),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final int index;
  final Challenge challenge;
  final int? selected;
  final ValueChanged<int> onChoose;
  const _ChallengeCard({
    required this.index,
    required this.challenge,
    required this.selected,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    final options = challenge.options;
    final correctIndex = challenge.correctIndex;
    final answered = selected != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FloatingCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: charcoal,
                  child: Text('${index + 1}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(challenge.prompt,
                      style: const TextStyle(
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                          color: ink)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (int o = 0; o < options.length; o++)
              _OptionTile(
                label: options[o],
                state: !answered
                    ? _OptState.idle
                    : o == correctIndex
                        ? _OptState.correct
                        : o == selected
                            ? _OptState.wrong
                            : _OptState.dimmed,
                onTap: answered ? null : () => onChoose(o),
              ),
          ],
        ),
      ),
    );
  }
}

enum _OptState { idle, correct, wrong, dimmed }

class _OptionTile extends StatelessWidget {
  final String label;
  final _OptState state;
  final VoidCallback? onTap;
  const _OptionTile({required this.label, required this.state, this.onTap});

  @override
  Widget build(BuildContext context) {
    Color border = silver;
    Color bg = Colors.white;
    Color fg = ink;
    Widget? trailing;
    switch (state) {
      case _OptState.idle:
        break;
      case _OptState.correct:
        border = _correctGreen;
        bg = const Color(0xFFEAF3EC);
        fg = _correctGreen;
        trailing =
            const Icon(Icons.check_circle, color: _correctGreen, size: 20);
        break;
      case _OptState.wrong:
        border = _wrongRed;
        bg = const Color(0xFFF7EAE9);
        fg = _wrongRed;
        trailing = const Icon(Icons.cancel, color: _wrongRed, size: 20);
        break;
      case _OptState.dimmed:
        border = silverLight;
        fg = slate;
        break;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
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
      ),
    );
  }
}
