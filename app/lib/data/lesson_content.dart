import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

/// A single multiple-choice challenge.
class Challenge {
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String category;
  const Challenge(this.prompt, this.options, this.correctIndex,
      {this.category = ''});

  String get correctLabel => options[correctIndex];

  /// Returns a copy with options shuffled (correct index re-pointed).
  Challenge shuffledOptions(Random r) {
    final label = correctLabel;
    final opts = [...options]..shuffle(r);
    return Challenge(prompt, opts, opts.indexOf(label), category: category);
  }
}

class GlossEntry {
  final String twi;
  final String en;
  const GlossEntry(this.twi, this.en);
}

class UnitContent {
  final String title;
  final String headword;
  final String pronunciation;
  final String gloss;
  final List<String> examples;
  final Map<String, dynamic>? grammar;
  final List<Challenge> challenges;
  final List<GlossEntry> glossary;
  final bool reviewRequired;
  const UnitContent({
    required this.title,
    required this.headword,
    required this.pronunciation,
    required this.gloss,
    required this.examples,
    required this.grammar,
    required this.challenges,
    required this.glossary,
    required this.reviewRequired,
  });
}

Future<UnitContent> loadUnit(String asset, {required String category}) async {
  final raw = await rootBundle.loadString(asset);
  final u = json.decode(raw) as Map<String, dynamic>;
  final v = u['vocabulary_spotlight'] as Map<String, dynamic>;
  final bridge = v['phonetic_bridge'] as Map<String, dynamic>?;
  final challenges = (u['lineage_challenges'] as List)
      .cast<Map<String, dynamic>>()
      .map((c) => Challenge(
            c['prompt'] as String,
            (c['options'] as List).cast<String>(),
            c['correct_index'] as int,
            category: category,
          ))
      .toList();
  final glossary = (u['glossary'] as List?)
          ?.cast<Map<String, dynamic>>()
          .map((g) => GlossEntry(g['twi'] as String, g['en'] as String))
          .toList() ??
      const <GlossEntry>[];
  return UnitContent(
    title: u['unit_title'] as String,
    headword: v['headword'] as String,
    pronunciation: (bridge?['pronunciation'] as String?) ?? '',
    gloss: v['gloss'] as String,
    examples: (v['example_sentences'] as List?)?.cast<String>() ?? const [],
    grammar: u['grammar_mechanics'] as Map<String, dynamic>?,
    challenges: challenges,
    glossary: glossary,
    reviewRequired: (u['review_required'] as bool?) ?? false,
  );
}
