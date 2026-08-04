import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/alphabet_primer.dart';

/// A tappable reference chart of the Twi alphabet and its sounds.
/// Vowels, consonants, and the digraphs that trip up English speakers.
/// The teaching content itself lives in [AlphabetPrimer] (shared with the
/// in-lesson "Learn first" phase).
class AlphabetScreen extends StatelessWidget {
  const AlphabetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('The Twi Alphabet',
            style: displayFont(fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const AlphabetPrimer(),
        const SizedBox(height: 24),
      ],
    );
  }
}
