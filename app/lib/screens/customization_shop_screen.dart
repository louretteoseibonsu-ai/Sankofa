import 'package:flutter/material.dart';
import '../data/avatar.dart';
import '../data/blind_box_data.dart';
import '../data/trotro_cosmetics.dart';
import '../services/progress_service.dart';
import '../services/sound_service.dart';
import '../theme.dart';
import '../widgets/avatar_carousel.dart';
import '../widgets/blind_box.dart';
import '../widgets/composable_trotro.dart';
import '../widgets/kente_shard.dart';
import '../widgets/state_message.dart';
import '../widgets/surface.dart';
import '../widgets/velvet.dart';
import '../widgets/tappable_scale.dart';

/// A woven-Kente cloth backdrop for the Compound hero, coloured by the equipped
/// `kente` cosmetic. 'None' (kente_classic) paints nothing.
class _KenteBackdrop extends CustomPainter {
  final String kenteId;
  const _KenteBackdrop(this.kenteId);

  static const _cream = Color(0xFFEFDCA6);

  List<Color>? _bands() {
    switch (kenteId) {
      case 'kente_goldgreen':
        return const [
          Color(0xFFE3A92C),
          _cream,
          Color(0xFF2E6B3B),
          Color(0xFF1A1512),
        ];
      case 'kente_redblack':
        return const [
          Color(0xFF9B2D2A),
          Color(0xFFE3A92C),
          Color(0xFF1A1512),
          _cream,
        ];
      default:
        return null; // 'None' → keep the plain velvet panel
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bands = _bands();
    if (bands == null) return;
    // A woven kente STRIP across the top (a header band), clear of the character
    // below. Interlocking coloured squares offset every other row, fine weave.
    const stripH = 38.0;
    const cell = 17.0;
    final cols = (size.width / cell).ceil();
    final rows = (stripH / cell).ceil();
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final idx = (c + (r.isOdd ? 2 : 0)) % 4;
        canvas.drawRect(
          Rect.fromLTWH(c * cell, r * cell, cell + 0.6, cell + 0.6),
          Paint()..color = bands[idx].withValues(alpha: 0.92),
        );
      }
    }
    final weave = Paint()
      ..color = const Color(0x66000000)
      ..strokeWidth = 1.0;
    for (double x = 0; x <= size.width; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, stripH), weave);
    }
    for (double y = 0; y <= stripH; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), weave);
    }
    // A thin gold thread finishes the bottom edge of the strip.
    canvas.drawRect(Rect.fromLTWH(0, stripH - 2, size.width, 2),
        Paint()..color = const Color(0x88E3A92C));
  }

  @override
  bool shouldRepaint(covariant _KenteBackdrop old) => old.kenteId != kenteId;
}

const Color _terra = Color(0xFFBE5235);

/// "The Compound" — your family home: choose and unlock the Super Family
/// characters, and spend Golden Kente shards on the Ananse blind box + collection.
class CustomizationShopScreen extends StatefulWidget {
  /// The skin to show instantly (from the map) so the Hero flight has a
  /// destination before the async cosmetics load finishes.
  final TroTroSkin? initialSkin;
  const CustomizationShopScreen({super.key, this.initialSkin});

  @override
  State<CustomizationShopScreen> createState() =>
      _CustomizationShopScreenState();
}

