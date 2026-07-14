import 'dart:math';

/// The "Sankofa Quiz Master" voice — punchy per-answer feedback that keeps the
/// momentum high, plus a fun tro-tro-themed mastery title for the summary.
/// Encouragement is always positive: a wrong answer is a detour, never a fail.

const List<String> _cheers = [
  "Vroom! That's it!",
  'Nice move!',
  'Ayɛkoo — smooth driving!',
  "Chale, you're flying!",
  "That's the road!",
  'Sharp! Keep cruising.',
  'Straight ahead — yɛn kɔ!',
];

const List<String> _nudges = [
  "Bumpy road — let's pivot.",
  'Almost there, keep going.',
  "Small detour — you've got this.",
  'Not that turn — shake it off.',
  'Close! Back on the road.',
];

final Random _r = Random();

String quizCheer() => _cheers[_r.nextInt(_cheers.length)];
String quizNudge() => _nudges[_r.nextInt(_nudges.length)];

class MasteryTitle {
  final String title;
  final String blurb;
  const MasteryTitle(this.title, this.blurb);
}

/// A fun mastery title from a 0..1 score fraction.
MasteryTitle masteryTitleFor(double fraction) {
  if (fraction >= 1.0) {
    return const MasteryTitle('Kente Road Master 🏆', 'Flawless run — Ayɛkoo!');
  }
  if (fraction >= 0.8) {
    return const MasteryTitle('Highway Hero 🛣️', 'Cruising with confidence.');
  }
  if (fraction >= 0.6) {
    return const MasteryTitle('Steady Driver 🚐', 'On the road and rolling.');
  }
  if (fraction >= 0.4) {
    return const MasteryTitle("Learner's Permit 🔰", 'Keep practising — Yɛbɛba bio!');
  }
  return const MasteryTitle('Just Getting Started 🌱', 'Every master started here.');
}
