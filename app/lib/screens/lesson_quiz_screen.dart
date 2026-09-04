import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/avatar.dart';
import '../data/journey_state.dart';
import '../data/lesson_catalog.dart';
import '../data/lesson_content.dart';
import '../data/lesson_drills.dart';
import '../data/quiz_master.dart';
import '../data/twi_phonetics.dart';
import '../services/progress_service.dart';
import '../services/sound_service.dart';
import '../services/twi_speech.dart';
import '../theme.dart';
import '../widgets/alphabet_primer.dart';
import '../widgets/animations.dart';
import '../widgets/celebration.dart';
import '../widgets/checkpoint_travel.dart';
import '../widgets/continue_button.dart';
import '../widgets/floating_card.dart';
import '../widgets/floating_reward.dart';
import '../widgets/lesson_drill_views.dart';
import '../widgets/family_celebration.dart';
import '../widgets/kente_shard.dart';
import '../widgets/tappable_scale.dart';
import '../widgets/velvet.dart';
import 'tools_hub_screen.dart' show velvetToolsTheme;

const Color _correctGreen = Color(0xFF63C583);
const Color _wrongRed = Color(0xFFE0655A);

class LessonQuizScreen extends StatefulWidget {
  final Lesson lesson;
  const LessonQuizScreen({super.key, required this.lesson});

  @override
  State<LessonQuizScreen> createState() => _LessonQuizScreenState();
}

class _LessonQuizScreenState extends State<LessonQuizScreen> {
  final _progress = ProgressService();
  UnitContent? _unit;
  List<LessonDrill> _drills = [];
  final Map<int, int> _selected = {}; // MCQ picks, keyed by drill index
  final Map<int, String> _feedback = {}; // Quiz Master line (MCQ only)
  final Set<int> _answered = {}; // drills the learner has completed
  final Map<int, bool> _resultAt = {}; // per-drill correctness
  bool _recorded = false;