class _CustomizationShopScreenState extends State<CustomizationShopScreen> {
  final _service = ProgressService();
  CosmeticState _cos = CosmeticState.empty;
  Stats _stats = Stats.empty;
  int _shards = 0;
  String _avatarId = kDefaultAvatarId;
  bool _loading = true;
  bool _error = false;

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
    setState(() {
      _stats = stats;
      _shards = stats.shards;
      _cos = cos;
      _avatarId = cos.equipped['avatar'] ?? kDefaultAvatarId;
      _loading = false;
      _error = false;
    });
  }

  Future<void> _unlockAvatar(Avatar a) async {
    if (_shards < a.shardCost) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('You need ${a.shardCost} shards to unlock '
              '${a.name} — earn more with 3-star lessons.')));
      return;
    }
    final ok = await _service.unlockAvatarWithShards(a);
    if (!mounted) return;
    if (ok) {
      SoundService.instance.tap();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${a.name} joined your family! 🎉')));
      setState(() => _avatarId = a.id);
      await _reload();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Couldn’t unlock — check your connection.')));
    }
  }

  Future<void> _buyFreezeShards() async {
    if (_shards < ProgressService.kFreezeShardCost) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('You need ${ProgressService.kFreezeShardCost} shards for '
              'a streak freeze — earn more with 3-star lessons.')));
      return;
    }
    final ok = await _service.buyFreezeWithShards();
    if (!mounted) return;
    if (ok) {
      SoundService.instance.tap();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Streak freeze added ❄')));
      await _reload();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Couldn’t buy — check your connection.')));
    }
  }

  Future<void> _selectAvatar(Avatar a) async {
    setState(() => _avatarId = a.id);
    SoundService.instance.tap();
    await _service.equipAvatar(a.id);
  }

  Future<void> _openBlindBox() async {
    if (_shards < kBlindBoxCost) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('You need $kBlindBoxCost shards to open a box — '
              'earn more by scoring 3 stars on lessons.')));
      return;
    }
    final result = await _service.buyBlindBox();
    if (!mounted) return;
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Couldn’t open the box — check your connection.')));
      return;
    }
    // The unboxing overlay plays its own timeline cues (boxTap → … → reveal).
    await BlindBoxOpening.show(context, result: result);
    if (!mounted) return;
    await _reload();
  }

  Future<void> _repairStreak() async {
    if (_shards < ProgressService.kRepairShardCost) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('You need ${ProgressService.kRepairShardCost} shards to '
              'restore your streak — earn more with 3-star lessons.')));
      return;
    }
    final ok = await _service.repairStreakWithShards();
    if (!mounted) return;
    if (ok) {
      SoundService.instance.complete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Streak restored — finish a lesson today to keep it 🔥')));
      await _reload();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Couldn’t restore — check your connection.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = _stats.progress.level;
    final streak = _stats.streak;
    final mastered = _stats.progress.best.values.where((v) => v >= 10).length;
    final unlockedAvatars = <String>{
      for (final a in kAvatars)
        if (a.unlockedBy(level: level, streak: streak, mastered: mastered))
          a.id,
      ..._cos.avatarsUnlocked, // members bought early with shards
    };
    return Scaffold(
      backgroundColor: kVelvetTop,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: kVelvetInk,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('The Compound',
            style: displayFont(
                fontSize: 19, fontWeight: FontWeight.w700, color: kVelvetInk)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('$_shards', style: editorialNumber(fontSize: 17)),
              const SizedBox(width: 6),
              const KenteShard(size: 17),
            ]),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kVelvetTop, kVelvetBottom],
          ),
        ),
        child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                // Hero — the equipped family member (also the Hero-flight
                // destination when arriving from the map).
                AtmosphericPanel(
                  radius: 22,
                  glow: terracotta,
                  padding: EdgeInsets.zero,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: SizedBox(
                      height: 262,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          // Equipped Kente cloth as a header strip above the
                          // family member (clear of the character).
                          const Positioned.fill(
                            child: CustomPaint(
                              painter: _KenteBackdrop('kente_goldgreen'),
                            ),
                          ),
                          Image.asset(
                            avatarById(_avatarId).assetReference,
                            height: 210,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox(height: 210),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text('Earn shards with 3-star lessons',
                      style: microLabel()),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 16, 0, 6),
                  child: Text('Your Family', style: microLabel()),
                ),
                AvatarCarousel(
                  selectedId: _avatarId,
                  unlockedIds: unlockedAvatars,
                  onSelect: _selectAvatar,
                  shards: _shards,
                  onUnlock: _unlockAvatar,
                ),
                const SizedBox(height: 20),
                // ── The Makola market stall: where shards are spent ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 0, 0, 2),
                  child: Row(
                    children: [
                      const Icon(Icons.storefront_rounded,
                          size: 18, color: Color(0xFFE3A92C)),
                      const SizedBox(width: 8),
                      Text('Makola Market Stall',
                          style: displayFont(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: kVelvetInk)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 0, 0, 10),
                  child: Text('Spend your kente shards to protect your streak',
                      style: microLabel()),
                ),
                if (_stats.repairableStreak > 0) ...[
                  _SecondChanceCard(
                    streak: _stats.repairableStreak,
                    cost: ProgressService.kRepairShardCost,
                    canAfford: _shards >= ProgressService.kRepairShardCost,
                    onRepair: _repairStreak,
                  ),
                  const SizedBox(height: 10),
                ],
                _BlindBoxCard(shards: _shards, onOpen: _openBlindBox),
                const SizedBox(height: 10),
                // ── Utility: spend shards on a streak freeze ──
                Material(
                  color: const Color(0xFF211B17),
                  borderRadius: BorderRadius.circular(18),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: _buyFreezeShards,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.ac_unit,
                              color: Color(0xFF6FA8DC), size: 22),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Streak Freeze',
                                    style: displayFont(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: kVelvetInk)),
                                const Text(
                                    'Protects your streak on a day you miss',
                                    style: TextStyle(
                                        color: kVelvetMuted, fontSize: 12)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${ProgressService.kFreezeShardCost}',
                              style: editorialNumber(fontSize: 15)),
                          const SizedBox(width: 5),
                          const KenteShard(size: 14),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                if (_error)
                  Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: StateMessage(
                      dark: true,
                      icon: Icons.wifi_off_rounded,
                      title: 'Couldn’t load the Compound',
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
                  ),
              ],
            ),
      ),
    );
  }
}

