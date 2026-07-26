import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/quiz_questions.dart';
import '../data/lesson_catalog.dart';
import '../data/lesson_content.dart';
import '../services/progress_service.dart';
import '../services/sound_service.dart';
import '../theme.dart';
import '../widgets/velvet.dart';
import '../widgets/continue_button.dart';
import '../widgets/floating_card.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<QuizQuestion> _bank = [];
  int _level = 1;
  bool _loading = true;

  List<QuizQuestion> _session = [];
  int _index = 0;
  int _score = 0;
  String? _selected;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final bank = <QuizQuestion>[...kQuizQuestions];
    for (final l in kLessonsFlat) {
      try {
        final u = await loadUnit(l.asset, category: l.categoryId);
        final catName =
            kCategories.firstWhere((c) => c.id == l.categoryId).name;
        for (final ch in u.challenges) {
          bank.add(QuizQuestion(
            category: catName,
            question: ch.prompt,
            options: ch.options,
            answer: ch.correctLabel,
            explanation: '',
          ));
        }
      } catch (_) {/* skip a unit that fails to load */}
    }
    int level = 1;
    try {
      level = (await ProgressService().load()).level;
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _bank = bank;
      _level = level;
      _loading = false;
      _newSession();
    });
  }

  void _newSession() {
    final r = Random();
    final pool = [..._bank]..shuffle(r);
    // Progressive: more questions as the learner levels up.
    final n = (4 + _level * 2).clamp(5, pool.length);
    _session = pool.take(n).map((q) => _shuffleOptions(q, r)).toList();
    _index = 0;
    _score = 0;
    _selected = null;
    _finished = false;
  }

  QuizQuestion _shuffleOptions(QuizQuestion q, Random r) {
    final opts = [...q.options]..shuffle(r);
    return QuizQuestion(
      category: q.category,
      question: q.question,
      options: opts,
      answer: q.answer,
      explanation: q.explanation,
    );
  }

  void _answer(String option) {
    if (_selected != null) return;
    final correct = option == _session[_index].answer;
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

  void _restart() => setState(_newSession); // fresh, shuffled set each time

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_finished) {
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
              const Text('A fresh mix awaits.',
                  style: TextStyle(fontSize: 13, color: kVelvetMuted)),
              const SizedBox(height: 20),
              FilledButton(
                  onPressed: _restart, child: const Text('New quiz')),
            ],
          ),
        ),
      );
    }

    final q = _session[_index];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Dynamic Quiz · ${q.category}',
                style: const TextStyle(
                    color: kVelvetMuted, fontWeight: FontWeight.w700, fontSize: 12)),
            Text('${_index + 1} / ${_session.length}',
                style: const TextStyle(color: Colors.black54, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        Text(q.question,
            style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 20, color: kVelvetInk)),
        const SizedBox(height: 16),
        ...q.options.map((opt) {
          Color border = Colors.white12;
          Color bg = const Color(0xFF211B17);
          if (_selected != null) {
            if (opt == q.answer) {
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
          if (q.explanation.isNotEmpty) ...[
            const SizedBox(height: 8),
            FloatingCard(
              child: Text(q.explanation,
                  style: const TextStyle(height: 1.4, color: kVelvetInk)),
            ),
          ],
          const SizedBox(height: 16),
          ContinueButton(onPressed: _next),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}
