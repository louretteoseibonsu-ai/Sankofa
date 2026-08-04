import 'package:flutter/material.dart';
import '../theme.dart';
import 'velvet.dart';
import 'speak_button.dart';

/// The Twi alphabet teaching data — one source of truth shared by the Tools
/// alphabet screen and the in-lesson "Learn first" primer.
/// Each row: [letter, sound (English approximation), example word (tap to hear)].
/// Example words are pre-bundled clips, so audio is verified-correct.
const List<List<String>> kTwiVowels = [
  ['a', 'ah — as in "father"', 'aane'],
  ['e', 'ay — as in "they"', 'edu'],
  ['ɛ', 'eh — as in "bed"', 'ɛmo'],
  ['i', 'ee — as in "see"', 'mmienu'],
  ['o', 'oh — as in "go"', 'onua'],
  ['ɔ', 'aw — as in "law"', 'ɔdɔ'],
  ['u', 'oo — as in "food"', 'nsuo'],
];

const List<List<String>> kTwiConsonants = [
  ['b', 'b', 'baako'],
  ['d', 'd', 'didi'],
  ['f', 'f', 'fie'],
  ['h', 'h', 'maaha'],
  ['k', 'k', 'kaa'],
  ['l', 'l (in loanwords)', 'ludo'],
  ['m', 'm', 'mako'],
  ['n', 'n', 'nana'],
  ['p', 'p', 'papa'],
  ['r', 'r (lightly tapped)', 'borɔdeɛ'],
  ['s', 's', 'sika'],
  ['t', 't', 'tii'],
  ['w', 'w', 'wo'],
  ['y', 'y', 'yɛ'],
];

const List<List<String>> kTwiDigraphs = [
  ['ky', 'ch — as in "church"', 'kyerɛw'],
  ['gy', 'j — as in "joy"', 'gyina'],
  ['hy', 'sh — as in "ship"', 'hyɛ'],
  ['kw', 'qu — as in "queen"', 'kwadu'],
  ['tw', 'chw — rounded "ch"', 'twene'],
  ['dw', 'jw — rounded "j"', 'dwom'],
  ['ny', 'ny — as in "canyon"', 'nyansa'],
  ['nw', 'nw — rounded "n"', 'nwoma'],
];

/// The full alphabet reference — vowels, consonants, digraphs — each row
/// tap-to-hear. Used standalone in Tools and inside the lesson Learn phase.
class AlphabetPrimer extends StatelessWidget {
  /// Show the one-line "what makes Twi different" intro above the sections.
  final bool showIntro;
  const AlphabetPrimer({super.key, this.showIntro = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showIntro) ...[
          const Text(
              'Tap any example to hear the sound. Twi drops c, j, q, v, x, z '
              'and adds two special vowels: ɛ and ɔ.',
              style: TextStyle(color: kVelvetMuted, fontSize: 13.5, height: 1.5)),
          const SizedBox(height: 16),
        ],
        const AlphabetSection(
            title: 'Vowels',
            subtitle: 'Seven in total — master ɛ and ɔ.',
            rows: kTwiVowels),
        const SizedBox(height: 14),
        const AlphabetSection(title: 'Consonants', rows: kTwiConsonants),
        const SizedBox(height: 14),
        const AlphabetSection(
            title: 'Digraphs',
            subtitle: 'Two letters, one sound — the ones English speakers miss.',
            rows: kTwiDigraphs),
      ],
    );
  }
}

/// One titled group of letter → sound rows, each with a tap-to-hear button.
class AlphabetSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<List<String>> rows;
  const AlphabetSection(
      {super.key, required this.title, this.subtitle, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF211B17),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 17, color: kVelvetInk)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!,
                style: const TextStyle(color: kVelvetMuted, fontSize: 12.5)),
          ],
          const SizedBox(height: 6),
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, color: Color(0x1FFFFFFF)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    child: Text(rows[i][0],
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                            color: terracotta)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rows[i][1],
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: kVelvetInk)),
                        Text(rows[i][2],
                            style: const TextStyle(
                                fontSize: 12.5, color: kVelvetMuted)),
                      ],
                    ),
                  ),
                  SpeakButton(text: rows[i][2], size: 20),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
