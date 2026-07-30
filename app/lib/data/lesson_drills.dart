import 'dart:math';
import 'lesson_content.dart';

/// The kinds of practice drill a lesson can serve. MCQ is the classic
/// multiple-choice; the rest are generated from the unit's own glossary and
/// example sentences so no extra authoring is needed.
enum DrillKind { mcq, match, listen, build }

/// Match English ↔ Twi pairs (up to four at a time).
class MatchDrill {
  final List<GlossEntry> pairs;
  const MatchDrill(this.pairs);
}

/// Hear the Twi, pick its English meaning.
class ListenDrill {
  final GlossEntry answer;
  final List<String> options; // english meanings incl. the correct one
  const ListenDrill(this.answer, this.options);
}

/// Normalize a Twi token for glossary lookup: lowercase + strip punctuation
/// (keeps the Twi vowels ɔ/ɛ, which are word characters).
String normTwi(String w) =>
    w.toLowerCase().replaceAll(RegExp('''[.,!?;:"'“”‘’()]'''), '').trim();

/// Arrange the scrambled word tiles to match the spoken Twi sentence.
class BuildDrill {
  final List<String> tokens; // the sentence, in order
  final String audio; // the full sentence, for TTS
  final Map<String, String> gloss; // normalized Twi -> English (literal fallback)
  const BuildDrill(this.tokens, this.audio, {this.gloss = const {}});

  /// A literal word-by-word English gloss assembled from the unit glossary.
  /// Words not in the glossary (particles, inflections) stay in Twi — a learning
  /// aid, not a polished translation. Prefer a hand-authored `en` when one lands.
  String literalGloss() =>
      tokens.map((t) => gloss[normTwi(t)] ?? t).join(' ');
}

/// One item in a lesson's interleaved practice sequence.
class LessonDrill {
  final DrillKind kind;
  final Challenge? mcq;
  final MatchDrill? match;
  final ListenDrill? listen;
  final BuildDrill? build;
  const LessonDrill._(this.kind,
      {this.mcq, this.match, this.listen, this.build});

  factory LessonDrill.mcq(Challenge c) =>
      LessonDrill._(DrillKind.mcq, mcq: c);
  factory LessonDrill.match(MatchDrill m) =>
      LessonDrill._(DrillKind.match, match: m);
  factory LessonDrill.listen(ListenDrill l) =>
      LessonDrill._(DrillKind.listen, listen: l);
  factory LessonDrill.build(BuildDrill b) =>
      LessonDrill._(DrillKind.build, build: b);
}

/// Builds an interleaved, varied practice sequence for [u]: the classic MCQs
/// mixed with word-match, listen-and-choose and build-the-sentence drills
/// generated from the unit's glossary + example sentences. Falls back to
/// MCQ-only when a unit lacks the data. Capped so lessons stay a sensible length.
List<LessonDrill> buildLessonDrills(UnitContent u, Random r, {int cap = 12}) {
  final mcqs = [for (final c in u.challenges) LessonDrill.mcq(c.shuffledOptions(r))];

  // ── Word match: chunk the glossary into groups of up to four pairs ──
  final gloss = [...u.glossary]..shuffle(r);
  final matches = <LessonDrill>[];
  for (var i = 0; i + 3 <= gloss.length; i += 4) {
    final chunk = gloss.skip(i).take(4).toList();
    if (chunk.length >= 3) matches.add(LessonDrill.match(MatchDrill(chunk)));
  }

  // ── Listen & choose: single-word audio → pick the meaning ──
  final listens = <LessonDrill>[];
  if (u.glossary.length >= 3) {
    final picks = ([...u.glossary]..shuffle(r)).take(3).toList();
    for (final ans in picks) {
      final distract = ([
        ...u.glossary.where((g) => g.en != ans.en)
      ]..shuffle(r))
          .take(2)
          .map((g) => g.en)
          .toList();
      if (distract.length < 2) continue;
      final opts = [ans.en, ...distract]..shuffle(r);
      listens.add(LessonDrill.listen(ListenDrill(ans, opts)));
    }
  }

  // ── Build the sentence: scramble an example (3–6 words) ──
  final builds = <LessonDrill>[];
  final glossMap = {for (final g in u.glossary) normTwi(g.twi): g.en};
  for (final s in u.examples) {
    final toks =
        s.split(RegExp(r'\s+')).where((t) => t.trim().isNotEmpty).toList();
    if (toks.length >= 3 && toks.length <= 6) {
      builds.add(LessonDrill.build(BuildDrill(toks, s, gloss: glossMap)));
    }
  }

  // ── Round-robin interleave so the practice never blocks on one type ──
  final pools = [mcqs, matches, listens, builds];
  final idx = [0, 0, 0, 0];
  final out = <LessonDrill>[];
  var guard = 0;
  while (out.length < cap && guard < 400) {
    guard++;
    final p = guard % 4;
    if (idx[p] < pools[p].length) {
      out.add(pools[p][idx[p]]);
      idx[p]++;
    }
    if (idx[0] >= mcqs.length &&
        idx[1] >= matches.length &&
        idx[2] >= listens.length &&
        idx[3] >= builds.length) {
      break;
    }
  }
  return out.isEmpty ? mcqs : out;
}
