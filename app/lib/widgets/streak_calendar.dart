import 'package:flutter/material.dart';
import '../theme.dart';
import 'velvet.dart';
import 'tappable_scale.dart';

String _dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

const List<String> _wd = ['M', 'T', 'W', 'T', 'F', 'S', 'S']; // Mon..Sun

/// A 7-day streak calendar: ✅ practised · ❄ frozen · ✗ missed. When a recent
/// miss is repairable and the learner has a freeze, offers to plug it.
class StreakCalendar extends StatelessWidget {
  final Set<String> activeDays;
  final Set<String> frozenDays;
  final int streak;
  final int freezes;
  final int repairableStreak; // >0 when a recent miss can be plugged
  final VoidCallback onUseFreeze;
  const StreakCalendar({
    super.key,
    required this.activeDays,
    required this.frozenDays,
    required this.streak,
    required this.freezes,
    required this.repairableStreak,
    required this.onUseFreeze,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = _dayKey(now);
    final days = [for (int i = 6; i >= 0; i--) now.subtract(Duration(days: i))];
    final canFreeze = repairableStreak > 0 && freezes > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF211B17),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded,
                  color: Color(0xFFE07A3E), size: 20),
              const SizedBox(width: 6),
              Text('$streak-day streak',
                  style: displayFont(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: kVelvetInk)),
              const Spacer(),
              const Icon(Icons.ac_unit_rounded,
                  color: Color(0xFF6FA8DC), size: 16),
              const SizedBox(width: 4),
              Text('$freezes',
                  style: const TextStyle(
                      color: kVelvetMuted, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [for (final d in days) _dayCell(d, today)],
          ),
          if (canFreeze) ...[
            const SizedBox(height: 14),
            TappableScale(
              onTap: onUseFreeze,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF6FA8DC), Color(0xFF3E7CA8)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text('Use a freeze to keep your $repairableStreak-day streak',
                    style: const TextStyle(
                        color: Color(0xFF0C1A24),
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dayCell(DateTime d, String today) {
    final k = _dayKey(d);
    final isToday = k == today;
    final active = activeDays.contains(k);
    final frozen = frozenDays.contains(k);
    final missed = !active && !frozen && !isToday;

    Color bg, border, icon;
    IconData glyph;
    if (active) {
      bg = const Color(0xFF17281C);
      border = const Color(0xFF63C583);
      icon = const Color(0xFF63C583);
      glyph = Icons.check_rounded;
    } else if (frozen) {
      bg = const Color(0xFF14202B);
      border = const Color(0xFF6FA8DC);
      icon = const Color(0xFF6FA8DC);
      glyph = Icons.ac_unit_rounded;
    } else if (missed) {
      bg = const Color(0xFF2C1D18);
      border = const Color(0xFFE0655A);
      icon = const Color(0xFFE0655A);
      glyph = Icons.close_rounded;
    } else {
      // today, not yet practised
      bg = const Color(0xFF1B1613);
      border = Colors.white24;
      icon = kVelvetMuted;
      glyph = Icons.circle_outlined;
    }
    return Column(
      children: [
        Text(_wd[d.weekday - 1],
            style: TextStyle(
                color: isToday ? kOchre : kVelvetMuted,
                fontWeight: FontWeight.w700,
                fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: border, width: 1.6),
          ),
          child: Icon(glyph, color: icon, size: 18),
        ),
      ],
    );
  }
}
