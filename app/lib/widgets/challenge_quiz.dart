import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/lesson_content.dart';
import '../services/sound_service.dart';
import '../theme.dart';
import 'continue_button.dart';
import 'velvet.dart';

/// A reusable multiple-choice quiz runner over a list of [Challenge]s.
/// Used by Review Quizzes and Reading comprehension. Pure practice — it does
/// not write progress/XP, so it can be replayed freely.
class ChallengeQuiz extends StatefulWidget {
  final List<Challenge> challenges;
  final int maxQuestions;
  final String kicker; // small label above each question
  /// When true, the quiz ends with a pass/fail result: below [passThreshold]
  /// the learner is asked to try again; at or above it, [onPassed] fires and a
  /// "Continue" button appears. When false (default) it loops as free practice.
  final bool passMode;
  final double passThreshold; // fraction, 0..1
  final VoidCallback? onPassed;
  final String passButtonLabel;
  const ChallengeQuiz({
    super.key,
    required this.challenges,
    this.maxQuestions = 12,
    this.kicker = 'Review',
    this.passMode = false,
    this.passThreshold = 0.6,
    this.onPassed,
    this.passButtonLabel = 'Continue',
  });

  @override
  State<ChallengeQuiz> createState() => _ChallengeQuizState();
}

class _ChallengeQuizState extends State<ChallengeQuiz> {
  final _r = Random();
  List<Challenge> _session = [];
  int _index = 0;
  int _score = 0;
  String? _selected;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _newSession();
  }

  void _newSession() {
    final pool = [...widget.challenges]..shuffle(_r);
    final n = min(widget.maxQuestions, pool.length);
    _session =
        pool.take(n).map((c) => c.shuffledOptions(_r)).toList(growable: false);
    _index = 0;
    _score = 0;
    _selected = null;
    _finished = false;
  }

  void _answer(String option) {
    if (_selected != null) return;
    final correct = option == _session[_index].correctLabel;
    if (correct) {
      HapticFeedback.lightImpact();
      SoundService.instance.correct();
    } else {
      HapticFeedback.mediumImpact();
    }
    setState(() {
      _selected = option;
      if (correct) _score++;
    });
  }

  void _next() {
    if (_index < _session.length - 1) {
      setState(() {
        _index++;
        _selected = null;
      });
    } else {
      SoundService.instance.complete();
      setState(() => _finished = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_session.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Nothing to review yet — complete a lesson first.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kVelvetMuted, fontSize: 14),
          ),
        ),
      );
    }

    if (_finished) {
      final passed = _score / _session.length >= widget.passThreshold;
      final need = (_session.length * widget.passThreshold).ceil();

      if (widget.passMode) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(passed ? Icons.check_circle : Icons.refresh,
                    size: 52,
                    color:
                        passed ? const Color(0xFF2E6B3B) : terracotta),
                const SizedBox(height: 10),
                Text('$_score / ${_session.length}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 44,
                        color: kVelvetInk)),
                const SizedBox(height: 8),
                Text(passed ? 'Passed! Yɛ wo adɛn!' : 'Not quite yet',
                    style: const TextStyle(fontSize: 17, color: kVelvetInk)),
                const SizedBox(height: 4),
                Text(
                    passed
                        ? 'You’ve unlocked the next passage.'
                        : 'You need $need correct to pass. Give it another go —',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: kVelvetMuted)),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: passed
                      ? widget.onPassed
                      : () => setState(_newSession),
                  child: Text(passed ? widget.passButtonLabel : 'Try again'),
                ),
              ],
            ),
          ),
        );
      }

      // Free-practice mode (Review Quizzes): loop with a fresh mix.
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$_score / ${_session.length}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 44,
                      color: kVelvetInk)),
              const SizedBox(height: 8),
              const Text('Yɛ wo adɛn! (Well done!)',
                  style: TextStyle(fontSize: 16, color: kVelvetInk)),
              const SizedBox(height: 4),
              const Text('Practice makes it stick.',
                  style: TextStyle(fontSize: 13, color: kVelvetMuted)),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => setState(_newSession),
                child: const Text('Review again'),
              ),
            ],
          ),
        ),
      );
    }

    final c = _session[_index];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(widget.kicker,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: kVelvetMuted, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
            const SizedBox(width: 8),
            Text('${_index + 1} / ${_session.length}',
                style: const TextStyle(color: kVelvetMuted, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        Text(c.prompt,
            style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 20, color: kVelvetInk)),
        const SizedBox(height: 16),
        ...c.options.map((opt) {
          Color border = Colors.white12;
          Color bg = const Color(0xFF211B17);
          if (_selected != null) {
            if (opt == c.correctLabel) {
              border = const Color(0xFF63C583);
              bg = const Color(0xFF17281C);
            } else if (opt == _selected) {
              border = terracotta;
              bg = const Color(0xFF2C1D18);
            }
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _selected == null ? () => _answer(opt) : null,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: border, width: 1.5),
                  ),
                  child: Text(opt,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, color: kVelvetInk)),
                ),
              ),
            ),
          );
        }),
        if (_selected != null) ...[
          const SizedBox(height: 16),
          ContinueButton(onPressed: _next),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}
