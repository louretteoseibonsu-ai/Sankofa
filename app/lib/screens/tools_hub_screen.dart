import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/velvet.dart';
import 'alphabet_screen.dart';
import 'courses_screen.dart';
import 'day_name_screen.dart';
import 'quiz_screen.dart';
import 'reading_screen.dart';
import 'review_quiz_screen.dart';
import 'leaderboard_screen.dart';
import 'symbols_screen.dart';

/// "Tools" tab — a hub for the secondary destinations that don't belong in the
/// daily learn → practice loop. Each opens as its own page with a back button.
class ToolsHubScreen extends StatelessWidget {
  const ToolsHubScreen({super.key});

  /// Body-only screens (no Scaffold of their own) get wrapped so they have an
  /// app bar + back button when pushed.
  void _openWrapped(BuildContext c, String title, Widget body) {
    Navigator.of(c).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: SafeArea(child: body),
      ),
    ));
  }

  void _openPage(BuildContext c, Widget page) {
    Navigator.of(c).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF17130F), Color(0xFF1E1A17)],
        ),
      ),
      child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _ToolRow(
          icon: Icons.school_outlined,
          title: 'Courses',
          subtitle: 'Structured tracks from basics to conversation',
          onTap: () => _openWrapped(context, 'Courses', const CoursesScreen()),
        ),
        _ToolRow(
          icon: Icons.abc,
          title: 'Twi Alphabet',
          subtitle: 'Vowels, sounds & digraphs — tap to hear',
          onTap: () =>
              _openWrapped(context, 'Twi Alphabet', const AlphabetScreen()),
        ),
        _ToolRow(
          icon: Icons.menu_book_outlined,
          title: 'Reading & Comprehension',
          subtitle: 'Read a passage, then answer questions',
          onTap: () => _openWrapped(
              context, 'Reading', const ReadingListScreen()),
        ),
        _ToolRow(
          icon: Icons.quiz_outlined,
          title: 'Review Quizzes',
          subtitle: 'Mixed practice from a course',
          onTap: () => _openWrapped(
              context, 'Review', const ReviewPickerScreen()),
        ),
        _ToolRow(
          icon: Icons.bolt_outlined,
          title: 'Quick Practice',
          subtitle: 'A fast mixed quiz',
          onTap: () => _openWrapped(context, 'Practice', const QuizScreen()),
        ),
        _ToolRow(
          icon: Icons.auto_awesome_outlined,
          title: 'Adinkra Symbols',
          subtitle: 'Meanings & wisdom of the glyphs',
          onTap: () => _openWrapped(context, 'Symbols', const SymbolsScreen()),
        ),
        _ToolRow(
          icon: Icons.calendar_today_outlined,
          title: 'Day Name',
          subtitle: 'Your Akan soul name (kra din)',
          onTap: () => _openWrapped(context, 'Day Name', const DayNameScreen()),
        ),
        _ToolRow(
          icon: Icons.emoji_events_outlined,
          title: 'Leaderboard',
          subtitle: 'League rankings this week',
          onTap: () => _openPage(context, const LeaderboardScreen()),
        ),
      ],
      ),
    );
  }
}

class _ToolRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ToolRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: const Color(0xFF211B17),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Colors.white10, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: kOchre.withValues(alpha: 0.08),
          highlightColor: kOchre.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                      color: Color(0x22D4A373), shape: BoxShape.circle),
                  child: Icon(icon, color: kOchre, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: displayFont(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: kVelvetInk)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(
                              color: kVelvetMuted, fontSize: 12.5)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
