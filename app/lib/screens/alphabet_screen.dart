import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/velvet.dart';
import '../widgets/floating_card.dart';
import '../widgets/speak_button.dart';

/// A tappable reference chart of the Twi alphabet and its sounds.
/// Vowels, consonants, and the digraphs that trip up English speakers.
class AlphabetScreen extends StatelessWidget {
  const AlphabetScreen({super.key});

  // letter, sound (English approximation), example word (tap to hear)
  // All example words are pre-bundled clips, so audio is verified-correct.
  static const List<List<String>> _vowels = [
    ['a', 'ah — as in "father"', 'aane'],
    ['e', 'ay — as in "they"', 'edu'],
    ['ɛ', 'eh — as in "bed"', 'ɛmo'],
    ['i', 'ee — as in "see"', 'mmienu'],
    ['o', 'oh — as in "go"', 'onua'],
    ['ɔ', 'aw — as in "law"', 'ɔdɔ'],
    ['u', 'oo — as in "food"', 'nsuo'],
  ];

  static const List<List<String>> _consonants = [
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

  static const List<List<String>> _digraphs = [
    ['ky', 'ch — as in "church"', 'kyerɛw'],
    ['gy', 'j — as in "joy"', 'gyina'],
    ['hy', 'sh — as in "ship"', 'hyɛ'],
    ['kw', 'qu — as in "queen"', 'kwadu'],
    ['tw', 'chw — rounded "ch"', 'twene'],
    ['dw', 'jw — rounded "j"', 'dwom'],
    ['ny', 'ny — as in "canyon"', 'nyansa'],
    ['nw', 'nw — rounded "n"', 'nwoma'],
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('The Twi Alphabet',
            style: displayFont(fontSize: 26, fontWeight: FontWeight.w800)),
        SizedBox(height: 4),
        Text('Tap any example to hear the sound. Twi drops c, j, q, v, x, z '
            'and adds two special vowels: ɛ and ɔ.',
            style: TextStyle(color: kVelvetMuted, fontSize: 13.5, height: 1.5)),
        SizedBox(height: 18),
        _Section(title: 'Vowels', subtitle: 'Seven in total — master ɛ and ɔ.', rows: _vowels),
        SizedBox(height: 16),
        _Section(title: 'Consonants', rows: _consonants),
        SizedBox(height: 16),
        _Section(
            title: 'Digraphs',
            subtitle: 'Two letters, one sound — the ones English speakers miss.',
            rows: _digraphs),
        SizedBox(height: 24),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<List<String>> rows;
  const _Section({required this.title, this.subtitle, required this.rows});

  @override
  Widget build(BuildContext context) {
    return FloatingCard(
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
            if (i > 0) const Divider(height: 1, color: const Color(0x1FFFFFFF)),
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
