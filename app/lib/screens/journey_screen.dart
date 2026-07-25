import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/lesson_catalog.dart';
import '../data/trotro_cosmetics.dart';
import '../services/progress_service.dart';
import '../services/sound_service.dart';
import '../theme.dart';
import '../widgets/celebration.dart';
import '../widgets/composable_trotro.dart';
import '../widgets/greeting.dart';
import '../widgets/mascot.dart';
import '../widgets/overlay_flight.dart';
import '../widgets/skeleton.dart';
import '../widgets/state_message.dart';
import '../widgets/tappable_scale.dart';
import '../widgets/tintable_trotro.dart';
import '../widgets/trotro_mascot.dart';
import 'customization_shop_screen.dart';
import 'reading_screen.dart';
import 'dialogue_boss_screen.dart';
import 'lesson_quiz_screen.dart';
import 'time_attack_screen.dart';

// Road / map palette.
const Color _roadActive = Color(0xFFBE5235); // travelled — vibrant terracotta
const Color _roadGold = Color(0xFFE3A92C); // kente centre thread
const Color _roadMuted = Color(0xFFD9DCE0); // locked road ahead
const Color _mutedDot = Color(0xFFBFC2C7);
const Color _doneGreen = Color(0xFF2E6B3B);
const Color _lockGrey = Color(0xFF9AA0A6);

/// A travelled-road palette (base tarmac + centre kente thread) for a zone.
class _ZonePalette {
  final Color base;
  final Color thread;
  const _ZonePalette(this.base, this.thread);
}

const _ZonePalette _defaultZone = _ZonePalette(_roadActive, _roadGold);

// Landmark zones override with their own flavour; everything else inherits its
// Act's palette so the road shifts mood by Act rather than flickering per stop.
const Map<String, _ZonePalette> _zonePalettes = {
  'village_gate': _ZonePalette(Color(0xFFBE5235), Color(0xFFE3A92C)),
  'village_compound': _ZonePalette(Color(0xFFBE5235), Color(0xFFE3A92C)),
  'city_center': _ZonePalette(Color(0xFFC98A2B), Color(0xFFF0C36B)),
  'transit_hub': _ZonePalette(Color(0xFF3E7CA8), Color(0xFFF0C36B)),
  'family_kitchen': _ZonePalette(Color(0xFFC0553B), Color(0xFFF0C36B)),
  'sacred_grove': _ZonePalette(Color(0xFF2E6B3B), Color(0xFFE3A92C)),
};

// Act-level fallback palettes (by course id).
const Map<String, _ZonePalette> _actPalettes = {
  'foundations': _ZonePalette(Color(0xFFBE5235), Color(0xFFE3A92C)),
  'everyday': _ZonePalette(Color(0xFFC98A2B), Color(0xFFF0C36B)),
  'people': _ZonePalette(Color(0xFF7A4FB5), Color(0xFFE3A92C)),
  'arts': _ZonePalette(Color(0xFF1F7A8C), Color(0xFFF0C36B)),
};

// categoryId → course ("Act") id, precomputed from the catalog.
final Map<String, String> _categoryCourse = {
  for (final course in kCourses)
    for (final cid in course.categoryIds) cid: course.id,
};

/// Resolves the road palette for a category: its own zone theme if it is a
/// landmark, otherwise its Act's palette.
_ZonePalette _paletteForCategory(String categoryId) {
  final cat = categoryById(categoryId);
  final own = _zonePalettes[cat.zoneTheme];
  if (own != null) return own;
  return _actPalettes[_categoryCourse[categoryId]] ?? _defaultZone;
}

