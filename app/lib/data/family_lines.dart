import 'dart:math';

/// Short, in-character lines for the four Super Family guides, keyed by avatar
/// id. One place to write / localise / native-check all narrative microcopy.
///
/// NOTE: these are DRAFT English lines — native-speaker review before ship,
/// especially anything with Twi in it.
class FamilyLines {
  const FamilyLines._();

  /// Played on the celebration screen after a lesson pass (in the guide's voice).
  static const Map<String, List<String>> _celebrate = {
    'auntie': [
      'You ate that up! 💅',
      'Twi is giving fluent — keep going!',
      "That's my star. Yɛnkɔ!",
    ],
    'uncle': [
      "Steady and strong — that's how it's done.",
      'See? You had it all along.',
      "One more step home. I'm right here.",
    ],
    'grandma': [
      'Every word is a root re-planted.',
      'The ancestors are smiling, me ba.',
      'Wisdom looks good on you.',
    ],
    'grandpa': [
      'Now that deserves a story.',
      'You spoke it true. Kwaku Ananse would nod.',
      'Home is getting closer, my child.',
    ],
  };

  /// Shown on the home map beneath the greeting (a warm nudge to start).
  static const Map<String, List<String>> _greeting = {
    'auntie': [
      'Ready to shine today? Yɛnkɔ!',
      'Let’s get you talking like family.',
      'Small small — you’re glowing already.',
    ],
    'uncle': [
      'Take it easy — one lesson at a time.',
      'You’ve got this. I’m right here.',
      'Steady wins. Let’s go.',
    ],
    'grandma': [
      'Every word you learn, an ancestor smiles.',
      'Sit with me a while — we’ll grow your cloth.',
      'Patience, me ba. Roots take time.',
    ],
    'grandpa': [
      'Aane, aane… sit, we have work to do.',
      'Learn well, and maybe a story after.',
      'The old words are waiting for you.',
    ],
  };

  static String celebrate(String? avatarId, [Random? rng]) =>
      _pick(_celebrate, avatarId, rng);

  static String greeting(String? avatarId, [Random? rng]) =>
      _pick(_greeting, avatarId, rng);

  static String _pick(Map<String, List<String>> m, String? id, Random? rng) {
    final pool = m[id] ?? m['auntie']!;
    return pool[(rng ?? Random()).nextInt(pool.length)];
  }
}
