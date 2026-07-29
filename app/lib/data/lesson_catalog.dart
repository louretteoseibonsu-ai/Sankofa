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
///
/// Landmark ("boss zone") metadata is optional: most categories are ordinary
/// stops, but the four blueprint zones (Welcome Mat, Makola Market, Tro Tro,
/// Kitchen) — plus the Heritage capstone — carry a [zoneTheme] road palette,
/// a [landmarkName], a [bossName] challenge, and a [bossArtifact] reward.
class LessonCategory {
  final String id;
  final String name;
  final String emoji;
  final String blurb;
  final IconData icon;
  final List<Lesson> lessons;

  /// Map road/palette theme for this region ('' = default kente road).
  final String zoneTheme;

  /// Named landmark zone from the World Map blueprint ('' = ordinary stop).
  final String landmarkName;

  /// The final "Boss Challenge" label for a landmark zone.
  final String bossName;

  /// The Cultural Artifact / Power-Up unlocked by clearing the zone.
  final String bossArtifact;

  const LessonCategory({
    required this.id,
    required this.name,
    this.emoji = '',
    required this.blurb,
    required this.icon,
    required this.lessons,
    this.zoneTheme = '',
    this.landmarkName = '',
    this.bossName = '',
    this.bossArtifact = '',
  });

  /// True when this category is a named landmark ("boss zone").
  bool get isLandmark => landmarkName.isNotEmpty;
}

