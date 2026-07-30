import 'package:flutter/material.dart';
import '../data/avatar.dart';
import '../data/blind_box_data.dart';
import '../data/cosmetic_state.dart';
import '../services/progress_service.dart';
import '../services/sound_service.dart';
import '../theme.dart';
import '../widgets/avatar_carousel.dart';
import '../widgets/blind_box.dart';
import '../widgets/kente_shard.dart';
import '../widgets/state_message.dart';
import '../widgets/surface.dart';
import '../widgets/velvet.dart';

/// "The Compound" — your family home: choose and unlock the Super Family
/// characters, and spend Golden Kente shards on the Ananse blind box + collection.
class CompoundScreen extends StatefulWidget {
  const CompoundScreen({super.key});

  @override
  State<CompoundScreen> createState() =>
      _CompoundScreenState();
}

class _CompoundScreenState extends State<CompoundScreen> {
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
                      width: double.infinity,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Image.asset(
                          avatarById(_avatarId).assetReference,
                          height: 224,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              const SizedBox(height: 224),
                        ),
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
                  _PowerUpTile(
                    icon: Icons.local_fire_department_rounded,
                    accent: const Color(0xFFE07A3E),
                    accentDeep: const Color(0xFF7A2F18),
                    title: 'Second Chance',
                    desc:
                        'Restore your ${_stats.repairableStreak}-day streak — one lesson keeps it',
                    action: 'RESTORE',
                    cost: ProgressService.kRepairShardCost,
                    canAfford: _shards >= ProgressService.kRepairShardCost,
                    onTap: _repairStreak,
                  ),
                  const SizedBox(height: 12),
                ],
                _PowerUpTile(
                  icon: Icons.card_giftcard_rounded,
                  accent: const Color(0xFF8E5BB5),
                  accentDeep: const Color(0xFF3D2A4D),
                  title: 'Ananse’s Blind Box',
                  desc: 'Freezes, shards & jackpots await',
                  action: 'OPEN',
                  cost: kBlindBoxCost,
                  canAfford: _shards >= kBlindBoxCost,
                  pillGradient: const LinearGradient(
                      colors: [Color(0xFF8E5BB5), Color(0xFFE3A92C)]),
                  onTap: _openBlindBox,
                ),
                const SizedBox(height: 12),
                _PowerUpTile(
                  icon: Icons.ac_unit_rounded,
                  accent: const Color(0xFF6FA8DC),
                  accentDeep: const Color(0xFF254A63),
                  title: 'Streak Freeze',
                  desc: 'Protects your streak on a day you miss',
                  action: 'BUY',
                  cost: ProgressService.kFreezeShardCost,
                  canAfford: _shards >= ProgressService.kFreezeShardCost,
                  onTap: _buyFreezeShards,
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

/// A vivid arcade-style power-up tile for the Makola Market Stall: a per-item
/// colour glow, a glossy icon ring, and a chunky "spend" pill.
class _PowerUpTile extends StatelessWidget {
  final IconData icon;
  final Color accent; // glow + ring + pill colour
  final Color accentDeep; // ring gradient deep end
  final String title;
  final String desc;
  final String action; // RESTORE / OPEN / BUY
  final int cost;
  final bool canAfford;
  final Gradient? pillGradient; // overrides the flat accent pill (blind box)
  final VoidCallback onTap;
  const _PowerUpTile({
    required this.icon,
    required this.accent,
    required this.accentDeep,
    required this.title,
    required this.desc,
    required this.action,
    required this.cost,
    required this.canAfford,
    required this.onTap,
    this.pillGradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16121A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
              color: accent.withValues(alpha: 0.22),
              blurRadius: 22,
              spreadRadius: -6,
              offset: const Offset(0, 8)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              // Corner colour bloom.
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(-0.85, -1.0),
                        radius: 1.15,
                        colors: [
                          accent.withValues(alpha: 0.40),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.7],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Glossy icon ring.
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient:
                                RadialGradient(colors: [accent, accentDeep]),
                            boxShadow: [
                              BoxShadow(
                                  color: accent.withValues(alpha: 0.6),
                                  blurRadius: 16,
                                  spreadRadius: -2),
                            ],
                          ),
                          child: Icon(icon, color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title,
                                  style: displayFont(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white)),
                              const SizedBox(height: 2),
                              Text(desc,
                                  maxLines: 2,
                                  style: const TextStyle(
                                      color: Color(0xFFB9B0C2),
                                      fontSize: 12,
                                      height: 1.25)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _pill(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill() {
    if (!canAfford) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('NEED $cost',
                style: const TextStyle(
                    color: Colors.white38,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 0.4)),
            const SizedBox(width: 5),
            const KenteShard(size: 14, muted: true),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        gradient: pillGradient,
        color: pillGradient == null ? accent : null,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: accent.withValues(alpha: 0.45),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$action  ·  $cost',
              style: const TextStyle(
                  color: Color(0xFF1A1206),
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  letterSpacing: 0.4)),
          const SizedBox(width: 5),
          const KenteShard(size: 14),
        ],
      ),
    );
  }
}
