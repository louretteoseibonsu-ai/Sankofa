import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/lesson_catalog.dart';
import '../data/trotro_cosmetics.dart';

/// Score (out of 10) needed to pass a lesson and unlock the next.
const int kPassScore = 6;

class Progress {
  final Map<String, int> best; // lessonId -> best correct (0..10)
  const Progress(this.best);

  static const empty = Progress({});

  int get totalXp => best.values.fold(0, (a, b) => a + b * 10);
  int get level => 1 + totalXp ~/ 100;
  int get xpIntoLevel => totalXp % 100;
  int get xpForNextLevel => 100;

  bool passed(String id) => (best[id] ?? 0) >= kPassScore;

  bool unlocked(String id) {
    final i = kLessonsFlat.indexWhere((l) => l.id == id);
    if (i <= 0) return true; // first lesson always open
    return passed(kLessonsFlat[i - 1].id);
  }

  /// 0–3 star rating for a stop, from the best score (Mario-style mastery).
  /// 0 = not yet cleared, 1 = passed, 2 = strong, 3 = perfect.
  int stars(String id) => _starsFor(best[id] ?? 0);

  /// Total stars earned across all lessons (0..3 each).
  int get totalStars =>
      best.keys.fold(0, (a, id) => a + _starsFor(best[id] ?? 0));

  /// 0..1 mastery for a category (average best across its lessons).
  double categoryMastery(LessonCategory c) {
    if (c.lessons.isEmpty) return 0;
    final got = c.lessons.fold<int>(0, (a, l) => a + (best[l.id] ?? 0));
    return got / (c.lessons.length * 10);
  }

  /// A map region (category) opens when the previous region reaches the
  /// mastery threshold — the "boss unlocks the next world" gate.
  bool sectionUnlocked(int categoryIndex) {
    if (categoryIndex <= 0) return true; // first region always open
    return categoryMastery(kCategories[categoryIndex - 1]) >=
        kSectionUnlockThreshold;
  }
}

/// Fraction of a region that must be mastered to unlock the next one.
const double kSectionUnlockThreshold = 0.8;

/// Star rating (0–3) for a lesson's best score.
int _starsFor(int score) {
  if (score >= 10) return 3;
  if (score >= 8) return 2;
  if (score >= kPassScore) return 1;
  return 0;
}

/// Full gamification snapshot for the Progress dashboard.
class Stats {
  final Progress progress;
  final int streak;
  final int freezes;
  final int dailyLessons;
  final int dailyXp;
  final bool dailyPerfect;
  final int keys; // wisdom keys earned from combos (3 open a chest)
  final bool premium;
  final int pedis; // soft currency
  final int shards; // Golden Kente shards — mastery currency for cosmetics
  final bool practicedToday; // has the user studied today? (fuel topped up)
  const Stats({
    required this.progress,
    required this.streak,
    required this.freezes,
    required this.dailyLessons,
    required this.dailyXp,
    required this.dailyPerfect,
    required this.keys,
    required this.premium,
    required this.pedis,
    this.shards = 0,
    this.practicedToday = false,
  });

  /// The streak exists but today's fuel hasn't been topped up yet — a gentle
  /// "come back today" signal (never a hard block).
  bool get streakAtRisk => streak > 0 && !practicedToday;

  static const empty = Stats(
    progress: Progress.empty,
    streak: 0,
    freezes: 1,
    dailyLessons: 0,
    dailyXp: 0,
    dailyPerfect: false,
    keys: 0,
    premium: false,
    pedis: 0,
  );

  int get lessonsCompleted =>
      progress.best.values.where((v) => v >= kPassScore).length;
  int get perfectLessons => progress.best.values.where((v) => v == 10).length;
  int get wordsLearned => lessonsCompleted * 10; // ~10 glossary words / unit
}

String _dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class LeaderboardEntry {
  final String uid;
  final String name;
  final String? photoURL;
  final int xp;
  final int level;
  final bool isBot;
  const LeaderboardEntry({
    required this.uid,
    required this.name,
    this.photoURL,
    required this.xp,
    required this.level,
    this.isBot = false,
  });
}

/// Artificial players so a new leaderboard feels alive. They blend into the
/// rankings client-side and never write to Firestore.
class _Ghost {
  final String name;
  final String glyph;
  final String hex;
  final int xp;
  final int weeklyXp;
  const _Ghost(this.name, this.glyph, this.hex, this.xp, this.weeklyXp);
}

