import 'package:flutter/material.dart';
import '../theme.dart';
import 'velvet.dart';
import 'tappable_scale.dart';

const List<int> kStreakGoals = [7, 14, 21, 28];

/// Lets a learner commit to a 7/14/21/28-day streak goal (or skip), and shows
/// progress toward the goal once committed.
class StreakGoalCard extends StatelessWidget {
  final int streak;
  final int streakGoal; // 0 = not committed
  final ValueChanged<int> onCommit; // pick a goal (or 0 to clear)
  const StreakGoalCard({
    super.key,
    required this.streak,
    required this.streakGoal,
    required this.onCommit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF211B17),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: streakGoal <= 0 ? _picker(context) : _progress(context),
    );
  }

  Widget _picker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.flag_rounded, color: kOchre, size: 20),
            const SizedBox(width: 6),
            Text('Commit to a streak',
                style: displayFont(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: kVelvetInk)),
          ],
        ),
        const SizedBox(height: 6),
        const Text('Set a target and keep your fire alive. Momentum builds fast.',
            style: TextStyle(color: kVelvetMuted, fontSize: 12.5, height: 1.4)),
        const SizedBox(height: 14),
        Row(
          children: [
            for (final g in kStreakGoals) ...[
              Expanded(
                child: TappableScale(
                  onTap: () => onCommit(g),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A211C),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x33E3A92C)),
                    ),
                    child: Column(
                      children: [
                        Text('$g',
                            style: const TextStyle(
                                color: kOchre,
                                fontWeight: FontWeight.w800,
                                fontSize: 18)),
                        const Text('days',
                            style: TextStyle(
                                color: kVelvetMuted, fontSize: 10.5)),
                      ],
                    ),
                  ),
                ),
              ),
              if (g != kStreakGoals.last) const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }

  Widget _progress(BuildContext context) {
    final done = streak >= streakGoal;
    final pct = (streak / streakGoal).clamp(0.0, 1.0);
    final remaining = (streakGoal - streak).clamp(0, streakGoal);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(done ? Icons.emoji_events_rounded : Icons.flag_rounded,
                color: done ? const Color(0xFF63C583) : kOchre, size: 20),
            const SizedBox(width: 6),
            Text(done ? 'Goal smashed!' : '$streakGoal-day goal',
                style: displayFont(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: kVelvetInk)),
            const Spacer(),
            Text('$streak / $streakGoal',
                style: const TextStyle(
                    color: kVelvetMuted, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: const Color(0x1FFFFFFF),
            valueColor: AlwaysStoppedAnimation(
                done ? const Color(0xFF63C583) : kOchre),
          ),
        ),
        const SizedBox(height: 10),
        if (done)
          Row(
            children: [
              const Expanded(
                child: Text('Amazing work. Ready for the next one?',
                    style: TextStyle(color: kVelvetMuted, fontSize: 12.5)),
              ),
              TappableScale(
                onTap: () => onCommit(0),
                child: const Text('Set new goal',
                    style: TextStyle(
                        color: kOchre,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5)),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: Text(
                    '$remaining ${remaining == 1 ? 'day' : 'days'} to go — keep it up!',
                    style: const TextStyle(
                        color: kVelvetMuted, fontSize: 12.5)),
              ),
              TappableScale(
                onTap: () => onCommit(0),
                child: const Text('Change',
                    style: TextStyle(
                        color: kVelvetMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5)),
              ),
            ],
          ),
      ],
    );
  }
}
