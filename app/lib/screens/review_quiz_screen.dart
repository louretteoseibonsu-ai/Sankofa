import 'package:flutter/material.dart';
import '../data/lesson_catalog.dart';
import '../data/lesson_content.dart';
import '../theme.dart';
import '../widgets/velvet.dart';
import '../widgets/challenge_quiz.dart';
import '../widgets/floating_card.dart';

/// Pick what to review — a whole course, or everything.
class ReviewPickerScreen extends StatelessWidget {
  const ReviewPickerScreen({super.key});

  void _open(BuildContext c, List<Lesson> lessons, String title) {
    Navigator.of(c).push(MaterialPageRoute(
        builder: (_) => ReviewQuizScreen(lessons: lessons, title: title)));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Review Quizzes',
            style: displayFont(fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Mixed practice from the lessons you’ve studied. '
            'No pressure — this doesn’t affect your XP.',
            style: TextStyle(color: kVelvetMuted, fontSize: 13.5, height: 1.5)),
        const SizedBox(height: 16),
        _PickRow(
          icon: Icons.shuffle,
          title: 'All courses',
          subtitle: 'A fresh mix from everything',
          onTap: () => _open(context, kLessonsFlat, 'All courses'),
        ),
        const SizedBox(height: 4),
        for (final course in kCourses)
          _PickRow(
            icon: course.icon,
            title: course.name,
            subtitle: '${course.lessons.length} lessons',
            onTap: () => _open(context, course.lessons, course.name),
          ),
      ],
    );
  }
}

class _PickRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _PickRow(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FloatingCard(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: kVelvetInk, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: kVelvetInk)),
                  Text(subtitle,
                      style: const TextStyle(color: kVelvetMuted, fontSize: 12.5)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}

/// Loads challenges from the chosen lessons and runs a practice quiz.
class ReviewQuizScreen extends StatefulWidget {
  final List<Lesson> lessons;
  final String title;
  const ReviewQuizScreen(
      {super.key, required this.lessons, required this.title});

  @override
  State<ReviewQuizScreen> createState() => _ReviewQuizScreenState();
}

class _ReviewQuizScreenState extends State<ReviewQuizScreen> {
  late final Future<List<Challenge>> _future = _loadChallenges();

  Future<List<Challenge>> _loadChallenges() async {
    final all = <Challenge>[];
    for (final l in widget.lessons) {
      try {
        final u = await loadUnit(l.asset, category: l.categoryId);
        all.addAll(u.challenges);
      } catch (_) {/* skip a unit that fails to load */}
    }
    return all;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Review · ${widget.title}')),
      body: SafeArea(
        child: FutureBuilder<List<Challenge>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final challenges = snap.data ?? const <Challenge>[];
            return ChallengeQuiz(
              challenges: challenges,
              kicker: 'Review · ${widget.title}',
            );
          },
        ),
      ),
    );
  }
}
