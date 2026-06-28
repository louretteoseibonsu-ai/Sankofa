import 'package:flutter/material.dart';

/// One lesson = one bundled unit JSON.
class Lesson {
  final String id;
  final String title;
  final String subtitle; // Twi name
  final String asset;
  final String categoryId;
  const Lesson({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.asset,
    required this.categoryId,
  });
}

/// A subject the learner can master.
class LessonCategory {
  final String id;
  final String name;
  final String emoji;
  final String blurb;
  final IconData icon;
  final List<Lesson> lessons;
  const LessonCategory({
    required this.id,
    required this.name,
    this.emoji = '',
    required this.blurb,
    required this.icon,
    required this.lessons,
  });
}

// ── The "Sankofa Twi" Spiral Trajectory (foundation → outward) ────────────
const List<LessonCategory> kCategories = [
  LessonCategory(
    id: 'greetings',
    emoji: '👋🏾',
    name: 'Foundations · Greetings',
    blurb: 'The first words that open every door.',
    icon: Icons.waving_hand_outlined,
    lessons: [
      Lesson(id: 'unit_002', title: 'Greetings', subtitle: 'Nkyea', asset: 'assets/content/unit_002.json', categoryId: 'greetings'),
    ],
  ),
  LessonCategory(
    id: 'dining',
    emoji: '🍲',
    name: 'Dining Out',
    blurb: 'Order food, drink, and ask for what you need.',
    icon: Icons.restaurant_outlined,
    lessons: [
      Lesson(id: 'unit_016', title: 'Dining Out', subtitle: 'Adidie', asset: 'assets/content/unit_016.json', categoryId: 'dining'),
    ],
  ),
  LessonCategory(
    id: 'hobbies',
    emoji: '⚽',
    name: 'Hobbies',
    blurb: 'Play, sport, and things you love to do.',
    icon: Icons.sports_esports_outlined,
    lessons: [
      Lesson(id: 'unit_015', title: 'Hobbies', subtitle: 'Anigyedeɛ', asset: 'assets/content/unit_015.json', categoryId: 'hobbies'),
    ],
  ),
  LessonCategory(
    id: 'travel',
    emoji: '✈️',
    name: 'Travel',
    blurb: 'Getting around and going places.',
    icon: Icons.flight_takeoff_outlined,
    lessons: [
      Lesson(id: 'unit_017', title: 'Travel', subtitle: 'Akwantuo', asset: 'assets/content/unit_017.json', categoryId: 'travel'),
    ],
  ),
  LessonCategory(
    id: 'dating',
    emoji: '❤️',
    name: 'Dating & Love',
    blurb: 'Affection, romance, and relationships.',
    icon: Icons.favorite_border,
    lessons: [
      Lesson(id: 'unit_014', title: 'Dating & Love', subtitle: 'Ɔdɔ', asset: 'assets/content/unit_014.json', categoryId: 'dating'),
    ],
  ),
  LessonCategory(
    id: 'family',
    emoji: '👨🏾‍👩🏾‍👧🏾',
    name: 'Family',
    blurb: 'The people closest to you.',
    icon: Icons.family_restroom_outlined,
    lessons: [
      Lesson(id: 'unit_004', title: 'Family Members', subtitle: 'Abusuafoɔ', asset: 'assets/content/unit_004.json', categoryId: 'family'),
    ],
  ),
  LessonCategory(
    id: 'numbers',
    emoji: '🔢',
    name: 'Numbers & Counting',
    blurb: 'Count from one all the way to one hundred.',
    icon: Icons.tag_outlined,
    lessons: [
      Lesson(id: 'unit_003', title: 'Numbers 1–10', subtitle: 'Akontaabuo', asset: 'assets/content/unit_003.json', categoryId: 'numbers'),
      Lesson(id: 'unit_005', title: 'Numbers 11–20', subtitle: 'Dubaako – Aduonu', asset: 'assets/content/unit_005.json', categoryId: 'numbers'),
      Lesson(id: 'unit_006', title: 'Numbers 21–30', subtitle: 'Aduonu – Aduasa', asset: 'assets/content/unit_006.json', categoryId: 'numbers'),
      Lesson(id: 'unit_007', title: 'Numbers 31–40', subtitle: 'Aduasa – Aduanan', asset: 'assets/content/unit_007.json', categoryId: 'numbers'),
      Lesson(id: 'unit_008', title: 'Numbers 41–50', subtitle: 'Aduanan – Aduonum', asset: 'assets/content/unit_008.json', categoryId: 'numbers'),
      Lesson(id: 'unit_009', title: 'Numbers 51–60', subtitle: 'Aduonum – Aduosia', asset: 'assets/content/unit_009.json', categoryId: 'numbers'),
      Lesson(id: 'unit_010', title: 'Numbers 61–70', subtitle: 'Aduosia – Aduoson', asset: 'assets/content/unit_010.json', categoryId: 'numbers'),
      Lesson(id: 'unit_011', title: 'Numbers 71–80', subtitle: 'Aduoson – Aduowɔtwe', asset: 'assets/content/unit_011.json', categoryId: 'numbers'),
      Lesson(id: 'unit_012', title: 'Numbers 81–90', subtitle: 'Aduowɔtwe – Aduokron', asset: 'assets/content/unit_012.json', categoryId: 'numbers'),
      Lesson(id: 'unit_013', title: 'Numbers 91–100', subtitle: 'Aduokron – Ɔha', asset: 'assets/content/unit_013.json', categoryId: 'numbers'),
    ],
  ),
  LessonCategory(
    id: 'music',
    emoji: '🎵',
    name: 'Music',
    blurb: 'Songs, drums, and dancing.',
    icon: Icons.music_note_outlined,
    lessons: [
      Lesson(id: 'unit_020', title: 'Music', subtitle: 'Nnwom', asset: 'assets/content/unit_020.json', categoryId: 'music'),
    ],
  ),
  LessonCategory(
    id: 'movies',
    emoji: '🎬',
    name: 'Movies',
    blurb: 'Films, shows, and watching together.',
    icon: Icons.movie_outlined,
    lessons: [
      Lesson(id: 'unit_018', title: 'Movies', subtitle: 'Sini', asset: 'assets/content/unit_018.json', categoryId: 'movies'),
    ],
  ),
  LessonCategory(
    id: 'books',
    emoji: '📚',
    name: 'Books',
    blurb: 'Reading, writing, and learning.',
    icon: Icons.menu_book_outlined,
    lessons: [
      Lesson(id: 'unit_019', title: 'Books', subtitle: 'Nwoma', asset: 'assets/content/unit_019.json', categoryId: 'books'),
    ],
  ),
  LessonCategory(
    id: 'occasions',
    emoji: '🎉',
    name: 'Special Occasions',
    blurb: 'Birthdays, Christmas, weddings, and funerals.',
    icon: Icons.celebration_outlined,
    lessons: [
      Lesson(id: 'unit_021', title: 'Celebrations', subtitle: 'Afahyɛ', asset: 'assets/content/unit_021.json', categoryId: 'occasions'),
      Lesson(id: 'unit_022', title: 'Weddings', subtitle: 'Ayeforɔhyia', asset: 'assets/content/unit_022.json', categoryId: 'occasions'),
      Lesson(id: 'unit_023', title: 'Funerals & Condolences', subtitle: 'Ayie', asset: 'assets/content/unit_023.json', categoryId: 'occasions'),
    ],
  ),
  LessonCategory(
    id: 'heritage',
    emoji: '🌳',
    name: 'Heritage & Lineage',
    blurb: 'Abusua, personhood, and Akan cosmology.',
    icon: Icons.account_tree_outlined,
    lessons: [
      Lesson(id: 'unit_001', title: 'Lineage & the Akan Person', subtitle: 'Abusua ne Onipa', asset: 'assets/content/unit_001.example.json', categoryId: 'heritage'),
    ],
  ),
];

/// Global order — defines unlock sequence and "next lesson".
final List<Lesson> kLessonsFlat = [
  for (final c in kCategories) ...c.lessons,
];

Lesson? nextLessonAfter(String lessonId) {
  final i = kLessonsFlat.indexWhere((l) => l.id == lessonId);
  if (i < 0 || i + 1 >= kLessonsFlat.length) return null;
  return kLessonsFlat[i + 1];
}