  int _combo = 0; // consecutive correct answers
  int _bestCombo = 0;
  int _keysEarned = 0; // 1 wisdom key per 3-in-a-row
  int _stars = 0; // stars earned on the finishing run (for the reward reveal)
  int _finalShards = 0; // shards earned on the finishing run
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
      _drills = buildLessonDrills(u, Random());
    });
  }

  int get _correct => _resultAt.values.where((v) => v).length;
  bool get _allDone =>
      _drills.isNotEmpty && _answered.length == _drills.length;

  /// Shared answer bookkeeping for every drill kind: records correctness,
  /// updates the combo/keys/flash, plays sound + haptics. Call inside setState.
  void _recordCore(int i, bool correct) {
    _answered.add(i);
    _resultAt[i] = correct;
    if (correct) {
      _combo += 1;
      if (_combo > _bestCombo) _bestCombo = _combo;
      // Every 3-in-a-row: a level-up flourish + a wisdom key + confetti.
      if (_combo % 3 == 0) {
        _keysEarned += 1;
        _flash = '🔥 ${_combo}x combo  ·  +1 🗝';
        HapticFeedback.heavyImpact();
        SoundService.instance.boxReveal();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) celebrateBurst(context);
        });
      } else {
        HapticFeedback.selectionClick();
        // Pitch climbs with the streak (combo 1 → base note, then up the scale).
        SoundService.instance.correct(step: _combo - 1);
        SoundService.instance.boxShakeTick(_combo.clamp(1, 6) / 6);
      }
    } else {
      _combo = 0; // broken
      HapticFeedback.heavyImpact();
      SoundService.instance.wrong();
    }
    if (_flash != null) {
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) setState(() => _flash = null);
      });
    }
  }

  void _answerMcq(int i, int opt) {
    if (_answered.contains(i)) return;
    final correct = opt == _drills[i].mcq!.correctIndex;
    setState(() {
      _selected[i] = opt;
      _feedback[i] = correct ? quizCheer() : quizNudge();
      _recordCore(i, correct);
    });
  }

  void _answerDrill(int i, bool correct) {
    if (_answered.contains(i)) return;
    setState(() => _recordCore(i, correct));
  }

  Widget _drillView(int i) {
    final d = _drills[i];
    switch (d.kind) {
      case DrillKind.mcq:
        return _ChallengeCard(
          key: ValueKey('mcq$i'),
          index: i,
          challenge: d.mcq!,
          selected: _selected[i],
          feedback: _feedback[i],
          onChoose: (opt) => _answerMcq(i, opt),
        );
      case DrillKind.match:
        return MatchDrillView(
            key: ValueKey('match$i'),
            data: d.match!,
            onAnswered: (c) => _answerDrill(i, c));
      case DrillKind.listen:
        return ListenDrillView(
            key: ValueKey('listen$i'),
            data: d.listen!,
            onAnswered: (c) => _answerDrill(i, c));
      case DrillKind.build:
        return BuildDrillView(
            key: ValueKey('build$i'),
            data: d.build!,
            onAnswered: (c) => _answerDrill(i, c));
    }
  }

  /// Advance to the next question, or finish the run (record + summary).
  void _next() {
    if (_i >= _drills.length - 1) {
      if (!_recorded) {
        _recorded = true;
        _finishRun();
      }
    } else {
      HapticFeedback.selectionClick();
      setState(() => _i += 1);
    }
  }

  /// Record the result, then — on a passing run — play the Stage Clear
  /// drive-across FIRST and only reveal the summary once the learner taps
  /// Continue. Awaiting the celebration (rather than firing it and jumping
  /// straight to the summary) is what guarantees the black stage actually
  /// shows; the old fire-and-forget lost the race with the summary and the
  /// widget was often unmounted before the overlay could appear.
  Future<void> _finishRun() async {
    RecordOutcome o;
    try {
      o = await _progress.recordResult(widget.lesson.id, _correct,
          keysEarned: _keysEarned);
    } catch (_) {
      // Saving failed (e.g. offline) — still show the summary so the learner
      // isn't stranded on the last question.
      if (mounted) setState(() => _done = true);
      return;
    }
    if (!mounted) return;

    _stars = o.stars;
    _finalShards = o.shardsEarned;
    final passed = _correct >= kPassScore;
    if (passed) {
      SoundService.instance.boxReveal(grand: o.stars >= 3); // level-up jingle
      Map<String, String> equipped = const {};
      try {
        equipped = (await _progress.loadCosmetics()).equipped;
      } catch (_) {
        // Cosmetics unavailable — celebrate with the default skin.
      }
      if (!mounted) return;
      await FamilyCelebration.play(
        context,
        avatar: avatarById(equipped['avatar']),
        stars: o.stars < 1 ? 1 : o.stars,
      );
      if (!mounted) return;

      // Region/Act clear → travel cinematic to the Act's landmark. Fires on
      // every boss clear (a re-clear replays it), not only when new stars land.
      final landmark = landmarkForActBoss(widget.lesson);
      if (landmark != null) {
        await CheckpointTravel.play(
          context,
          destination: landmark,
          avatar: avatarById(equipped['avatar']),
        );
        if (!mounted) return;
      }
    }

    // Reveal the summary + Mastery Report after the drive.
    setState(() => _done = true);

    // Float the shard gain over the summary.
    if (o.shardsEarned > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ShardGain.show(context, o.shardsEarned);
      });
    }

    // A level-up is a bigger, named milestone — show it after the summary.
    if (o.leveledUp) {
      celebrateMilestone(context,
          headline: 'Level up!', subline: 'You reached level ${o.level}');
    }
  }

  void _restart() {
    setState(() {
      _selected.clear();
      _answered.clear();
      _resultAt.clear();
      _recorded = false;
      _combo = 0;
      _bestCombo = 0;
      _keysEarned = 0;
      _stars = 0;
      _finalShards = 0;
      _flash = null;
      _feedback.clear();
      _i = 0;
      _done = false;
      if (_unit != null) _drills = buildLessonDrills(_unit!, Random());
    });
  }

  void _onContinue() {
    if (!_allDone) {
      final left = _drills.length - _answered.length;
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
    final answered = _answered.contains(_i);
    final last = _i >= _drills.length - 1;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: answered ? _next : null,
        child: Text(last ? 'Finish the lesson' : 'Kɔ so · Continue  →'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = _unit;
    final total = _drills.length;
    final progress = total == 0 ? 0.0 : _answered.length / total;
    return Theme(
      data: velvetToolsTheme(context),
      child: Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: const Color(0x1FFFFFFF),
            valueColor: const AlwaysStoppedAnimation(terracotta),
          ),
        ),
      ),
      bottomNavigationBar: u == null
          ? null
          : Container(
              decoration: const BoxDecoration(
                color: const Color(0xFF17130F),
                border: Border(top: BorderSide(color: const Color(0x1FFFFFFF), width: 1)),
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
                Text(u.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 22, color: kVelvetInk)),
                const SizedBox(height: 14),
                // ── Learn section (collapsible to reduce cognitive load) ──
                Row(
                  children: [
                    Text(
                        widget.lesson.categoryId == 'alphabet'
                            ? 'Learn the alphabet'
                            : 'Learn the words',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: kVelvetInk)),
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
                  // Alphabet lesson: teach the vowels/consonants/digraphs the
                  // quiz asks about, before the questions (they aren't vocab).
                  if (widget.lesson.categoryId == 'alphabet') ...[
                    const AlphabetPrimer(showIntro: true),
                    const SizedBox(height: 14),
                  ],
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
                            color: kVelvetInk)),
                    const SizedBox(width: 10),
                    if (_combo >= 2) _ComboChip(combo: _combo),
                    const Spacer(),
                    Text('${_done ? total : _i + 1} / ${_drills.length}',
                        style: const TextStyle(
                            color: kVelvetMuted,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ],
                ),
                if (_flash != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFE07A3E), Color(0xFFE3A92C)]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFFE3A92C).withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 5)),
                      ],
                    ),
                    child: Text(_flash!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Color(0xFF1A1206),
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5)),
                  ),
                ],
                const SizedBox(height: 12),
                if (!_done && _drills.isNotEmpty) _drillView(_i),
                const SizedBox(height: 8),
                if (_done) ...[
                  if (_correct >= kPassScore)
                    _RewardReveal(
                      stars: _stars,
                      xp: _correct * 10,
                      shards: _finalShards,
                      bestCombo: _bestCombo,
                    )
                  else
                    Center(
                      child: Text(
                          'You scored $_correct / ${_drills.length}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: kVelvetInk)),
                    ),
                  const SizedBox(height: 12),
                  Center(
                    child: Builder(builder: (_) {
                      final m = masteryTitleFor(_drills.isEmpty
                          ? 0
                          : _correct / _drills.length);
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
                                color: kVelvetMuted, fontSize: 12.5)),
                      ]);
                    }),
                  ),
                  if (_correct < kPassScore) ...[
                    const SizedBox(height: 6),
                    const Center(
                      child: Text(
                          'Score $kPassScore+ to unlock the next lesson.',
                          style: TextStyle(color: kVelvetMuted, fontSize: 12.5)),
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 8),
              ],
            ),
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
                  color: kVelvetMuted,
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
                        color: kVelvetInk)),
              ),
              _SpeakButton(text: u.headwordAudio ?? u.headword, size: 26),
            ],
          ),
          Row(
            children: [
              if (u.pronunciation.isNotEmpty &&
                  u.pronunciation != u.headword) ...[
                Text('/${u.pronunciation}/',
                    style: const TextStyle(color: kVelvetMuted, fontSize: 14)),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text('sounds like “${twiApproximate(u.headword)}”',
                    style: const TextStyle(
                        color: kVelvetMuted,
                        fontSize: 13,
                        fontStyle: FontStyle.italic)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(u.gloss, style: const TextStyle(height: 1.5, color: kVelvetInk)),
          if (u.cultureNote != null && u.cultureNote!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _ChaleTip(text: u.cultureNote!),
          ],
          if (keySounds.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Key Twi sounds',
                style: TextStyle(
                    color: kVelvetMuted, fontWeight: FontWeight.w700, fontSize: 12)),
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
                      color: const Color(0xFF2A211C),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${k.key}  →  ${k.value}',
                        style: const TextStyle(fontSize: 12.5, color: kVelvetInk)),
                  ),
              ],
            ),
          ],
          if (u.examples.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('In a sentence',
                style: TextStyle(
                    color: kVelvetMuted, fontWeight: FontWeight.w700, fontSize: 12)),
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
                              color: kVelvetInk)),
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
                  color: kVelvetMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.6)),
          const SizedBox(height: 8),
          Text(grammar['focus'] as String,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 16, color: kVelvetInk)),
          const SizedBox(height: 6),
          Text(grammar['explanation'] as String,
              style: const TextStyle(height: 1.5, color: kVelvetInk)),
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
                          color: const Color(0xFF2A211C),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(p,
                            style:
                                const TextStyle(fontSize: 13, color: kVelvetInk)),
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
                  color: kVelvetMuted,
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
                              color: kVelvetInk)),
                      Text(
                          '${glossary[i].en}  ·  “${twiApproximate(glossary[i].twi)}”',
                          style: const TextStyle(color: kVelvetMuted, fontSize: 12.5)),
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
    super.key,
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
                  backgroundColor: terracotta,
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
                          color: kVelvetInk)),
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
        color: const Color(0xFF2C1D18),
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
                    color: kVelvetInk, fontSize: 12.5, height: 1.4),
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