// XP is spread low→high so a real beginner (~100–200 XP) lands mid-pack,
// not dead last. Roughly half the bots sit below a typical starter score.
const List<_Ghost> _kGhosts = [
  _Ghost('Kwame Mensah', 'gyenyame', 'E2725B', 560, 240),
  _Ghost('Ama Owusu', 'sankofa', '2E6B3B', 480, 210),
  _Ghost('Yaw Boateng', 'dwennimmen', 'E3A92C', 400, 180),
  _Ghost('Akosua Sarpong', 'akoma', '9B2D2A', 320, 150),
  _Ghost('Kojo Asante', 'nyame_dua', '5A5E63', 260, 130),
  _Ghost('Abena Frimpong', 'gyenyame', '2B2B2D', 210, 110),
  _Ghost('Kwabena Osei', 'sankofa', 'E3A92C', 175, 90),
  _Ghost('Esi Adjei', 'dwennimmen', 'E2725B', 145, 70),
  _Ghost('Yaa Danso', 'akoma', '2E6B3B', 120, 55),
  _Ghost('Kofi Appiah', 'nyame_dua', '9B2D2A', 100, 40),
  _Ghost('Adwoa Ofori', 'gyenyame', '5A5E63', 70, 25),
  _Ghost('Fiifi Quaye', 'sankofa', '2B2B2D', 40, 15),
];

List<LeaderboardEntry> _withGhosts(
  List<LeaderboardEntry> real, {
  required bool weekly,
  required int limit,
}) {
  final ghosts = _kGhosts.map((g) {
    final xp = weekly ? g.weeklyXp : g.xp;
    return LeaderboardEntry(
      uid: 'ghost_${g.name}',
      name: g.name,
      photoURL: 'adinkra://${g.glyph}/${g.hex}',
      xp: xp,
      level: 1 + xp ~/ 100,
      isBot: true,
    );
  });
  final all = [...real, ...ghosts]..sort((a, b) => b.xp.compareTo(a.xp));
  return all.take(limit).toList();
}

