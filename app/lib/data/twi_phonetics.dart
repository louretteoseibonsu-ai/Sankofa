/// Lightweight Twi pronunciation helpers for learners.
///
/// Twi spelling hides a few sounds that trip up English speakers:
///  ky → "ch", gy → "j", hy → "sh", dw → "jw", tw → "chw",
///  ɛ → the "e" in "bed", ɔ → the "aw" in "law".

/// A rough "sounds-like" respelling using English approximations.
String twiApproximate(String word) {
  var w = word;
  const digraphs = {
    'ky': 'ch',
    'gy': 'j',
    'hy': 'sh',
    'dw': 'jw',
    'tw': 'chw',
  };
  digraphs.forEach((k, v) {
    w = w.replaceAll(k, v).replaceAll(k.toUpperCase(), v);
  });
  w = w
      .replaceAll('ɛ', 'eh')
      .replaceAll('Ɛ', 'eh')
      .replaceAll('ɔ', 'aw')
      .replaceAll('Ɔ', 'aw')
      .replaceAll('ŋ', 'ng');
  return w;
}

const Map<String, String> _guide = {
  'ky': 'ch — as in "church"',
  'gy': 'j — as in "joy"',
  'hy': 'sh — as in "ship"',
  'dw': 'jw — rounded "j"',
  'tw': 'chw — rounded "ch"',
  'ny': 'ny — as in "canyon"',
  'ɛ': 'ɛ — the "e" in "bed"',
  'ɔ': 'ɔ — the "aw" in "law"',
};

/// The notable Twi sounds present in [text], for a learner-friendly guide.
List<MapEntry<String, String>> twiKeySounds(String text) {
  final lower = text.toLowerCase();
  final out = <MapEntry<String, String>>[];
  for (final e in _guide.entries) {
    final g = e.key;
    final present =
        (g == 'ɛ' || g == 'ɔ') ? text.contains(g) : lower.contains(g);
    if (present) out.add(e);
  }
  return out;
}