class _OptionTile extends StatefulWidget {
  final String label;
  final _OptState state;
  final VoidCallback? onTap;
  const _OptionTile({required this.label, required this.state, this.onTap});

  @override
  State<_OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<_OptionTile>
    with TickerProviderStateMixin {
  late final AnimationController _pop =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 340));
  late final AnimationController _shake =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 440));

  @override
  void didUpdateWidget(covariant _OptionTile old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state) {
      if (widget.state == _OptState.correct) _pop.forward(from: 0);
      if (widget.state == _OptState.wrong) _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color border = const Color(0x3DFFFFFF);
    Color bg = const Color(0xFF211B17);
    Color fg = kVelvetInk;
    Widget? trailing;
    List<BoxShadow>? glow;
    switch (widget.state) {
      case _OptState.idle:
        break;
      case _OptState.correct:
        border = _correctGreen;
        bg = const Color(0xFF17281C);
        fg = _correctGreen;
        trailing =
            const Icon(Icons.check_circle, color: _correctGreen, size: 20);
        glow = [
          BoxShadow(
              color: _correctGreen.withValues(alpha: 0.35),
              blurRadius: 18,
              spreadRadius: -4),
        ];
        break;
      case _OptState.wrong:
        border = _wrongRed;
        bg = const Color(0xFF2C1D18);
        fg = _wrongRed;
        trailing = const Icon(Icons.cancel, color: _wrongRed, size: 20);
        break;
      case _OptState.dimmed:
        border = const Color(0x1FFFFFFF);
        fg = kVelvetMuted;
        break;
    }
    final tile = Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 1.4),
        boxShadow: glow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(widget.label,
                style: TextStyle(
                    color: fg, fontWeight: FontWeight.w600, fontSize: 15)),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedBuilder(
        animation: Listenable.merge([_pop, _shake]),
        builder: (_, child) {
          final pop = 1 + 0.07 * sin(pi * _pop.value); // quick bump
          final dx = _shake.value > 0
              ? sin(_shake.value * pi * 8) * 7 * (1 - _shake.value)
              : 0.0;
          return Transform.translate(
            offset: Offset(dx, 0),
            child: Transform.scale(scale: pop, child: child),
          );
        },
        child: TappableScale(onTap: widget.onTap, child: tile),
      ),
    );
  }
}

