import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/lesson_catalog.dart';
import '../data/lesson_content.dart';
import '../data/quiz_master.dart';
import '../data/twi_phonetics.dart';
import '../services/progress_service.dart';
import '../services/sound_service.dart';
import '../services/twi_speech.dart';
import '../theme.dart';
import '../widgets/animations.dart';
import '../widgets/celebration.dart';
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
  final Map<int, String> _feedback = {}; // punchy Quiz Master line per question
  bool _recorded = false;

  int _combo = 0; // consecutive correct answers
  int _bestCombo = 0;
  int _keysEarned = 0; // 1 wisdom key per 3-in-a-row
  String? _flash; // transient combo banner text
  bool _showLearn = true; // collapse the teach cards to focus on practice
  int _i = 0; // current question — one at a time, boss-battle style
  bool _done = false; // finished the run — show the summary + Mastery Report

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
    final correct = opt == _challenges[i].correctIndex;
    setState(() {
      _selected[i] = opt;
      _feedback[i] = correct ? quizCheer() : quizNudge();
      if (correct) {
        _combo += 1;
        if (_combo > _bestCombo) _bestCombo = _combo;
        // Every 3-in-a-row: a drum flourish + a wisdom key.
        if (_combo % 3 == 0) {
          _keysEarned += 1;
          _flash = '🔥 ${_combo}x combo  ·  +1 🗝';
          HapticFeedback.heavyImpact();
          SoundService.instance.complete();
        } else {
          HapticFeedback.selectionClick();
          SoundService.instance.correct();
        }
      } else {
        _combo = 0; // broken
        HapticFeedback.heavyImpact();
        SoundService.instance.tap();
      }
    });
    // Celebrate a combo milestone with a confetti burst.
    if (correct && _combo > 0 && _combo % 3 == 0) {
      celebrateBurst(context);
    }
    // Clear the flash banner shortly after.
    if (_flash != null) {
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) setState(() => _flash = null);
      });
    }
  }

  /// Advance to the next question, or finish the run (record + summary).
  void _next() {
    if (_i >= _challenges.length - 1) {
      if (!_recorded) {
        _recorded = true;
        _recordAndCelebrate();
      }
      setState(() => _done = true);
    } else {
      HapticFeedback.selectionClick();
      setState(() => _i += 1);
    }
  }

  Future<void> _recordAndCelebrate() async {
    final o = await _progress.recordResult(widget.lesson.id, _correct,
        keysEarned: _keysEarned);
    if (!mounted) return;
    if (o.leveledUp) {
      celebrateMilestone(context,
          headline: 'Level up!', subline: 'You reached level ${o.level}');
    } else if (o.starsGained > 0 && o.stars == 3) {
      celebrateMilestone(context,
          headline: 'Perfect — 3 stars!',
          subline: 'Mastered ${widget.lesson.title}');
    }
  }

  void _restart() {
    setState(() {
      _selected.clear();
      _recorded = false;
      _combo = 0;
      _bestCombo = 0;
      _keysEarned = 0;
      _flash = null;
      _feedback.clear();
      _i = 0;
      _done = false;
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
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

  /// The sticky bottom action adapts to state: a failed-but-finished quiz shows
  /// a primary "Try again" (no more dead-end Continue that just shows a toast).
  Widget _bottomCta() {
    // Finished the run — continue to the next lesson, or retry if under pass.
    if (_done) {
      if (_correct < kPassScore) {
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              SoundService.instance.tap();
              _restart();
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Try again'),
          ),
        );
      }
      return ContinueButton(onPressed: _onContinue);
    }
    // Mid-run — advance once the current question is answered.
    final answered = _selected.containsKey(_i);
    final last = _i >= _challenges.length - 1;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: answered ? _next : null,
        child: Text(last ? 'Finish the lesson' : 'Drive on  →'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = _unit;
    final total = _challenges.length;
    final progress = total == 0 ? 0.0 : _selected.length / total;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: silverLight,
            valueColor: const AlwaysStoppedAnimation(terracotta),
          ),
        ),
      ),
      bottomNavigationBar: u == null
          ? null
          : Container(
              decoration: const BoxDecoration(
                color: canvas,
                border: Border(top: BorderSide(color: silverLight, width: 1)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: _bottomCta(),
                ),
              ),
            ),
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
                // ── Learn section (collapsible to reduce cognitive load) ──
                Row(
                  children: [
                    const Text('Learn the words',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: ink)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _showLearn = !_showLearn),
                      icon: Icon(
                          _showLearn ? Icons.expand_less : Icons.expand_more,
                          size: 18),
                      label: Text(_showLearn ? 'Hide' : 'Show'),
                    ),
                  ],
                ),
                if (_showLearn) ...[
                  const SizedBox(height: 4),
                  Reveal(child: _VocabCard(u: u)),
                  if (u.glossary.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _GlossaryCard(glossary: u.glossary),
                  ],
                  if (u.grammar != null) ...[
                    const SizedBox(height: 14),
                    _GrammarCard(grammar: u.grammar!),
                  ],
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text('Practice',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: ink)),
                    const SizedBox(width: 10),
                    if (_combo >= 2)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                            color: const Color(0xFFFBEEEA),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text('🔥 ${_combo}x',
                            style: const TextStyle(
                                color: terracotta,
                                fontWeight: FontWeight.w800,
                                fontSize: 13)),
                      ),
                    const Spacer(),
                    Text('${_done ? total : _i + 1} / ${_challenges.length}',
                        style: const TextStyle(
                            color: slate,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ],
                ),
                if (_flash != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                        color: const Color(0xFF2B2B2D),
                        borderRadius: BorderRadius.circular(14)),
                    child: Text(_flash!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Color(0xFFE3A92C),
                            fontWeight: FontWeight.w800,
                            fontSize: 14)),
                  ),
                ],
                const SizedBox(height: 12),
                if (!_done && _challenges.isNotEmpty)
                  _ChallengeCard(
                    index: _i,
                    challenge: _challenges[_i],
                    selected: _selected[_i],
                    feedback: _feedback[_i],
                    onChoose: (opt) => _choose(_i, opt),
                  ),
                const SizedBox(height: 8),
                if (_done) ...[
                  Center(
                    child: Text(
                        'You scored $_correct / ${_challenges.length}'
                        '${_correct >= kPassScore ? '  ·  +${_correct * 10} XP' : ''}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: ink)),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Builder(builder: (_) {
                      final m = masteryTitleFor(_challenges.isEmpty
                          ? 0
                          : _correct / _challenges.length);
                      return Column(children: [
                        Text(m.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                color: terracottaDeep)),
                        const SizedBox(height: 2),
                        Text(m.blurb,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: slate, fontSize: 12.5)),
                      ]);
                    }),
                  ),
                  if (_correct < kPassScore) ...[
                    const SizedBox(height: 6),
                    const Center(
                      child: Text(
                          'Score $kPassScore+ to unlock the next lesson.',
                          style: TextStyle(color: slate, fontSize: 12.5)),
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 8),
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
              _SpeakButton(text: u.headwordAudio ?? u.headword, size: 26),
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
          if (u.cultureNote != null && u.cultureNote!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _ChaleTip(text: u.cultureNote!),
          ],
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
    // Guarantee a ≥48dp tap target around the icon (pronunciation is a primary
    // learning action and must be easy to hit).
    return SizedBox(
      width: 48,
      height: 48,
      child: InkResponse(
        onTap: _busy ? null : _go,
        radius: 26,
        child: Center(
          child: _busy
              ? SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: const CircularProgressIndicator(strokeWidth: 2))
              : Icon(Icons.volume_up_rounded,
                  size: widget.size, color: terracotta),
        ),
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
          const Text('BASIC GRAMMAR',
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

class _GlossaryCard extends StatelessWidget {
  final List<GlossEntry> glossary;
  const _GlossaryCard({required this.glossary});

  @override
  Widget build(BuildContext context) {
    return FloatingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('WORDS & PRONUNCIATION',
              style: TextStyle(
                  color: slate,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.6)),
          const SizedBox(height: 4),
          for (int i = 0; i < glossary.length; i++) ...[
            if (i > 0) const Divider(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(glossary[i].twi,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: ink)),
                      Text(
                          '${glossary[i].en}  ·  “${twiApproximate(glossary[i].twi)}”',
                          style: const TextStyle(color: slate, fontSize: 12.5)),
                    ],
                  ),
                ),
                _SpeakButton(text: glossary[i].audio ?? glossary[i].twi, size: 22),
              ],
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
  final String? feedback;
  final ValueChanged<int> onChoose;
  const _ChallengeCard({
    required this.index,
    required this.challenge,
    required this.selected,
    required this.feedback,
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
            if (answered && feedback != null) ...[
              const SizedBox(height: 8),
              Text(feedback!,
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color:
                          selected == correctIndex ? _correctGreen : terracotta)),
            ],
            if (answered &&
                challenge.slangHint != null &&
                challenge.slangHint!.isNotEmpty) ...[
              const SizedBox(height: 4),
              _ChaleTip(text: challenge.slangHint!),
            ],
          ],
        ),
      ),
    );
  }
}

/// A small terracotta "Chale tip" callout for modern slang / cultural context.
class _ChaleTip extends StatelessWidget {
  final String text;
  const _ChaleTip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFBEEEA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🗣', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                    color: ink, fontSize: 12.5, height: 1.4),
                children: [
                  const TextSpan(
                      text: 'Chale tip:  ',
                      style: TextStyle(
                          color: terracotta, fontWeight: FontWeight.w800)),
                  TextSpan(text: text),
                ],
              ),
            ),
          ),
        ],
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
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
