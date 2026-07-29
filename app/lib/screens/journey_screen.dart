import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/avatar.dart';
import '../data/family_lines.dart';
import '../data/journey_state.dart';
import '../data/landmark.dart';
import '../data/lesson_catalog.dart';
import '../data/trotro_cosmetics.dart';
import '../services/progress_service.dart';
import '../services/sound_service.dart';
import '../theme.dart';
import '../widgets/celebration.dart';
import '../widgets/composable_trotro.dart';
import '../widgets/avatar_badge.dart';
import '../widgets/campaign_banner.dart';
import '../widgets/greeting.dart';
import '../widgets/landmark_sheet.dart';
import '../widgets/motion.dart';
import '../widgets/overlay_flight.dart';
import '../widgets/skeleton.dart';
import '../widgets/state_message.dart';
import '../widgets/tappable_scale.dart';
import '../widgets/velvet.dart';
import '../widgets/trotro_mascot.dart';
import 'customization_shop_screen.dart';
import 'reading_screen.dart';
import 'dialogue_boss_screen.dart';
import 'lesson_quiz_screen.dart';
import 'time_attack_screen.dart';

// Road / map palette.
const Color _roadActive = Color(0xFFBE5235); // travelled — vibrant terracotta
const Color _roadGold = Color(0xFFE3A92C); // kente centre thread
const Color _roadMuted = Color(0xFF3A322C); // locked road ahead (velvet)
const Color _mutedDot = Color(0xFF52463C);
const Color _doneGreen = Color(0xFF2E6B3B);

// (The old per-zone/per-Act road palettes were retired when the road moved to a
// single sculpted terracotta+ochre treatment in _RoadPainter.)