/// A glowing, escalating combo chip — colour + glow intensify with the streak,
/// and it pulses each time the combo climbs.
class _ComboChip extends StatefulWidget {
  final int combo;
  const _ComboChip({required this.combo});

  @override
  State<_ComboChip> createState() => _ComboChipState();
}

class _ComboChipState extends State<_ComboChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 260));

  @override
  void initState() {
    super.initState();
    _pulse.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant _ComboChip old) {
    super.didUpdateWidget(old);
    if (widget.combo != old.combo) _pulse.forward(from: 0);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Color get _tier {
    if (widget.combo >= 6) return const Color(0xFFF4B646); // gold
    if (widget.combo >= 4) return const Color(0xFFF0A93E); // amber
    return const Color(0xFFE07A3E); // ember
  }

  @override
  Widget build(BuildContext context) {
    final c = _tier;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        final s = 1 + 0.18 * sin(pi * _pulse.value);
        return Transform.scale(
          scale: s,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c, width: 1.2),
              boxShadow: [
                BoxShadow(
                    color: c.withValues(alpha: 0.45),
                    blurRadius: 12,
                    spreadRadius: -2),
              ],
            ),
            child: Text('🔥 ${widget.combo}x',
                style: TextStyle(
                    color: c, fontWeight: FontWeight.w800, fontSize: 13)),
          ),
        );
      },
    );
  }
}