// ── The "Sankofa Twi" World Map (Act order: foundation → outward) ──────────
// Declaration order mirrors the four Acts (kCourses below) so every screen —
// map, lesson list, dashboard — reads the same logical progression. Numbers
// now sits in Act 1 (Foundations) where the curriculum needs it, before the
// market. kLessonsFlat is built FROM kCourses so the two can never drift.
const List<LessonCategory> kCategories = [
  // ─────────────────────────── ACT 1 · FOUNDATIONS ──────────────────────────
  LessonCategory(
    id: 'alphabet',
    emoji: '🔤',
    name: 'The Twi Alphabet',
    blurb: 'Letters, vowels, and the sounds English misses.',
    icon: Icons.abc,
    zoneTheme: 'village_gate',
    lessons: [
      Lesson(id: 'unit_065', title: 'The Twi Alphabet & Sounds', subtitle: 'Nsɛmfua', asset: 'assets/content/unit_065.json', categoryId: 'alphabet'),
    ],
  ),
  LessonCategory(
    id: 'greetings',
    emoji: '👋🏾',
    name: 'Foundations · Greetings',
    blurb: 'The first words that open every door.',
    icon: Icons.waving_hand_outlined,
    zoneTheme: 'village_compound',
    landmarkName: 'The Welcome Mat',
    bossName: "The Elder's Doorstep",
    bossArtifact: 'Akwaaba Mat',
    lessons: [
      Lesson(id: 'unit_002', title: 'Greetings', subtitle: 'Nkyea', asset: 'assets/content/unit_002.json', categoryId: 'greetings'),
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
      Lesson(id: 'unit_006', title: 'Numbers 21–39', subtitle: 'Aduonu – Aduasa nkron', asset: 'assets/content/unit_006.json', categoryId: 'numbers'),
      // The tens (40–100) + the pattern to build any number — no need to drill
      // every value once 1–30 and the compounding rule are known.
      Lesson(id: 'unit_007', title: 'Tens: 40–100', subtitle: 'Aduanan – Ɔha', asset: 'assets/content/unit_007.json', categoryId: 'numbers'),
    ],
  ),
  LessonCategory(
    id: 'grammar',
    emoji: '🔤',
    name: 'Foundations · Grammar',
    blurb: 'Build sentences: present, past, future & conjugation.',
    icon: Icons.school_outlined,
    lessons: [
      Lesson(id: 'unit_024', title: 'Tenses & Conjugation', subtitle: 'Mmerɛ', asset: 'assets/content/unit_024.json', categoryId: 'grammar'),
      Lesson(id: 'unit_025', title: 'Negatives', subtitle: 'Daabi', asset: 'assets/content/unit_025.json', categoryId: 'grammar'),
      Lesson(id: 'unit_026', title: 'Asking Questions', subtitle: 'Nsɛmmisa', asset: 'assets/content/unit_026.json', categoryId: 'grammar'),
      Lesson(id: 'unit_027', title: 'Possessives', subtitle: 'Me, Wo, Ne', asset: 'assets/content/unit_027.json', categoryId: 'grammar'),
      Lesson(id: 'unit_028', title: 'Everyday Verbs', subtitle: 'Adeyɛ', asset: 'assets/content/unit_028.json', categoryId: 'grammar'),
    ],
  ),

  // ────────────────────────── ACT 2 · EVERYDAY LIFE ──────────────────────────
  // The city adventure: market → transit hub → home kitchen.
  LessonCategory(
    id: 'shopping',
    emoji: '🛍️',
    name: 'Shopping & Money',
    blurb: 'Markets, prices, clothes, and bargaining.',
    icon: Icons.shopping_bag_outlined,
    zoneTheme: 'city_center',
    landmarkName: 'The Makola Market Hustle',
    bossName: 'The Haggle-Off',
    bossArtifact: 'Haggling Pro',
    lessons: [
      Lesson(id: 'unit_032', title: 'At the Market', subtitle: 'Gua', asset: 'assets/content/unit_032.json', categoryId: 'shopping'),
      Lesson(id: 'unit_033', title: 'Shopping', subtitle: 'Adetɔ', asset: 'assets/content/unit_033.json', categoryId: 'shopping'),
      Lesson(id: 'unit_034', title: 'Money & Prices', subtitle: 'Sika', asset: 'assets/content/unit_034.json', categoryId: 'shopping'),
      Lesson(id: 'unit_035', title: 'Clothing', subtitle: 'Ntadeɛ', asset: 'assets/content/unit_035.json', categoryId: 'shopping'),
    ],
  ),
  LessonCategory(
    id: 'travel',
    emoji: '✈️',
    name: 'Travel & Getting Around',
    blurb: 'Directions, transport, and going places.',
    icon: Icons.flight_takeoff_outlined,
    zoneTheme: 'transit_hub',
    landmarkName: 'Tro Tro Commuter Talk',
    bossName: 'The Rush-Hour Run',
    bossArtifact: 'Golden Horn',
    lessons: [
      Lesson(id: 'unit_017', title: 'Travel', subtitle: 'Akwantuo', asset: 'assets/content/unit_017.json', categoryId: 'travel'),
      Lesson(id: 'unit_038', title: 'Directions', subtitle: 'Akwankyerɛ', asset: 'assets/content/unit_038.json', categoryId: 'travel'),
      Lesson(id: 'unit_039', title: 'Transport (Trotro)', subtitle: 'Trɔtrɔ', asset: 'assets/content/unit_039.json', categoryId: 'travel'),
    ],
  ),
  LessonCategory(
    id: 'dining',
    emoji: '🍲',
    name: 'Food & Drink',
    blurb: 'Order, cook, and ask for what you need.',
    icon: Icons.restaurant_outlined,
    zoneTheme: 'family_kitchen',
    landmarkName: 'Kitchen Wisdom',
    bossName: "Grandma's Kitchen",
    bossArtifact: 'Nkwan Ladle',
    lessons: [
      Lesson(id: 'unit_016', title: 'Dining Out', subtitle: 'Adidie', asset: 'assets/content/unit_016.json', categoryId: 'dining'),
      Lesson(id: 'unit_029', title: 'Food & Ingredients', subtitle: 'Nnuane', asset: 'assets/content/unit_029.json', categoryId: 'dining'),
      Lesson(id: 'unit_030', title: 'Drinks', subtitle: 'Anonneɛ', asset: 'assets/content/unit_030.json', categoryId: 'dining'),
      Lesson(id: 'unit_031', title: 'Cooking', subtitle: 'Noa', asset: 'assets/content/unit_031.json', categoryId: 'dining'),
    ],
  ),
  LessonCategory(
    id: 'hobbies',
    emoji: '⚽',
    name: 'Hobbies & Games',
    blurb: 'Play, sport, and things you love to do.',
    icon: Icons.sports_esports_outlined,
    lessons: [
      Lesson(id: 'unit_015', title: 'Hobbies', subtitle: 'Anigyedeɛ', asset: 'assets/content/unit_015.json', categoryId: 'hobbies'),
      Lesson(id: 'unit_036', title: 'Sports', subtitle: 'Agodie', asset: 'assets/content/unit_036.json', categoryId: 'hobbies'),
      Lesson(id: 'unit_037', title: 'Games', subtitle: 'Agorɔ', asset: 'assets/content/unit_037.json', categoryId: 'hobbies'),
    ],
  ),
  LessonCategory(
    id: 'dailylife',
    emoji: '🌤️',
    name: 'Daily Life',
    blurb: 'Weather, time, and your everyday routine.',
    icon: Icons.wb_cloudy_outlined,
    lessons: [
      Lesson(id: 'unit_040', title: 'Weather', subtitle: 'Ewiem', asset: 'assets/content/unit_040.json', categoryId: 'dailylife'),
      Lesson(id: 'unit_041', title: 'Daily Routine & Time', subtitle: 'Da biara', asset: 'assets/content/unit_041.json', categoryId: 'dailylife'),
    ],
  ),

  // ───────────────────────── ACT 3 · PEOPLE & CULTURE ────────────────────────
  LessonCategory(
    id: 'family',
    emoji: '👨🏾‍👩🏾‍👧🏾',
    name: 'Family',
    blurb: 'The people closest to you.',
    icon: Icons.family_restroom_outlined,
    lessons: [
      Lesson(id: 'unit_004', title: 'Family Members', subtitle: 'Abusuafoɔ', asset: 'assets/content/unit_004.json', categoryId: 'family'),
      Lesson(id: 'unit_042', title: 'Extended Family', subtitle: 'Abusua', asset: 'assets/content/unit_042.json', categoryId: 'family'),
    ],
  ),
  LessonCategory(
    id: 'people',
    emoji: '🧑🏾',
    name: 'People',
    blurb: 'Describe people, feelings, and friendship.',
    icon: Icons.person_outline,
    lessons: [
      Lesson(id: 'unit_043', title: 'Describing People', subtitle: 'Nnipa', asset: 'assets/content/unit_043.json', categoryId: 'people'),
      Lesson(id: 'unit_044', title: 'Emotions & Feelings', subtitle: 'Atenka', asset: 'assets/content/unit_044.json', categoryId: 'people'),
      Lesson(id: 'unit_045', title: 'Friendship', subtitle: 'Nnamfoɔ', asset: 'assets/content/unit_045.json', categoryId: 'people'),
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
    id: 'culture',
    emoji: '🪘',
    name: 'Culture & Custom',
    blurb: 'Respect, proverbs, Adinkra, naming, and belief.',
    icon: Icons.auto_stories_outlined,
    lessons: [
      Lesson(id: 'unit_046', title: 'Respect & Elders', subtitle: 'Obuo', asset: 'assets/content/unit_046.json', categoryId: 'culture'),
      Lesson(id: 'unit_047', title: 'Proverbs & Wisdom', subtitle: 'Mmɛ', asset: 'assets/content/unit_047.json', categoryId: 'culture'),
      Lesson(id: 'unit_048', title: 'Adinkra Meanings', subtitle: 'Adinkra', asset: 'assets/content/unit_048.json', categoryId: 'culture'),
      Lesson(id: 'unit_049', title: 'Naming & Day Names', subtitle: 'Kra din', asset: 'assets/content/unit_049.json', categoryId: 'culture'),
      Lesson(id: 'unit_050', title: 'Chieftaincy', subtitle: 'Ahenni', asset: 'assets/content/unit_050.json', categoryId: 'culture'),
      Lesson(id: 'unit_051', title: 'Spirituality', subtitle: 'Ɔsom', asset: 'assets/content/unit_051.json', categoryId: 'culture'),
    ],
  ),
  LessonCategory(
    id: 'heritage',
    emoji: '🌳',
    name: 'Heritage & Lineage',
    blurb: 'Abusua, personhood, and Akan cosmology.',
    icon: Icons.account_tree_outlined,
    zoneTheme: 'sacred_grove',
    landmarkName: 'The Sankofa Capstone',
    bossName: 'Return to the Source',
    bossArtifact: 'Sankofa Crown',
    lessons: [
      Lesson(id: 'unit_001', title: 'Lineage & the Akan Person', subtitle: 'Abusua ne Onipa', asset: 'assets/content/unit_001.example.json', categoryId: 'heritage'),
    ],
  ),

  // ────────────────────────── ACT 4 · ARTS & MEDIA ───────────────────────────
  LessonCategory(
    id: 'music',
    emoji: '🎵',
    name: 'Music & Dance',
    blurb: 'Songs, drums, instruments, and dancing.',
    icon: Icons.music_note_outlined,
    lessons: [
      Lesson(id: 'unit_020', title: 'Music', subtitle: 'Nnwom', asset: 'assets/content/unit_020.json', categoryId: 'music'),
      Lesson(id: 'unit_052', title: 'Instruments', subtitle: 'Nnwontodeɛ', asset: 'assets/content/unit_052.json', categoryId: 'music'),
      Lesson(id: 'unit_053', title: 'Drumming', subtitle: 'Twene', asset: 'assets/content/unit_053.json', categoryId: 'music'),
      Lesson(id: 'unit_054', title: 'Dance', subtitle: 'Asaw', asset: 'assets/content/unit_054.json', categoryId: 'music'),
    ],
  ),
  LessonCategory(
    id: 'books',
    emoji: '📚',
    name: 'Literature & Stage',
    blurb: 'Stories, books, poetry, and theatre.',
    icon: Icons.menu_book_outlined,
    lessons: [
      Lesson(id: 'unit_019', title: 'Books', subtitle: 'Nwoma', asset: 'assets/content/unit_019.json', categoryId: 'books'),
      Lesson(id: 'unit_055', title: 'Storytelling', subtitle: 'Anansesɛm', asset: 'assets/content/unit_055.json', categoryId: 'books'),
      Lesson(id: 'unit_056', title: 'Poetry', subtitle: 'Anwonsɛm', asset: 'assets/content/unit_056.json', categoryId: 'books'),
      Lesson(id: 'unit_057', title: 'Theatre', subtitle: 'Agorɔdie', asset: 'assets/content/unit_057.json', categoryId: 'books'),
    ],
  ),
  LessonCategory(
    id: 'movies',
    emoji: '🎬',
    name: 'Screen & Broadcast',
    blurb: 'Movies, TV, radio, and the news.',
    icon: Icons.movie_outlined,
    lessons: [
      Lesson(id: 'unit_018', title: 'Movies', subtitle: 'Sini', asset: 'assets/content/unit_018.json', categoryId: 'movies'),
      Lesson(id: 'unit_058', title: 'Television', subtitle: 'Tiivii', asset: 'assets/content/unit_058.json', categoryId: 'movies'),
      Lesson(id: 'unit_059', title: 'Radio', subtitle: 'Radio', asset: 'assets/content/unit_059.json', categoryId: 'movies'),
      Lesson(id: 'unit_060', title: 'News', subtitle: 'Amanneɛbɔ', asset: 'assets/content/unit_060.json', categoryId: 'movies'),
    ],
  ),
  LessonCategory(
    id: 'visualarts',
    emoji: '🎨',
    name: 'Visual Arts',
    blurb: 'Photography, kente, craft, and social media.',
    icon: Icons.palette_outlined,
    lessons: [
      Lesson(id: 'unit_061', title: 'Photography', subtitle: 'Mfoni', asset: 'assets/content/unit_061.json', categoryId: 'visualarts'),
      Lesson(id: 'unit_062', title: 'Kente & Cloth', subtitle: 'Kente', asset: 'assets/content/unit_062.json', categoryId: 'visualarts'),
      Lesson(id: 'unit_063', title: 'Visual Art', subtitle: 'Adwinneɛ', asset: 'assets/content/unit_063.json', categoryId: 'visualarts'),
      Lesson(id: 'unit_064', title: 'Social Media', subtitle: 'Intanɛt', asset: 'assets/content/unit_064.json', categoryId: 'visualarts'),
    ],
  ),
];

/// Quick lookup by id.
LessonCategory categoryById(String id) =>
    kCategories.firstWhere((c) => c.id == id);

// ── Structured Courses (the four Acts) ──────────────────────────────────────
/// A course is a named track ("Act") that groups several categories into a
/// coherent learning journey. Categories (and their lessons) remain the unit of
/// study; courses define the world-map ORDER — kLessonsFlat is built from them.
class Course {
  final String id;
  final String name;
  final String blurb;
  final IconData icon;
  final List<String> categoryIds;
  const Course({
    required this.id,
    required this.name,
    required this.blurb,
    required this.icon,
    required this.categoryIds,
  });

  List<LessonCategory> get categories => [
        for (final id in categoryIds)
          kCategories.firstWhere((c) => c.id == id),
      ];

  List<Lesson> get lessons => [for (final c in categories) ...c.lessons];
}

const List<Course> kCourses = [
  Course(
    id: 'foundations',
    name: 'Foundations',
    blurb: 'Greetings, numbers and grammar — the bedrock of Twi.',
    icon: Icons.foundation_outlined,
    categoryIds: ['alphabet', 'greetings', 'numbers', 'grammar'],
  ),
  Course(
    id: 'everyday',
    name: 'Everyday Life',
    blurb: 'The city adventure — market, transit, kitchen, and more.',
    icon: Icons.wb_sunny_outlined,
    categoryIds: ['shopping', 'travel', 'dining', 'hobbies', 'dailylife'],
  ),
  Course(
    id: 'people',
    name: 'People & Culture',
    blurb: 'Family, love, occasions and Akan heritage.',
    icon: Icons.diversity_3_outlined,
    categoryIds: [
      'family',
      'people',
      'dating',
      'occasions',
      'culture',
      'heritage'
    ],
  ),
  Course(
    id: 'arts',
    name: 'Arts & Media',
    blurb: 'Music, stories, screen, and visual arts in Twi.',
    icon: Icons.palette_outlined,
    categoryIds: ['music', 'books', 'movies', 'visualarts'],
  ),
];

/// Global order — defines the world-map sequence, unlock order and "next
/// lesson". Built from the four Acts so the map, unlock gate and course
/// overview can never drift apart.
final List<Lesson> kLessonsFlat = [
  for (final course in kCourses)
    for (final category in course.categories) ...category.lessons,
];

Lesson? nextLessonAfter(String lessonId) {
  final i = kLessonsFlat.indexWhere((l) => l.id == lessonId);
  if (i < 0 || i + 1 >= kLessonsFlat.length) return null;
  return kLessonsFlat[i + 1];
}