/// Second Chance — restore a streak that lapsed in the last day or two. Only
/// shown when [ProgressService] reports a repairable streak.
class _SecondChanceCard extends StatelessWidget {
  final int streak;
  final int cost;
  final bool canAfford;
  final VoidCallback onRepair;
  const _SecondChanceCard({
    required this.streak,
    required this.cost,
    required this.canAfford,
    required this.onRepair,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7A3F36), Color(0xFF2C1D18)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE07A3E), width: 1.4),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onRepair,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department_rounded,
                    color: Color(0xFFE07A3E), size: 30),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Second Chance',
                          style: displayFont(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      const SizedBox(height: 2),
                      Text('Restore your $streak-day streak — one lesson today keeps it',
                          maxLines: 2,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text('$cost',
                    style: editorialNumber(
                        fontSize: 15,
                        color: canAfford ? Colors.white : Colors.white38)),
                const SizedBox(width: 5),
                KenteShard(size: 14, muted: !canAfford),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The entry point to Ananse's Folklore Blind Boxes — a kente-toned CTA that
/// spends [kBlindBoxCost] shards to open a mystery calabash.
class _BlindBoxCard extends StatelessWidget {
  final int shards;
  final VoidCallback onOpen;
  const _BlindBoxCard({required this.shards, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final canAfford = shards >= kBlindBoxCost;
    return Container(
      margin: const EdgeInsets.only(top: 18, bottom: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3D2A4D), Color(0xFF7A3F36)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: kRaisedShadow,
      ),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard_rounded,
              color: Color(0xFFE3A92C), size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Ananse’s Blind Box",
                    style: displayFont(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 2),
                const Text('A mystery calabash — streak freezes & shards await.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 5),
                Text.rich(
                  const TextSpan(children: [
                    TextSpan(
                        text: 'Common',
                        style: TextStyle(color: Color(0xFF9AA0A6))),
                    TextSpan(text: '  ·  '),
                    TextSpan(
                        text: 'Rare',
                        style: TextStyle(color: Color(0xFF6FA8DC))),
                    TextSpan(text: '  ·  '),
                    TextSpan(
                        text: 'Legendary',
                        style: TextStyle(color: Color(0xFFE3A92C))),
                    TextSpan(text: ' awaits'),
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          TappableScale(
            onTap: onOpen,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color:
                    canAfford ? const Color(0xFFBE5235) : Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  KenteShard(size: 15, muted: !canAfford),
                  const SizedBox(width: 4),
                  Text('$kBlindBoxCost',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: canAfford ? Colors.white : Colors.white70)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
