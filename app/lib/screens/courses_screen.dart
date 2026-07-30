import 'package:flutter/material.dart';
import '../data/lesson_catalog.dart';
import '../services/progress_service.dart';
import '../theme.dart';
import '../widgets/velvet.dart';
import '../widgets/floating_card.dart';
import 'lesson_quiz_screen.dart';
import 'upgrade_screen.dart';
import 'tools_hub_screen.dart' show velvetToolsTheme;

double _courseMastery(Course c, Progress p) {
  final lessons = c.lessons;
  if (lessons.isEmpty) return 0;
  final got = lessons.fold<int>(0, (a, l) => a + (p.best[l.id] ?? 0));
  return got / (lessons.length * 10);
}

int _passedCount(List<Lesson> lessons, Progress p) =>
    lessons.where((l) => p.passed(l.id)).length;

/// Structured Courses overview — named tracks that group categories.
class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final _service = ProgressService();
  Progress _p = Progress.empty;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final p = await _service.load();
    if (!mounted) return;
    setState(() {
      _p = p;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Courses',
              style: displayFont(
                  fontSize: 26, fontWeight: FontWeight.w800, color: kVelvetInk)),
          const SizedBox(height: 4),
          const Text('Structured tracks that take you from your first word to '
              'real conversation.',
              style: TextStyle(color: kVelvetMuted, fontSize: 13.5, height: 1.5)),
          const SizedBox(height: 16),
          for (final course in kCourses) ...[
            _CourseCard(
              course: course,
              p: _p,
              onOpen: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => CourseDetailScreen(course: course)));
                _reload();
              },
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;
  final Progress p;
  final VoidCallback onOpen;
  const _CourseCard(
      {required this.course, required this.p, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final lessons = course.lessons;
    final mastery = _courseMastery(course, p);
    final passed = _passedCount(lessons, p);
    final complete = passed == lessons.length && lessons.isNotEmpty;
    return FloatingCard(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A211C),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(course.icon, color: kVelvetInk, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(course.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  color: kVelvetInk)),
                        ),
                        if (course.premium) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3A92C).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFE3A92C)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.workspace_premium_rounded,
                                    size: 12, color: Color(0xFFE3A92C)),
                                SizedBox(width: 3),
                                Text('PREMIUM',
                                    style: TextStyle(
                                        color: Color(0xFFE3A92C),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 9.5,
                                        letterSpacing: 0.5)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text('$passed / ${lessons.length} lessons passed',
                        style: const TextStyle(color: kVelvetMuted, fontSize: 12.5)),
                  ],
                ),
              ),
              Text('${(mastery * 100).round()}%',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color:
                          complete ? const Color(0xFF2E6B3B) : kVelvetMuted)),
            ],
          ),
          const SizedBox(height: 8),
          Text(course.blurb,
              style: const TextStyle(color: kVelvetMuted, fontSize: 13)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: mastery.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0x1FFFFFFF),
              valueColor: AlwaysStoppedAnimation(
                  complete ? const Color(0xFF2E6B3B) : terracotta),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single course: its categories and lessons, in order.
class CourseDetailScreen extends StatefulWidget {
  final Course course;
  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final _service = ProgressService();
  Progress _p = Progress.empty;
  bool _premium = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final stats = await _service.loadStats();
    if (!mounted) return;
    setState(() {
      _p = stats.progress;
      _premium = stats.premium;
      _loading = false;
    });
  }

  Future<void> _openLesson(Lesson l) async {
    // Premium-gated course → free users go to the upgrade screen.
    if (lessonIsPremium(l.id) && !_premium) {
      await Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const UpgradeScreen()));
      _reload();
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LessonQuizScreen(lesson: l)),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    // Pushed as its own route, so it loses the Tools dark theme — re-apply it
    // here so the detail matches the rest of the dark hub.
    return Theme(
      data: velvetToolsTheme(context),
      child: Scaffold(
      appBar: AppBar(title: Text(course.name)),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _reload,
                child: Builder(builder: (context) {
                  // Unlock within THIS course only, so each course is an
                  // independent track: first lesson open, next unlocks on pass.
                  final courseLessons = course.lessons;
                  final unlocked = <String>{};
                  for (int i = 0; i < courseLessons.length; i++) {
                    if (i == 0 || _p.passed(courseLessons[i - 1].id)) {
                      unlocked.add(courseLessons[i].id);
                    }
                  }
                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(course.blurb,
                          style: const TextStyle(
                              color: kVelvetMuted, fontSize: 14, height: 1.5)),
                      const SizedBox(height: 16),
                      for (final cat in course.categories) ...[
                        _CategorySection(
                          category: cat,
                          p: _p,
                          isUnlocked: (id) => unlocked.contains(id),
                          onOpen: _openLesson,
                        ),
                        const SizedBox(height: 14),
                      ],
                    ],
                  );
                }),
              ),
      ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final LessonCategory category;
  final Progress p;
  final bool Function(String) isUnlocked;
  final ValueChanged<Lesson> onOpen;
  const _CategorySection(
      {required this.category,
      required this.p,
      required this.isUnlocked,
      required this.onOpen});

  @override
  Widget build(BuildContext context) {
    // Show unlocked lessons plus the next locked one as a preview.
    final visible = <Lesson>[];
    for (final l in category.lessons) {
      visible.add(l);
      if (!isUnlocked(l.id)) break;
    }
    return FloatingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (category.emoji.isNotEmpty)
                Text(category.emoji, style: const TextStyle(fontSize: 18))
              else
                Icon(category.icon, color: kVelvetInk, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(category.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: kVelvetInk)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final l in visible)
            _LessonRow(
              lesson: l,
              unlocked: isUnlocked(l.id),
              passed: p.passed(l.id),
              best: p.best[l.id] ?? 0,
              onOpen: () => onOpen(l),
            ),
        ],
      ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  final Lesson lesson;
  final bool unlocked;
  final bool passed;
  final int best;
  final VoidCallback onOpen;
  const _LessonRow({
    required this.lesson,
    required this.unlocked,
    required this.passed,
    required this.best,
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
      icon = Icons.play_circle_fill;
      iconColor = terracotta;
    } else {
      icon = Icons.lock_outline;
      iconColor = Colors.white30;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: const Color(0xFF211B17),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: unlocked ? onOpen : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x1FFFFFFF), width: 1.2),
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lesson.title,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: unlocked ? kVelvetInk : kVelvetMuted)),
                      Text(
                          passed
                              ? '${lesson.subtitle}  ·  best $best/10'
                              : unlocked
                                  ? lesson.subtitle
                                  : 'Locked — finish the previous lesson',
                          style: const TextStyle(color: kVelvetMuted, fontSize: 12)),
                    ],
                  ),
                ),
                if (unlocked)
                  const Icon(Icons.chevron_right, color: Colors.white30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
