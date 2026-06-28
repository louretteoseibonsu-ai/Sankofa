import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../services/sound_service.dart';
import '../widgets/continue_button.dart';
import '../widgets/floating_card.dart';

// On-brand feedback colours (Kente green / maroon) used only for quiz states.
const Color _correctGreen = Color(0xFF2E6B3B);
const Color _wrongRed = Color(0xFF9B2D2A);

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  Map<String, dynamic>? _unit;
  // challenge index -> chosen option index
  final Map<int, int> _selected = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw =
        await rootBundle.loadString('assets/content/unit_001.example.json');
    if (!mounted) return;
    setState(() => _unit = json.decode(raw) as Map<String, dynamic>);
  }

  void _choose(int challengeIndex, int optionIndex, int correctIndex) {
    if (_selected.containsKey(challengeIndex)) return; // lock after answering
    setState(() => _selected[challengeIndex] = optionIndex);
    if (optionIndex == correctIndex) {
      HapticFeedback.selectionClick();
      SoundService.instance.correct();
    } else {
      HapticFeedback.heavyImpact();
      SoundService.instance.tap();
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = _unit;
    if (u == null) return const Center(child: CircularProgressIndicator());

    final vocab = u['vocabulary_spotlight'] as Map<String, dynamic>;
    final bridge = vocab['phonetic_bridge'] as Map<String, dynamic>;
    final examples =
        (vocab['example_sentences'] as List?)?.cast<String>() ?? const [];
    final grammar = u['grammar_mechanics'] as Map<String, dynamic>?;
    final challenges =
        (u['lineage_challenges'] as List).cast<Map<String, dynamic>>();

    final answered = _selected.length;
    final correct = _selected.entries
        .where((e) =>
            e.value == (challenges[e.key]['correct_index'] as int))
        .length;
    final allDone = answered == challenges.length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(u['unit_title'] as String,
            style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 22, color: ink)),
        const SizedBox(height: 14),

        // ── Vocabulary spotlight ──────────────────────────────────────────
        FloatingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('VOCABULARY SPOTLIGHT',
                  style: TextStyle(
                      color: slate,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.6)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(vocab['headword'] as String,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          color: ink)),
                  const SizedBox(width: 10),
                  Text('/${bridge['pronunciation']}/',
                      style: const TextStyle(color: slate, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 6),
              Text(vocab['gloss'] as String,
                  style: const TextStyle(height: 1.5, color: ink)),
              if (examples.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('In a sentence',
                    style: TextStyle(
                        color: slate,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
                const SizedBox(height: 4),
                for (final s in examples)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('•  $s',
                        style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                            color: ink)),
                  ),
              ],
            ],
          ),
        ),

        // ── Grammar mechanics ─────────────────────────────────────────────
        if (grammar != null) ...[
          const SizedBox(height: 14),
          FloatingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('GRAMMAR',
                    style: TextStyle(
                        color: slate,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.6)),
                const SizedBox(height: 8),
                Text(grammar['focus'] as String,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16, color: ink)),
                const SizedBox(height: 6),
                Text(grammar['explanation'] as String,
                    style: const TextStyle(height: 1.5, color: ink)),
                if (grammar['patterns'] is List) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (grammar['patterns'] as List)
                        .cast<String>()
                        .map((p) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: glyphTile,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(p,
                                  style: const TextStyle(
                                      fontSize: 13, color: ink)),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Lineage Challenges',
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 16, color: ink)),
            Text('$answered / ${challenges.length}',
                style: const TextStyle(
                    color: slate, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 12),

        // ── Interactive challenges ────────────────────────────────────────
        for (int i = 0; i < challenges.length; i++)
          _ChallengeCard(
            index: i,
            challenge: challenges[i],
            selected: _selected[i],
            onChoose: (opt) => _choose(
                i, opt, challenges[i]['correct_index'] as int),
          ),

        const SizedBox(height: 8),
        if (allDone)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Center(
              child: Text('You scored $correct / ${challenges.length}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16, color: ink)),
            ),
          ),
        ContinueButton(onPressed: () {
          if (allDone) {
            SoundService.instance.complete();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    'Lesson complete — $correct / ${challenges.length} correct. Akwaaba!')));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    'Answer all ${challenges.length} challenges to finish (${challenges.length - answered} left).')));
          }
        }),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> challenge;
  final int? selected;
  final ValueChanged<int> onChoose;

  const _ChallengeCard({
    required this.index,
    required this.challenge,
    required this.selected,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    final options = (challenge['options'] as List).cast<String>();
    final correctIndex = challenge['correct_index'] as int;
    final answered = selected != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FloatingCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: charcoal,
                  child: Text('${index + 1}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(challenge['prompt'] as String,
                      style: const TextStyle(
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                          color: ink)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (int o = 0; o < options.length; o++)
              _OptionTile(
                label: options[o],
                state: !answered
                    ? _OptState.idle
                    : o == correctIndex
                        ? _OptState.correct
                        : o == selected
                            ? _OptState.wrong
                            : _OptState.dimmed,
                onTap: answered ? null : () => onChoose(o),
              ),
          ],
        ),
      ),
    );
  }
}

enum _OptState { idle, correct, wrong, dimmed }

class _OptionTile extends StatelessWidget {
  final String label;
  final _OptState state;
  final VoidCallback? onTap;

  const _OptionTile({required this.label, required this.state, this.onTap});

  @override
  Widget build(BuildContext context) {
    Color border = silver;
    Color bg = Colors.white;
    Color fg = ink;
    Widget? trailing;
    switch (state) {
      case _OptState.idle:
        break;
      case _OptState.correct:
        border = _correctGreen;
        bg = const Color(0xFFEAF3EC);
        fg = _correctGreen;
        trailing = const Icon(Icons.check_circle, color: _correctGreen, size: 20);
        break;
      case _OptState.wrong:
        border = _wrongRed;
        bg = const Color(0xFFF7EAE9);
        fg = _wrongRed;
        trailing = const Icon(Icons.cancel, color: _wrongRed, size: 20);
        break;
      case _OptState.dimmed:
        border = silverLight;
        fg = slate;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border, width: 1.4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(label,
                      style: TextStyle(
                          color: fg,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