/// The map's ambient glow colour for the equipped Journey Glow map theme
/// (bought with shards in The Compound).
Color _trailGlow(String? trailId) {
  switch (trailId) {
    case 'trail_gold':
      return const Color(0xFF2E2410); // Golden Hour
    case 'trail_emerald':
      return const Color(0xFF16261A); // Emerald
    case 'trail_royal':
      return const Color(0xFF241733); // Royal Kente (violet)
    default:
      return const Color(0xFF241C17); // Ember (default)
  }
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
  final GlobalKey _compoundKey = GlobalKey(); // the Compound button (flight target)
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
  Map<String, String> _equipped = const {}; // cosmetics for the layered avatar
  Set<String> _avatarsUnlocked = const {}; // family bought early with shards
  String? _familyLine; // a greeting nudge in the equipped guide's voice
  bool _firstLoad = true;
  bool _error = false; // set when the initial load fails (offline / no cache)

  // Continuous engine-idle bob for the player avatar — grows into a bigger bob
  // + forward lean while "driving" between stops so it reads as alive.
  late final AnimationController _driveBob;

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
    _driveBob = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _reload();
  }

  @override
  void dispose() {
    _driveBob.dispose();
    super.dispose();
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
      _equipped = cos.equipped;
      _avatarsUnlocked = cos.avatarsUnlocked;
      _familyLine = FamilyLines.greeting(cos.equipped['avatar']);
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
      builder: (w) => _avatarFigure(w),
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
      builder: (w) => _avatarFigure(w),
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

  /// Fly the family avatar home into the Compound — powered by the reusable
  /// [OverlayFlight] helper.
  Future<void> _openCompound() async {
    if (_flying || _troKey.currentContext == null) {
      _pushCompound();
      return;
    }
    await OverlayFlight.run(
      context: context,
      vsync: this,
      fromKey: _troKey,
      toKey: _compoundKey,
      endScale: 0.28, // shrink into the Compound button
      arcHeight: 90,
      builder: (w) => _avatarFigure(w),
      onStart: () {
        HapticFeedback.selectionClick();
        setState(() => _flying = true); // hide the avatar during the flight
      },
    );
    if (!mounted) return;
    _pushCompound();
  }

  void _pushCompound() {
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

  /// Landmarks unlocked by clearing each region's boss (progress-driven).
  Set<String> get _unlockedLandmarks => unlockedLandmarkIds(_p.passed);

  /// The equipped family avatar rendered as a matte figure at [width] — used for
  /// the map player marker and the region-warp / Compound / campfire flight clones
  /// (the tro tro bus art is retired).
  Widget _avatarFigure(double width) {
    final avatar = avatarById(_equipped['avatar']);
    return Image.asset(
      avatar.assetReference,
      width: width,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          AvatarBadge(avatar: avatar, size: width, selected: true),
    );
  }

  /// The unlocked family members, in roster order — who the player can pick.
  List<Avatar> get _unlockedAvatars {
    final level = _stats.progress.level;
    final streak = _stats.streak;
    final mastered = _stats.progress.best.values.where((v) => v >= 10).length;
    return kAvatars
        .where((a) =>
            a.unlockedBy(level: level, streak: streak, mastered: mastered) ||
            _avatarsUnlocked.contains(a.id)) // bought early with shards
        .toList();
  }

  /// Cycle the map player to the next unlocked family member (persisted).
  Future<void> _cycleAvatar() async {
    final unlocked = _unlockedAvatars;
    if (unlocked.length < 2) return; // nothing else unlocked yet
    final currentId = _equipped['avatar'] ?? kDefaultAvatarId;
    final idx = unlocked.indexWhere((a) => a.id == currentId);
    final next = unlocked[(idx + 1) % unlocked.length];
    HapticFeedback.selectionClick();
    setState(() => _equipped = {..._equipped, 'avatar': next.id});
    await _service.equipAvatar(next.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: const Duration(milliseconds: 1100),
      content: Text('You are now ${next.name}'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _MapSkeleton();
    if (_error) {
      return ColoredBox(
        color: const Color(0xFF17130F),
        child: StateMessage(
          dark: true,
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
        ),
      );
    }
    final lessons = kLessonsFlat;
    final n = lessons.length;
    final current = _currentIndex;
    final regionName = _catName[lessons[current].categoryId] ?? 'Journey';

    return DecoratedBox(
      decoration: BoxDecoration(
        // Subtle radial ambient — its glow colour is the equipped Journey Glow
        // map theme (Ember / Golden Hour / Emerald / Royal Kente), falling to
        // near-black velvet at the edges.
        gradient: RadialGradient(
          center: const Alignment(0.0, -0.55),
          radius: 1.3,
          colors: [_trailGlow(_equipped['trail']), const Color(0xFF141110)],
        ),
      ),
      child: Column(
        children: [
          // A warm nudge from your equipped family guide.
          if (_familyLine != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text:
                        '${avatarById(_equipped['avatar']).name.replaceFirst('Super ', '')}  ',
                    style: const TextStyle(
                        color: kOchre,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                  TextSpan(
                    text: _familyLine,
                    style: const TextStyle(
                        color: kVelvetMuted,
                        fontSize: 13,
                        height: 1.3,
                        fontStyle: FontStyle.italic),
                  ),
                ]),
              ),
            ),
          const CampaignBanner(kicker: ''),
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
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                      onPressed: _cycleAvatar,
                      icon: const Icon(Icons.groups_rounded),
                      color: kVelvetInk,
                      tooltip: 'Change character',
                    ),
                    IconButton(
                      key: _anansesemKey,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                      onPressed: _openAnansesem,
                      icon: const Icon(Icons.local_fire_department_rounded),
                      color: kVelvetInk,
                      tooltip: 'Anansesɛm',
                    ),
                    IconButton(
                      key: _compoundKey,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                      onPressed: _openCompound,
                      icon: const Icon(Icons.holiday_village_rounded),
                      color: kVelvetInk,
                      tooltip: 'The Compound',
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
                        painter: _RoadPainter(points, passedFlags),
                      ),
                      // Goal marker at the top of the map
                      if (n > 0)
                        Positioned(
                          left: points.last.dx - 20,
                          top: points.last.dy - 78,
                          child: const Icon(Icons.emoji_events_rounded,
                              color: _roadGold, size: 40),
                        ),
                      // Cultural landmark points of interest — unlocked once the
                      // region's boss is cleared (progress-driven).
                      for (final lm in kLandmarks)
                        Positioned(
                          left: lm.coordinates.dx * w - 26,
                          top: lm.coordinates.dy * height - 26,
                          child: _LandmarkMarker(
                            landmark: lm,
                            unlocked: _unlockedLandmarks.contains(lm.id),
                            onTap: () => showLandmarkSheet(context, lm,
                                unlocked: _unlockedLandmarks.contains(lm.id)),
                          ),
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
                      // The player avatar — the chosen family character stands
                      // on the active checkpoint (the tro tro bus is retired).
                      if (n > 0)
                        Positioned(
                          left: 0,
                          top: 0,
                          width: 96,
                          height: 118,
                          child: Spring2DBuilder(
                            target: Offset(points[_displayIndex].dx - 48,
                                points[_displayIndex].dy - 90),
                            builder: (context, pos, child) =>
                                Transform.translate(offset: pos, child: child),
                            child: GestureDetector(
                              onTap: () => _open(lessons[current]),
                              child: Opacity(
                                opacity: _flying ? 0.0 : 1.0,
                                child: AnimatedBuilder(
                                  animation: _driveBob,
                                  builder: (_, __) {
                                    final driving =
                                        _troState == TroTroState.drive;
                                    final wave = Curves.easeInOut
                                        .transform(_driveBob.value);
                                    final bob = (driving ? 6.0 : 2.5) * wave;
                                    final avatar =
                                        avatarById(_equipped['avatar']);
                                    return Stack(
                                      clipBehavior: Clip.none,
                                      alignment: Alignment.bottomCenter,
                                      children: [
                                        // Grounding contact shadow.
                                        const Positioned(
                                          bottom: 8,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              color: Color(0x55000000),
                                              borderRadius: BorderRadius.all(
                                                  Radius.elliptical(27, 6.5)),
                                            ),
                                            child: SizedBox(
                                                width: 54, height: 13),
                                          ),
                                        ),
                                        if (driving)
                                          Positioned(
                                            left: 2,
                                            bottom: 8,
                                            child:
                                                _DriveDust(t: _driveBob.value),
                                          ),
                                        Transform.translate(
                                          offset: Offset(0, -bob),
                                          child: Transform.rotate(
                                            angle: driving ? -0.04 : 0.0,
                                            alignment: Alignment.bottomCenter,
                                            child: Image.asset(
                                              avatar.assetReference,
                                              key: _troKey,
                                              height: 106,
                                              fit: BoxFit.contain,
                                              errorBuilder: (_, __, ___) =>
                                                  AvatarBadge(
                                                avatar: avatar,
                                                size: 72,
                                                selected: true,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
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
                color: const Color(0xFF211B17),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10, width: 1.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // velvet current-stop card
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
                                color: kVelvetInk,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 1),
                        Text(
                          'Continue, ${firstNameOf(FirebaseAuth.instance.currentUser)}',
                          style: const TextStyle(color: kVelvetMuted, fontSize: 12),
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
      ),
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
        color: const Color(0xFF211B17),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10, width: 1.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: iconColor, size: 17),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                color: kVelvetInk, fontSize: 13, fontWeight: FontWeight.w800)),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: unlocked ? const Color(0xE6241C17) : const Color(0xCC1A1613),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
              color: unlocked ? const Color(0x66D4A373) : Colors.white10,
              width: 1),
        ),
        child: Text(unlocked ? name : '$name · locked',
            style: displayFont(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: unlocked ? kOchre : kVelvetMuted)),
      );
    }
    // Landmark "sign": name + the artifact you earn for clearing its boss.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 132),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: unlocked ? const Color(0xE6241C17) : const Color(0xCC1A1613),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: unlocked ? kOchre : Colors.white12, width: 1.2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(unlocked ? landmark : '$landmark · locked',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: displayFont(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: unlocked ? kVelvetInk : kVelvetMuted,
                    height: 1.05)),
            const SizedBox(height: 3),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.workspace_premium_rounded,
                  size: 12, color: unlocked ? kOchre : Colors.white24),
              const SizedBox(width: 3),
              Flexible(
                child: Text(artifact,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: unlocked ? kOchre : kVelvetMuted,
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
    final Color fill, border, iconColor;
    final IconData iconData;
    List<BoxShadow> shadow = const [
      BoxShadow(color: Color(0x66000000), blurRadius: 10, offset: Offset(0, 4)),
    ];
    if (passed) {
      fill = const Color(0xFF20261D);
      border = _doneGreen;
      iconColor = const Color(0xFF63C583);
      iconData = isBoss ? Icons.account_balance_rounded : Icons.check_rounded;
    } else if (unlocked) {
      fill = const Color(0xFF2A211C);
      border = terracotta;
      iconColor = terracotta;
      iconData =
          isBoss ? Icons.account_balance_rounded : Icons.play_arrow_rounded;
      // Terracotta inner glow — the "next" node draws the eye.
      shadow = [
        const BoxShadow(
            color: Color(0x66000000), blurRadius: 10, offset: Offset(0, 4)),
        BoxShadow(
            color: terracotta.withValues(alpha: 0.5),
            blurRadius: 18,
            spreadRadius: 1),
      ];
    } else {
      fill = const Color(0xFF1B1714);
      border = Colors.white12;
      iconColor = const Color(0xFF6E655C);
      iconData = isBoss ? Icons.account_balance_rounded : Icons.lock_rounded;
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          // Matte sculpt: a faint top sheen over the base fill.
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.alphaBlend(Colors.white.withValues(alpha: 0.06), fill),
              fill,
            ],
          ),
          shape: isBoss ? BoxShape.rectangle : BoxShape.circle,
          borderRadius: isBoss ? BorderRadius.circular(16) : null,
          border: Border.all(color: border, width: isBoss ? 3 : 2.5),
          boxShadow: shadow,
        ),
        child: Center(
          child: Icon(iconData, color: iconColor, size: isBoss ? 30 : 24),
        ),
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
    // Velvet base so the skeleton never flashes light before the map paints.
    return const ColoredBox(
      color: Color(0xFF17130F),
      child: SkeletonLoader(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  SkeletonBox(width: 54, height: 30, radius: 20, dark: true),
                  SizedBox(width: 8),
                  SkeletonBox(width: 54, height: 30, radius: 20, dark: true),
                  Spacer(),
                  SkeletonBox(width: 92, height: 30, radius: 20, dark: true),
                  SizedBox(width: 8),
                  SkeletonBox(width: 30, height: 30, radius: 15, dark: true),
                  SizedBox(width: 6),
                  SkeletonBox(width: 30, height: 30, radius: 15, dark: true),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 44, vertical: 18),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _SkeletonNodeRow(0),
                    _SkeletonNodeRow(1),
                    _SkeletonNodeRow(2),
                    _SkeletonNodeRow(3),
                    _SkeletonNodeRow(4),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 6, 16, 16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFF211B17),
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  border: Border.fromBorderSide(
                      BorderSide(color: Colors.white10, width: 1.5)),
                ),
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonBox(width: 120, height: 12, dark: true),
                            SizedBox(height: 8),
                            SkeletonBox(width: 180, height: 16, dark: true),
                            SizedBox(height: 6),
                            SkeletonBox(width: 90, height: 12, dark: true),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      SkeletonBox(width: 92, height: 42, radius: 21, dark: true),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One alternating node placeholder row in the dark map skeleton.
class _SkeletonNodeRow extends StatelessWidget {
  final int i;
  const _SkeletonNodeRow(this.i);
  @override
  Widget build(BuildContext context) => Align(
        alignment: i.isEven ? Alignment.centerLeft : Alignment.centerRight,
        child: const SkeletonBox(width: 52, height: 52, radius: 26, dark: true),
      );
}

class _RoadPainter extends CustomPainter {
  final List<Offset> pts;
  final List<bool> passed; // passed[i] → segment i→i+1 is "travelled"
  const _RoadPainter(this.pts, this.passed);

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
    const road = Color(0xFFE2725B); // terracotta
    const dash = Color(0xFFD4A373); // ochre
    const depth = Color(0xFF0C0A09); // sculpted shadow under the road
    for (int i = 0; i < pts.length - 1; i++) {
      final active = i < passed.length && passed[i];
      final path = _segment(i);
      // Sculpted depth: a dark under-stroke so the road reads raised + tactile.
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = active ? 17 : 14
          ..color = depth,
      );
      // Road surface — terracotta when travelled, dark warm when locked ahead.
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = active ? 13 : 11
          ..color = active ? road : _roadMuted,
      );
      // Thin top sheen for the sculpted highlight.
      if (active) {
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = 3
            ..color = Colors.white.withValues(alpha: 0.12),
        );
      }
      // Warm ochre dashed centre-line.
      final centre = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = active ? 4 : 3
        ..color = active ? dash : _mutedDot;
      final dashOn = active ? 8.0 : 2.0;
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
      old.pts != pts || old.passed != passed;
}

/// A little kente-dust wake kicked up behind the bus while it drives between
/// stops. Three puffs drift back (left) and fade — driven by the map's idle
/// controller so it costs nothing extra.
class _DriveDust extends StatelessWidget {
  final double t; // 0..1 pulse from the drive-bob controller
  const _DriveDust({required this.t});

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: CustomPaint(size: const Size(34, 22), painter: _DustPainter(t)),
      );
}

class _DustPainter extends CustomPainter {
  final double t;
  _DustPainter(this.t);

  static const Color _dust = Color(0xFFCBB89B);

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 3; i++) {
      final phase = (t + i / 3) % 1.0;
      final op = (1 - phase) * 0.5;
      final r = 3.0 + phase * 6.0;
      final cx = size.width - phase * size.width;
      final cy = size.height - 4 - i * 2.0;
      canvas.drawCircle(
          Offset(cx, cy), r, Paint()..color = _dust.withValues(alpha: op));
    }
  }

  @override
  bool shouldRepaint(covariant _DustPainter old) => old.t != t;
}

/// A collectible landmark pin on the world map — a small tile of the landmark's
/// art (or an accent placeholder), locked until earned. Tap opens its info sheet.
class _LandmarkMarker extends StatelessWidget {
  final Landmark landmark;
  final bool unlocked;
  final VoidCallback onTap;
  const _LandmarkMarker(
      {required this.landmark, required this.unlocked, required this.onTap});

  static Future<bool> _hasArt(BuildContext c, String path) async {
    try {
      await DefaultAssetBundle.of(c).load(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TappableScale(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1A17),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
              color: unlocked ? landmark.accent : Colors.white24, width: 2),
          boxShadow: kSoftShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Stack(
            fit: StackFit.expand,
            children: [
              FutureBuilder<bool>(
                future: _hasArt(context, landmark.imageAsset),
                builder: (context, snap) => snap.data == true
                    ? Image.asset(landmark.imageAsset, fit: BoxFit.cover)
                    : Center(
                        child: Icon(Icons.place_rounded,
                            color: landmark.accent, size: 24)),
              ),
              if (!unlocked)
                const ColoredBox(
                  color: Color(0x99000000),
                  child: Center(
                    child: Icon(Icons.lock_rounded,
                        color: Colors.white70, size: 20),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
