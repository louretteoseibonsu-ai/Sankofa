import 'package:flutter/material.dart';
import '../data/lesson_catalog.dart';
import '../services/progress_service.dart';
import '../theme.dart';
import '../widgets/floating_card.dart';
import 'lesson_quiz_screen.dart';
import 'leaderboard_screen.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
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

  Future<void> _openLesson(Lesson l) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LessonQuizScreen(lesson: l)),
    );
    _reload(); // refresh XP / unlocks after returning
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Lessons',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 26, color: ink)),
              IconButton(
                tooltip: 'Leaderboard',
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const LeaderboardScreen())),
                icon: const Icon(Icons.emoji_events_outlined, color: charcoal),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _LevelCard(p: _p),
          const SizedBox(height: 22),
          const Text('Explore Interactive Twi Lessons',
              style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 18, color: ink)),
          const SizedBox(height: 6),
          const Text(
            'Akan / Twi uses beautiful semantic roots. Tap any of the curated '
            'categories below to study the phonetic guides, cultural context, '
            'and everyday usage patterns.',
            style: TextStyle(color: slate, fontSize: 13.5, height: 1.5),
          ),
          const SizedBox(height: 16),
          for (final c in kCategories) ...[
            _CategoryBlock(category: c, p: _p, onOpen: _openLesson),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final Progress p;
  const _LevelCard({required this.p});

  @override
  Widget build(BuildContext context) {
    final pct = p.xpIntoLevel / p.xpForNextLevel;
    return FloatingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: terracotta,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text('${p.level}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Level ${p.level}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: ink)),
                    Text('${p.totalXp} XP total',
                        style: const TextStyle(color: slate, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: silverLight,
              valueColor: const AlwaysStoppedAnimation(terracotta),
            ),
          ),
          const SizedBox(height: 6),
          Text('${p.xpIntoLevel} / ${p.xpForNextLevel} XP to level ${p.level + 1}',
              style: const TextStyle(color: slate, fontSize: 12)),
        ],
      ),
    );
  }
}

class _CategoryBlock extends StatelessWidget {
  final LessonCategory category;
  final Progress p;
  final ValueChanged<Lesson> onOpen;
  const _CategoryBlock(
      {required this.category, required this.p, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final mastery = p.categoryMastery(category);
    final masteredAll = mastery >= (kPassScore / 10);
    // Show every unlocked lesson plus only the next locked one as a preview.
    final visible = <Lesson>[];
    for (final l in category.lessons) {
      visible.add(l);
      if (!p.unlocked(l.id)) break;
    }
    final hidden = category.lessons.length - visible.length;
    return FloatingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(category.icon, color: charcoal, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(category.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: ink)),
              ),
              Text('${(mastery * 100).round()}%',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: masteredAll ? const Color(0xFF2E6B3B) : slate)),
            ],
          ),
          const SizedBox(height: 4),
          Text(category.blurb,
              style: const TextStyle(color: slate, fontSize: 13)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: mastery.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: silverLight,
              valueColor: AlwaysStoppedAnimation(
                  masteredAll ? const Color(0xFF2E6B3B) : charcoal),
            ),
          ),
          const SizedBox(height: 12),
          for (final l in visible)
            _LessonRow(
              lesson: l,
              unlocked: p.unlocked(l.id),
              best: p.best[l.id] ?? 0,
              passed: p.passed(l.id),
              onOpen: () => onOpen(l),
            ),
          if (hidden > 0)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, size: 15, color: silver),
                  const SizedBox(width: 6),
                  Text('$hidden more ${hidden == 1 ? 'lesson' : 'lessons'} to unlock',
                      style: const TextStyle(
                          color: slate,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
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
      iconColor = silver;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: unlocked ? onOpen : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: silverLight, width: 1.2),
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
                              color: unlocked ? ink : slate)),
                      Text(
                          passed
                              ? '${lesson.subtitle}  ·  best $best/10'
                              : unlocked
                                  ? lesson.subtitle
                                  : 'Locked — finish the previous lesson',
                          style: const TextStyle(color: slate, fontSize: 12)),
                    ],
                  ),
                ),
                if (unlocked)
                  const Icon(Icons.chevron_right, color: Colors.black26),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
