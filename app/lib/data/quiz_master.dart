import 'dart:math';

/// The "Sankofa Quiz Master" voice — punchy per-answer feedback that keeps the
/// momentum high, plus a mastery title for the summary. Framed around the
/// Sankofa journey and the Super Family, not the retired tro-tro. Encouragement
/// is always positive: a wrong answer is a step back to learn, never a fail.

const List<String> _cheers = [
  'Ayɛkoo!',
  'Sharp — nice one!',
  'Yɛn kɔ — keep going!',
  "That's it, chale!",
  'Wo ho yɛ — you’re shining!',
  'Onward!',
  'Beautiful — straight through!',
];

const List<String> _nudges = [
  'Sankofa — go back and get it.',
  'Almost there, keep going.',
  "Small miss — you've got this.",
  'Not that one — shake it off.',
  'Close! Try again.',
];

final Random _r = Random();

String quizCheer() => _cheers[_r.nextInt(_cheers.length)];
String quizNudge() => _nudges[_r.nextInt(_nudges.length)];

class MasteryTitle {
  final String title;
  final String blurb;
  const MasteryTitle(this.title, this.blurb);
}

/// A mastery title from a 0..1 score fraction — journey + family themed.
MasteryTitle masteryTitleFor(double fraction) {
  if (fraction >= 1.0) {
    return const MasteryTitle('Kente Master 🏆', 'Flawless run — Ayɛkoo!');
  }
  if (fraction >= 0.8) {
    return const MasteryTitle("Nana's Pride 👑", 'Wisdom worthy of the elders.');
  }
  if (fraction >= 0.6) {
    return const MasteryTitle('Steady Traveller 🧭', 'On the journey, moving strong.');
  }
  if (fraction >= 0.4) {
    return const MasteryTitle('Growing Roots 🌿', 'Keep practising — Yɛbɛba bio!');
  }
  return const MasteryTitle('Just Getting Started 🌱', 'Every master started here.');
}