class ProgressService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _uid => _auth.currentUser?.uid;

  Future<Progress> load() async {
    final uid = _uid;
    if (uid == null) return Progress.empty;
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data() ?? {};
    final raw = (data['lessonBest'] as Map?)?.cast<String, dynamic>() ?? {};
    final best =
        raw.map((k, v) => MapEntry(k, (v as num).toInt()));
    return Progress(best);
  }

  /// Reads the full gamification snapshot for the Progress dashboard.
  Future<Stats> loadStats() async {
    final uid = _uid;
    if (uid == null) return Stats.empty;
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data() ?? {};
    final raw = (data['lessonBest'] as Map?)?.cast<String, dynamic>() ?? {};
    final best = raw.map((k, v) => MapEntry(k, (v as num).toInt()));

    final today = _dayKey(DateTime.now());
    final yesterday =
        _dayKey(DateTime.now().subtract(const Duration(days: 1)));
    final lastActive = data['lastActive'] as String?;
    var streak = (data['streak'] as num?)?.toInt() ?? 0;
    if (lastActive != today && lastActive != yesterday) streak = 0; // lapsed

    final isToday = (data['dailyDate'] as String?) == today;
    return Stats(
      progress: Progress(best),
      streak: streak,
      freezes: (data['freezes'] as num?)?.toInt() ?? 1,
      dailyLessons: isToday ? (data['dailyLessons'] as num?)?.toInt() ?? 0 : 0,
      dailyXp: isToday ? (data['dailyXp'] as num?)?.toInt() ?? 0 : 0,
      dailyPerfect: isToday ? (data['dailyPerfect'] as bool?) ?? false : false,
      keys: (data['keys'] as num?)?.toInt() ?? 0,
      premium: (data['premium'] as bool?) ?? false,
      pedis: (data['pedis'] as num?)?.toInt() ?? 0,
      shards: (data['shards'] as num?)?.toInt() ?? 0,
      practicedToday: lastActive == today,
    );
  }

  /// Cost in pedis to buy one streak freeze.
  static const int kFreezeCost = 50;

  /// Spends pedis to buy a streak freeze. Returns true on success.
  Future<bool> buyFreezeWithPedis() async {
    final uid = _uid;
    if (uid == null) return false;
    final doc = await _db.collection('users').doc(uid).get();
    final pedis = (doc.data()?['pedis'] as num?)?.toInt() ?? 0;
    if (pedis < kFreezeCost) return false;
    await _db.collection('users').doc(uid).set({
      'pedis': FieldValue.increment(-kFreezeCost),
      'freezes': FieldValue.increment(1),
    }, SetOptions(merge: true));
    return true;
  }

  /// Passages the learner has passed comprehension on (unlocks the next).
  Future<Set<String>> loadReadingPassed() async {
    final uid = _uid;
    if (uid == null) return {};
    final doc = await _db.collection('users').doc(uid).get();
    final list = (doc.data()?['readingPassed'] as List?)?.cast<String>() ?? [];
    return list.toSet();
  }

  /// Marks a reading passage as passed. Returns true the first time (and grants
  /// a small pedi reward); false if it was already passed.
  Future<bool> markReadingPassed(String id) async {
    final uid = _uid;
    if (uid == null) return false;
    final ref = _db.collection('users').doc(uid);
    final doc = await ref.get();
    final list = (doc.data()?['readingPassed'] as List?)?.cast<String>() ?? [];
    if (list.contains(id)) return false;
    await ref.set({
      'readingPassed': FieldValue.arrayUnion([id]),
      'pedis': FieldValue.increment(5),
    }, SetOptions(merge: true));
    return true;
  }

  // ── Tro tro cosmetics (the Garage) ──────────────────────────────────────

  /// Loads the user's owned + equipped cosmetics (defaults always owned).
  Future<CosmeticState> loadCosmetics() async {
    final uid = _uid;
    if (uid == null) return CosmeticState({...kDefaultOwned}, {});
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data() ?? {};
    final owned = {
      ...kDefaultOwned,
      ...((data['cosmeticsOwned'] as List?)?.cast<String>() ?? const [])
    };
    final eqRaw =
        (data['cosmeticEquipped'] as Map?)?.cast<String, dynamic>() ?? {};
    final equipped = eqRaw.map((k, v) => MapEntry(k, v.toString()));
    return CosmeticState(owned, equipped);
  }

  /// Spends shards to buy [item], then auto-equips it. Returns false if the
  /// user can't afford it. Defaults (cost 0) never need buying.
  Future<bool> buyCosmetic(ShopItem item) async {
    final uid = _uid;
    if (uid == null) return false;
    if (item.isDefault) {
      await equipCosmetic(item.category, item.id);
      return true;
    }
    final ref = _db.collection('users').doc(uid);
    final doc = await ref.get();
    final shards = (doc.data()?['shards'] as num?)?.toInt() ?? 0;
    if (shards < item.costShards) return false;
    await ref.set({
      'shards': FieldValue.increment(-item.costShards),
      'cosmeticsOwned': FieldValue.arrayUnion([item.id]),
      'cosmeticEquipped': {item.category: item.id}, // deep-merged
    }, SetOptions(merge: true));
    return true;
  }

  /// Equips an already-owned cosmetic in its category.
  Future<void> equipCosmetic(String category, String id) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).set({
      'cosmeticEquipped': {category: id},
    }, SetOptions(merge: true));
  }

  /// Credits pedis (used by the consumable IAP "buy pedis" flow — stub).
  Future<void> addPedis(int amount) async {
    final uid = _uid;
    if (uid == null || amount <= 0) return;
    await _db.collection('users').doc(uid).set(
        {'pedis': FieldValue.increment(amount)}, SetOptions(merge: true));
  }

  /// Opens a treasure chest if the user has ≥3 wisdom keys. Spends 3 keys and
  /// grants 1–2 streak freezes. Returns the reward, or null if not enough keys.
  Future<int?> openChest() async {
    final uid = _uid;
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).get();
    final keys = (doc.data()?['keys'] as num?)?.toInt() ?? 0;
    if (keys < 3) return null;
    final reward = DateTime.now().millisecond % 10 < 3 ? 2 : 1; // 30% → 2
    await _db.collection('users').doc(uid).set({
      'keys': FieldValue.increment(-3),
      'freezes': FieldValue.increment(reward),
    }, SetOptions(merge: true));
    return reward;
  }

  /// Records an attempt (keeps the best per lesson), updates XP, streak,
  /// daily quests, and the public leaderboards. Returns the updated progress.
  Future<Progress> recordResult(String lessonId, int correct,
      {int keysEarned = 0}) async {
    final uid = _uid;
    if (uid == null) return Progress.empty;
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data() ?? {};
    final raw = (data['lessonBest'] as Map?)?.cast<String, dynamic>() ?? {};
    final best = raw.map((k, v) => MapEntry(k, (v as num).toInt()));
    final oldScore = best[lessonId] ?? 0;
    final oldXp = Progress(best).totalXp;
    if (correct > oldScore) best[lessonId] = correct;
    final newScore = best[lessonId] ?? 0;
    final updated = Progress(best);
    final delta = updated.totalXp - oldXp; // XP newly earned now

    // Golden Kente shards: awarded only for NEW stars (not farmable by
    // replay), with a bonus for a first-time 3-star (perfect) clear.
    final oldStars = _starsFor(oldScore);
    final newStars = _starsFor(newScore);
    int shardsEarned = (newStars - oldStars).clamp(0, 3).toInt();
    if (newStars == 3 && oldStars < 3) shardsEarned += 2;

    final user = _auth.currentUser;
    final name = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : (user?.email?.split('@').first ?? 'Learner');

    // ── Streak ──
    final today = _dayKey(DateTime.now());
    final yesterday =
        _dayKey(DateTime.now().subtract(const Duration(days: 1)));
    final lastActive = data['lastActive'] as String?;
    var streak = (data['streak'] as num?)?.toInt() ?? 0;
    if (lastActive == today) {
      if (streak == 0) streak = 1;
    } else if (lastActive == yesterday) {
      streak += 1;
    } else {
      streak = 1;
    }

    // ── Daily quests ──
    final sameDay = (data['dailyDate'] as String?) == today;
    final dailyLessons =
        (sameDay ? (data['dailyLessons'] as num?)?.toInt() ?? 0 : 0) + 1;
    final dailyXp =
        (sameDay ? (data['dailyXp'] as num?)?.toInt() ?? 0 : 0) +
            (delta > 0 ? delta : 0);
    final dailyPerfect =
        (sameDay ? (data['dailyPerfect'] as bool?) ?? false : false) ||
            correct == 10;

    await _db.collection('users').doc(uid).set({
      'lessonBest': best,
      'xp': updated.totalXp,
      'level': updated.level,
      'streak': streak,
      'lastActive': today,
      'dailyDate': today,
      'dailyLessons': dailyLessons,
      'dailyXp': dailyXp,
      'dailyPerfect': dailyPerfect,
      'keys': FieldValue.increment(keysEarned),
      // Earn pedis: 5 per lesson + 5 per combo key bonus.
      'pedis': FieldValue.increment(5 + keysEarned * 5),
      'shards': FieldValue.increment(shardsEarned),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Public all-time leaderboard doc — name + xp + avatar only.
    await _db.collection('leaderboard').doc(uid).set({
      'name': name,
      'photoURL': user?.photoURL,
      'xp': updated.totalXp,
      'level': updated.level,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Weekly board: accumulate XP earned within the current ISO week.
    if (delta > 0) {
      final week = _weekKey(DateTime.now());
      await _db
          .collection('leaderboard_weekly')
          .doc(week)
          .collection('users')
          .doc(uid)
          .set({
        'name': name,
        'photoURL': user?.photoURL,
        'xp': FieldValue.increment(delta),
        'level': updated.level,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    return updated;
  }

  /// ISO-8601 week key, e.g. "2026-W26".
  static String _weekKey(DateTime date) {
    final d = DateTime.utc(date.year, date.month, date.day);
    final thursday = d.add(Duration(days: 3 - ((d.weekday + 6) % 7)));
    final week1 = DateTime.utc(thursday.year, 1, 1);
    final weekNum = 1 + (thursday.difference(week1).inDays / 7).floor();
    return '${thursday.year}-W${weekNum.toString().padLeft(2, '0')}';
  }

  /// Top learners for the current week (for the home-screen strip).
  Stream<List<LeaderboardEntry>> weeklyTop({int limit = 3}) {
    final week = _weekKey(DateTime.now());
    return _db
        .collection('leaderboard_weekly')
        .doc(week)
        .collection('users')
        .orderBy('xp', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) {
      final real = s.docs.map((d) {
        final m = d.data();
        return LeaderboardEntry(
          uid: d.id,
          name: (m['name'] ?? 'Learner') as String,
          photoURL: m['photoURL'] as String?,
          xp: (m['xp'] as num?)?.toInt() ?? 0,
          level: (m['level'] as num?)?.toInt() ?? 1,
        );
      }).toList();
      return _withGhosts(real, weekly: true, limit: limit);
    });
  }

  Stream<List<LeaderboardEntry>> leaderboard({int limit = 50}) {
    return _db
        .collection('leaderboard')
        .orderBy('xp', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) {
      final real = s.docs.map((d) {
        final m = d.data();
        return LeaderboardEntry(
          uid: d.id,
          name: (m['name'] ?? 'Learner') as String,
          photoURL: m['photoURL'] as String?,
          xp: (m['xp'] as num?)?.toInt() ?? 0,
          level: (m['level'] as num?)?.toInt() ?? 1,
        );
      }).toList();
      return _withGhosts(real, weekly: false, limit: limit);
    });
  }
}