/// The arcade reward panel on a passing run — animated stars + XP/shard
/// count-ups in a glowing power-up card.
class _RewardReveal extends StatelessWidget {
  final int stars;
  final int xp;
  final int shards;
  final int bestCombo;
  const _RewardReveal({
    required this.stars,
    required this.xp,
    required this.shards,
    required this.bestCombo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment(0, -0.6),
          radius: 1.2,
          colors: [Color(0xFF2A211C), Color(0xFF17130F)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: const Color(0xFFE3A92C).withValues(alpha: 0.35),
            width: 1.2),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFE3A92C).withValues(alpha: 0.22),
              blurRadius: 22,
              spreadRadius: -6,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [for (int i = 0; i < 3; i++) _star(i < stars, i)],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _countChip(value: xp, suffix: 'XP', color: const Color(0xFFF4B646)),
              if (shards > 0) ...[
                const SizedBox(width: 10),
                _countChip(
                    value: shards,
                    glyph: const KenteShard(size: 15),
                    color: const Color(0xFFE3A92C)),
              ],
            ],
          ),
          if (bestCombo >= 3) ...[
            const SizedBox(height: 10),
            Text('Best combo  🔥 ${bestCombo}x',
                style: const TextStyle(
                    color: kVelvetMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5)),
          ],
        ],
      ),
    );
  }

  Widget _star(bool filled, int i) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 380 + i * 160),
      curve: Curves.elasticOut,
      builder: (_, v, __) => Transform.scale(
        scale: filled ? v : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
              filled ? Icons.star_rounded : Icons.star_border_rounded,
              color: filled ? const Color(0xFFF4B646) : Colors.white24,
              size: 46),
        ),
      ),
    );
  }

  Widget _countChip(
      {required int value, String? suffix, Widget? glyph, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: value.toDouble()),
            duration: const Duration(milliseconds: 750),
            curve: Curves.easeOut,
            builder: (_, v, __) => Text('+${v.round()}',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w800, fontSize: 16)),
          ),
          const SizedBox(width: 5),
          if (glyph != null)
            glyph
          else
            Text(suffix ?? '',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w800, fontSize: 13)),
        ],
      ),
    );
  }
}