/// The Sankofa "world map" — a winding kente road through cultural regions.
/// The tro tro is the player's avatar: it parks at the current stop and drives
/// to the next one when a lesson is cleared. Regions unlock boss-by-boss.
class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key});

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen>
    with TickerProviderStateMixin {
  final _service = ProgressService();
  final GlobalKey _troKey = GlobalKey(); // the parked map bus
  final GlobalKey _garageKey = GlobalKey(); // the garage button (flight target)
  final GlobalKey _anansesemKey = GlobalKey(); // campfire button (flight target)
  final GlobalKey _warpNodeKey = GlobalKey(); // the stop we're warping into
  bool _flying = false; // hide the map bus while its clone is in flight
  int? _warpTarget; // stop index carrying _warpNodeKey during a region warp
  Progress _p = Progress.empty;
  Stats _stats = Stats.empty;
  bool _loading = true;

  int _displayIndex = 0;
  TroTroState _troState = TroTroState.idle;
  TroTroSkin _skin = const TroTroSkin(); // kept for the equipped horn sound
  Color _bodyColor = kTroTroBodyColors.first;
  Map<String, String> _equipped = const {}; // cosmetics for the layered avatar
  bool _firstLoad = true;
  bool _error = false; // set when the initial load fails (offline / no cache)

  // Boss = last stop of each region; region name keyed by category id.
  static final Set<String> _bossIds = {
    for (final c in kCategories)
      if (c.lessons.isNotEmpty) c.lessons.last.id
  };
  static final Map<String, String> _catName = {
    for (final c in kCategories) c.id: c.name
  };

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    Stats stats;
    CosmeticState cos;
    try {
      stats = await _service.loadStats();
      cos = await _service.loadCosmetics();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
      return;
    }
    if (!mounted) return;
    final p = stats.progress;
    final newCurrent = _currentIndexFor(p);
    final prev = _displayIndex;
    setState(() {
      _p = p;
      _stats = stats;
      _skin = TroTroSkin.fromEquipped(cos.equipped);
      _bodyColor = troTroBodyColorFor(cos.equipped);
      _equipped = cos.equipped;
      _loading = false;
      _error = false;
    });

    if (_firstLoad) {
      _firstLoad = false;
      setState(() => _displayIndex = newCurrent);
      return;
    }

    if (newCurrent > prev) {
      // Crossing into a NEW region (section unlock) gets the "warp" flourish —
      // the bus lifts off the road and arcs to the new stop. Advancing within
      // the same region keeps the grounded road-slide.
      final crossedRegion = kLessonsFlat[newCurrent].categoryId !=
          kLessonsFlat[prev].categoryId;
      if (crossedRegion && _troKey.currentContext != null) {
        await _warpToStop(newCurrent);
        return;
      }
      // Cleared a stop: drive up the road to the newly unlocked one.
      setState(() {
        _troState = TroTroState.drive;
        _displayIndex = newCurrent;
      });
      await Future.delayed(const Duration(milliseconds: 950));
      if (!mounted) return;
      setState(() => _troState = TroTroState.arrive);
      SoundService.instance.horn(_skin.horn); // equipped horn honks on arrival
      HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      setState(() => _troState = TroTroState.idle);
    } else {
      setState(() => _displayIndex = newCurrent);
    }
  }

  /// "Warp to the new stop": arcs a clone of the customised bus from its parked
  /// spot to the freshly unlocked region's stop via [OverlayFlight], then lands.
  Future<void> _warpToStop(int target) async {
    // Attach the flight-target key to the destination node and let it build.
    setState(() {
      _troState = TroTroState.idle;
      _warpTarget = target;
    });
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    await OverlayFlight.run(
      context: context,
      vsync: this,
      fromKey: _troKey,
      toKey: _warpNodeKey,
      endScale: 1.0,
      arcHeight: 46,
      duration: const Duration(milliseconds: 650),
      builder: (w) =>
          Mascot(bodyColor: _bodyColor, equipped: _equipped, width: w),
      onStart: () {
        HapticFeedback.selectionClick();
        setState(() => _flying = true); // hide the parked bus during flight
      },
    );
    if (!mounted) return;

    // Land: drop the clone, park the real bus at the new stop, honk.
    setState(() {
      _flying = false;
      _warpTarget = null;
      _displayIndex = target;
    });
    SoundService.instance.horn(_skin.horn);
    HapticFeedback.mediumImpact();

    // A new region is a real milestone — celebrate it by name.
    if (!mounted) return;
    final region = _catName[kLessonsFlat[target].categoryId] ?? 'a new region';
    await celebrateMilestone(
      context,
      headline: 'New region unlocked!',
      subline: 'Your tro tro just rolled into $region.',
    );
  }

  Future<void> _open(Lesson l) async {
    // A cleared, non-boss stop has "evolved" — offer Replay or Mastery.
    if (!_bossIds.contains(l.id) && _p.passed(l.id)) {
      await _openClearedSheet(l);
      return;
    }
    // Boss stops launch the Dialogue Boss Battle; everything else the lesson.
    final Widget dest = _bossIds.contains(l.id)
        ? DialogueBossScreen(lesson: l)
        : LessonQuizScreen(lesson: l);
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => dest));
    _reload();
  }

  Future<void> _openClearedSheet(Lesson l) async {
    final mastered = _stats.mastered.contains(l.id);
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(children: [
                Expanded(
                  child: Text(l.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: ink)),
                ),
                if (mastered)
                  const Icon(Icons.workspace_premium_rounded,
                      color: _roadGold, size: 22),
              ]),
            ),
            ListTile(
              leading: const Icon(Icons.replay_rounded, color: slate),
              title: const Text('Replay lesson'),
              subtitle: const Text('Practise again — improve your stars.'),
              onTap: () => Navigator.of(ctx).pop('replay'),
            ),
            ListTile(
              leading: const Icon(Icons.workspace_premium_rounded,
                  color: _roadGold),
              title: Text(
                  mastered ? 'Mastery Challenge · mastered' : 'Mastery Challenge'),
              subtitle: Text(mastered
                  ? 'Run it again for the thrill.'
                  : 'A perfect timed run earns bonus shards.'),
              onTap: () => Navigator.of(ctx).pop('mastery'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    final Widget dest = choice == 'mastery'
        ? TimeAttackScreen(lesson: l, mastery: true)
        : LessonQuizScreen(lesson: l);
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => dest));
    _reload();
  }

  /// Bus-fly to the campfire, then open the Anansesɛm folktale list.
  Future<void> _openAnansesem() async {
    if (_flying || _troKey.currentContext == null) {
      _pushAnansesem();
      return;
    }
    await OverlayFlight.run(
      context: context,
      vsync: this,
      fromKey: _troKey,
      toKey: _anansesemKey,
      endScale: 0.3,
      arcHeight: 80,
      builder: (w) =>
          Mascot(bodyColor: _bodyColor, equipped: _equipped, width: w),
      onStart: () {
        HapticFeedback.selectionClick();
        setState(() => _flying = true);
      },
    );
    if (!mounted) return;
    _pushAnansesem();
  }

  void _pushAnansesem() {
    Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (_) => const ReadingListScreen(folkloreOnly: true)))
        .then((_) {
      if (mounted) setState(() => _flying = false);
    });
  }

  /// Bus-fly into the Garage — powered by the reusable [OverlayFlight] helper.
  Future<void> _openGarage() async {
    if (_flying || _troKey.currentContext == null) {
      _pushGarage();
      return;
    }
    await OverlayFlight.run(
      context: context,
      vsync: this,
      fromKey: _troKey,
      toKey: _garageKey,
      endScale: 0.28, // shrink into the garage button
      arcHeight: 90,
      builder: (w) =>
          Mascot(bodyColor: _bodyColor, equipped: _equipped, width: w),
      onStart: () {
        HapticFeedback.selectionClick();
        setState(() => _flying = true); // hide the real bus during the flight
      },
    );
    if (!mounted) return;
    _pushGarage();
  }

  void _pushGarage() {
    Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (_) => CustomizationShopScreen(initialSkin: _skin)))
        .then((_) {
      if (mounted) setState(() => _flying = false);
      _reload();
    });
  }

  static int _currentIndexFor(Progress p) {
    final i =
        kLessonsFlat.indexWhere((l) => p.unlocked(l.id) && !p.passed(l.id));
    if (i != -1) return i;
    return kLessonsFlat.isEmpty ? 0 : kLessonsFlat.length - 1;
  }

  int get _currentIndex => _currentIndexFor(_p);

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _MapSkeleton();
    if (_error) {
      return StateMessage(
        icon: Icons.wifi_off_rounded,
        title: 'Couldn’t load your journey',
        subtitle: 'Check your connection and try again.',
        actionLabel: 'Retry',
        onAction: () {
          setState(() {
            _loading = true;
            _error = false;
          });
          _reload();
        },
      );
    }
    final lessons = kLessonsFlat;
    final n = lessons.length;
    final current = _currentIndex;
    final regionName = _catName[lessons[current].categoryId] ?? 'Journey';

    return Column(
      children: [
        // ── HUD overlay ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              _Pill(
                icon: Icons.monetization_on_rounded,
                iconColor: _roadGold,
                label: '${_stats.pedis}',
              ),
              const SizedBox(width: 8),
              _Pill(
                icon: Icons.local_fire_department_rounded,
                iconColor: _roadActive,
                label: '${_stats.streak}',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                            color: charcoal,
                            borderRadius: BorderRadius.circular(20)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.place_rounded,
                              color: _roadGold, size: 15),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(regionName,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ]),
                      ),
                    ),
                    IconButton(
                      key: _anansesemKey,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                      onPressed: _openAnansesem,
                      icon: const Icon(Icons.local_fire_department_rounded),
                      color: charcoal,
                      tooltip: 'Anansesɛm',
                    ),
                    IconButton(
                      key: _garageKey,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                      onPressed: _openGarage,
                      icon: const Icon(Icons.garage_rounded),
                      color: charcoal,
                      tooltip: 'Garage',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // ── World map ────────────────────────────────────────────────
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              const topPad = 56.0, spacing = 120.0, bottomPad = 80.0;
              final height = topPad + spacing * (n - 1) + bottomPad;
              Offset posOf(int i) => Offset(
                    i.isEven ? w * 0.30 : w * 0.70,
                    height - bottomPad - spacing * i, // stop 0 at the bottom
                  );
              final points = [for (int i = 0; i < n; i++) posOf(i)];
              final passedFlags = [
                for (int i = 0; i < n; i++) _p.passed(lessons[i].id)
              ];
              final zonePalettes = [
                for (int i = 0; i < n; i++)
                  _paletteForCategory(lessons[i].categoryId)
              ];

              return SingleChildScrollView(
                reverse: true, // start scrolled to the bottom (stop 0)
                // Bouncy, physical feel — the road has "give" (suspension).
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                child: SizedBox(
                  width: w,
                  height: height,
                  child: Stack(
                    children: [
                      CustomPaint(
                        size: Size(w, height),
                        painter: _RoadPainter(points, passedFlags, zonePalettes),
                      ),
                      // Goal marker at the top of the map
                      if (n > 0)
                        Positioned(
                          left: points.last.dx - 20,
                          top: points.last.dy - 78,
                          child: const Icon(Icons.emoji_events_rounded,
                              color: _roadGold, size: 40),
                        ),
                      // Region name tags at each region's first stop
                      for (int i = 0; i < n; i++)
                        if (i == 0 ||
                            lessons[i].categoryId != lessons[i - 1].categoryId)
                          Positioned(
                            left: points[i].dx < w / 2
                                ? points[i].dx + 34
                                : points[i].dx - 118,
                            top: points[i].dy - 12,
                            child: _RegionTag(
                            name: _catName[lessons[i].categoryId] ?? '',
                            unlocked: _p.unlocked(lessons[i].id),
                            landmark: categoryById(lessons[i].categoryId)
                                .landmarkName,
                            artifact: categoryById(lessons[i].categoryId)
                                .bossArtifact,
                          ),
                        ),
                      // Stars above cleared stops
                      for (int i = 0; i < n; i++)
                        if (i != _displayIndex && _p.passed(lessons[i].id))
                          Positioned(
                            left: points[i].dx - 24,
                            top: points[i].dy -
                                (_bossIds.contains(lessons[i].id) ? 52 : 46),
                            child: _StarRow(_p.stars(lessons[i].id)),
                          ),
                      // Mastery crown on mastered stops
                      for (int i = 0; i < n; i++)
                        if (i != _displayIndex &&
                            _stats.mastered.contains(lessons[i].id))
                          Positioned(
                            left: points[i].dx +
                                (_bossIds.contains(lessons[i].id) ? 20 : 14),
                            top: points[i].dy -
                                (_bossIds.contains(lessons[i].id) ? 34 : 30),
                            child: const Icon(Icons.workspace_premium_rounded,
                                color: _roadGold, size: 20),
                          ),
                      // Stops (hide the one under the tro tro)
                      for (int i = 0; i < n; i++)
                        if (i != _displayIndex)
                          Positioned(
                            left: points[i].dx -
                                (_bossIds.contains(lessons[i].id) ? 32 : 26),
                            top: points[i].dy -
                                (_bossIds.contains(lessons[i].id) ? 32 : 26),
                            child: _Node(
                              key: i == _warpTarget ? _warpNodeKey : null,
                              passed: _p.passed(lessons[i].id),
                              unlocked: _p.unlocked(lessons[i].id),
                              isBoss: _bossIds.contains(lessons[i].id),
                              onTap: _p.unlocked(lessons[i].id)
                                  ? () => _open(lessons[i])
                                  : null,
                            ),
                          ),
                      // The tro tro avatar
                      if (n > 0)
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeInOut,
                          left: points[_displayIndex].dx - 54,
                          top: points[_displayIndex].dy - 46,
                          width: 108,
                          height: 108 * 250 / 380,
                          child: GestureDetector(
                            onTap: () => _open(lessons[current]),
                            // Always the illustrated bus (parked, driving, or
                            // arriving) — it just leans forward while driving so
                            // the motion reads without swapping to a different
                            // art style.
                            child: Center(
                              child: Opacity(
                                opacity: _flying ? 0.0 : 1.0,
                                child: AnimatedRotation(
                                  turns: _troState == TroTroState.drive
                                      ? -0.02
                                      : 0.0,
                                  duration: const Duration(milliseconds: 260),
                                  curve: Curves.easeOut,
                                  child: Mascot(
                                      key: _troKey,
                                      bodyColor: _bodyColor,
                                      equipped: _equipped,
                                      width: 104),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // ── Current-stop card ────────────────────────────────────────
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: silverLight, width: 1.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _stats.streak > 0
                              ? '🔥 Day ${_stats.streak} · ${regionName.toUpperCase()}'
                              : '${_bossIds.contains(lessons[current].id) ? 'BOSS STOP' : 'STOP ${current + 1}'} · ${regionName.toUpperCase()}',
                          style: const TextStyle(
                              color: _roadActive,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6),
                        ),
                        const SizedBox(height: 2),
                        Text(lessons[current].title,
                            style: const TextStyle(
                                color: ink,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 1),
                        Text(
                          'Continue, ${firstNameOf(FirebaseAuth.instance.currentUser)}',
                          style: const TextStyle(color: slate, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (!_bossIds.contains(lessons[current].id))
                    IconButton(
                      onPressed: () async {
                        await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) =>
                                TimeAttackScreen(lesson: lessons[current])));
                        _reload();
                      },
                      icon: const Icon(Icons.bolt_rounded),
                      color: _roadGold,
                      tooltip: 'Time-Attack',
                    ),
                  const SizedBox(width: 6),
                  TappableScale(
                    onTap: () => _open(lessons[current]),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 13),
                      decoration: BoxDecoration(
                          color: terracottaDeep,
                          borderRadius: BorderRadius.circular(20)),
                      child: const Text('Play',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  const _Pill(
      {required this.icon, required this.iconColor, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: silverLight, width: 1.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: iconColor, size: 17),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                color: ink, fontSize: 13, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

class _StarRow extends StatelessWidget {
  final int count; // 0..3
  const _StarRow(this.count);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < 3; i++)
          Icon(i < count ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 16, color: i < count ? _roadGold : silver),
      ],
    );
  }
}

class _RegionTag extends StatelessWidget {
  final String name;
  final bool unlocked;
  final String landmark; // '' for ordinary regions
  final String artifact; // reward unlocked at a landmark's boss
  const _RegionTag({
    required this.name,
    required this.unlocked,
    this.landmark = '',
    this.artifact = '',
  });

  @override
  Widget build(BuildContext context) {
    final isLandmark = landmark.isNotEmpty;
    if (!isLandmark) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
            color: unlocked ? const Color(0xFFF7E6DF) : glyphTile,
            borderRadius: BorderRadius.circular(9)),
        child: Text(unlocked ? name : '$name · locked',
            style: TextStyle(
                color: unlocked ? _roadActive : slate,
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      );
    }
    // Landmark "sign": name + the artifact you earn for clearing its boss.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 128),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: unlocked ? const Color(0xFFFFF6E4) : glyphTile,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: unlocked ? _roadGold : silver, width: 1.2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(unlocked ? landmark : '$landmark · locked',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: unlocked ? _roadActive : slate,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    height: 1.05)),
            const SizedBox(height: 2),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.workspace_premium_rounded,
                  size: 12, color: unlocked ? _roadGold : silver),
              const SizedBox(width: 3),
              Flexible(
                child: Text(artifact,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: unlocked ? const Color(0xFF8A5A12) : slate,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _Node extends StatelessWidget {
  final bool passed;
  final bool unlocked;
  final bool isBoss;
  final VoidCallback? onTap;
  const _Node({
    super.key,
    required this.passed,
    required this.unlocked,
    required this.isBoss,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double size = isBoss ? 64 : 52;
    final Color fill;
    final Color border;
    final Widget icon;
    if (passed) {
      fill = _doneGreen;
      border = _doneGreen;
      icon = Icon(isBoss ? Icons.account_balance_rounded : Icons.check,
          color: Colors.white, size: isBoss ? 30 : 24);
    } else if (unlocked) {
      fill = Colors.white;
      border = terracotta;
      icon = Icon(
          isBoss
              ? Icons.account_balance_rounded
              : Icons.play_arrow_rounded,
          color: terracotta,
          size: isBoss ? 30 : 26);
    } else {
      fill = const Color(0xFFEDEEF0);
      border = _lockGrey;
      icon = Icon(isBoss ? Icons.account_balance_rounded : Icons.lock,
          color: _lockGrey, size: isBoss ? 26 : 20);
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: fill,
          shape: isBoss ? BoxShape.rectangle : BoxShape.circle,
          borderRadius: isBoss ? BorderRadius.circular(16) : null,
          border: Border.all(color: border, width: isBoss ? 4 : 3),
          boxShadow: const [
            BoxShadow(
                color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Center(child: icon),
      ),
    );
  }
}

/// Loading placeholder shaped like the journey: HUD pills, a winding trail of
/// stop discs, and the bottom "what next" card.
class _MapSkeleton extends StatelessWidget {
  const _MapSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: const [
                SkeletonBox(width: 54, height: 30, radius: 20),
                SizedBox(width: 8),
                SkeletonBox(width: 54, height: 30, radius: 20),
                Spacer(),
                SkeletonBox(width: 92, height: 30, radius: 20),
                SizedBox(width: 8),
                SkeletonBox(width: 30, height: 30, radius: 15),
                SizedBox(width: 6),
                SkeletonBox(width: 30, height: 30, radius: 15),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (int i = 0; i < 5; i++)
                    Align(
                      alignment: i.isEven
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: const SkeletonBox(width: 52, height: 52, radius: 26),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFECE8E0), width: 1.5),
              ),
              child: Row(
                children: const [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 120, height: 12),
                        SizedBox(height: 8),
                        SkeletonBox(width: 180, height: 16),
                        SizedBox(height: 6),
                        SkeletonBox(width: 90, height: 12),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  SkeletonBox(width: 92, height: 42, radius: 21),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoadPainter extends CustomPainter {
  final List<Offset> pts;
  final List<bool> passed; // passed[i] → segment i→i+1 is "travelled"
  final List<_ZonePalette> palettes; // palettes[i] → colour of stop i's zone
  const _RoadPainter(this.pts, this.passed, this.palettes);

  Path _segment(int i) {
    final a = pts[i], b = pts[i + 1];
    final midY = (a.dy + b.dy) / 2;
    return Path()
      ..moveTo(a.dx, a.dy)
      ..cubicTo(a.dx, midY, b.dx, midY, b.dx, b.dy);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (pts.length < 2) return;
    for (int i = 0; i < pts.length - 1; i++) {
      final active = i < passed.length && passed[i];
      final path = _segment(i);
      // Travelled road takes the palette of the zone it leads INTO (stop i+1).
      final zone = (i + 1) < palettes.length ? palettes[i + 1] : _defaultZone;
      // Road base
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = active ? 14 : 12
          ..color = active ? zone.base : _roadMuted,
      );
      // Centre pattern — zone kente thread when travelled, faint dots when locked
      final centre = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = active ? 4 : 3
        ..color = active ? zone.thread : _mutedDot;
      final dashOn = active ? 7.0 : 2.0;
      final dashGap = active ? 12.0 : 16.0;
      for (final m in path.computeMetrics()) {
        double d = 0;
        while (d < m.length) {
          canvas.drawPath(m.extractPath(d, d + dashOn), centre);
          d += dashOn + dashGap;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RoadPainter old) =>
      old.pts != pts || old.passed != passed || old.palettes != palettes;
}
