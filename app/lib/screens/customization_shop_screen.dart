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
import '../widgets/skeleton.dart';
import '../widgets/state_message.dart';
import '../widgets/surface.dart';
import '../widgets/velvet.dart';
import '../widgets/tappable_scale.dart';
import '../widgets/tintable_trotro.dart';

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
  int _bodyIndex = 0; // equipped body-colour palette index
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
      _bodyIndex = troTroBodyIndexFor(cos.equipped);
      _avatarId = cos.equipped['avatar'] ?? kDefaultAvatarId;
      _loading = false;
      _error = false;
    });
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
    SoundService.instance.complete();
    final equip = await BlindBoxOpening.show(
      context,
      result: result,
      bodyColor: kTroTroBodyColors[_bodyIndex],
      equipped: _cos.equipped,
    );
    if (!mounted) return;
    // Persist the equip AFTER the overlay resolves (avoids racing the reload).
    if (equip && result.reward.isBusCosmetic) {
      await _service.equipCosmetic(result.reward.category, result.reward.id);
    }
    await _reload();
  }

  Future<void> _onTap(ShopItem item) async {
    final owned = _cos.owned.contains(item.id) || item.isDefault;
    if (owned) {
      await _service.equipCosmetic(item.category, item.id);
      SoundService.instance.tap();
    } else {
      final ok = await _service.buyCosmetic(item);
      if (!ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Not enough kente shards yet — earn more by '
                'scoring 3 stars on lessons.')));
        return;
      }
      SoundService.instance.complete();
    }
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final level = _stats.progress.level;
    final streak = _stats.streak;
    final mastered = _stats.progress.best.values.where((v) => v >= 10).length;
    final unlockedAvatars = <String>{
      for (final a in kAvatars)
        if (a.unlockedBy(level: level, streak: streak, mastered: mastered))
          a.id
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
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: Image.asset(
                      avatarById(_avatarId).assetReference,
                      height: 208,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const SizedBox(height: 208),
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
                ),
                const SizedBox(height: 10),
                _BlindBoxCard(shards: _shards, onOpen: _openBlindBox),
                const SizedBox(height: 4),
                if (_error)
                  Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: StateMessage(
                      dark: true,
                      icon: Icons.wifi_off_rounded,
                      title: 'Couldn’t load the Garage',
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
                if (!_error && _loading)
                  const SkeletonLoader(
                    child: Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Column(
                        children: [
                          SkeletonCard(dark: true),
                          SkeletonCard(dark: true),
                          SkeletonCard(dark: true),
                        ],
                      ),
                    ),
                  ),
                if (!_error && !_loading)
                  for (final cat in kCosmeticCategories) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(2, 12, 0, 8),
                    child: Text(kCategoryLabel[cat] ?? cat,
                        style: microLabel()),
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final item
                          in kCosmetics.where((i) => i.category == cat))
                        _ItemCard(
                          item: item,
                          owned: _cos.owned.contains(item.id) || item.isDefault,
                          equipped: _cos.equippedIn(cat) == item.id,
                          affordable: _shards >= item.costShards,
                          onTap: () => _onTap(item),
                        ),
                    ],
                  ),
                ],
              ],
            ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final ShopItem item;
  final bool owned;
  final bool equipped;
  final bool affordable;
  final VoidCallback onTap;
  const _ItemCard({
    required this.item,
    required this.owned,
    required this.equipped,
    required this.affordable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Widget status;
    if (equipped) {
      status = Text('EQUIPPED',
          style: displayFont(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: kOchre,
              letterSpacing: 1.2));
    } else if (owned) {
      status = Text('Equip',
          style: displayFont(
              fontSize: 12, fontWeight: FontWeight.w700, color: kVelvetInk));
    } else {
      status = Row(mainAxisSize: MainAxisSize.min, children: [
        KenteShard(size: 14, muted: !affordable),
        const SizedBox(width: 4),
        Text('${item.costShards}',
            style: displayFont(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: affordable ? kOchre : kVelvetMuted)),
      ]);
    }

    final width = MediaQuery.of(context).size.width - 16 * 2;
    return AppCard(
      onTap: onTap,
      width: width,
      radius: 14,
      color: const Color(0xFF211B17),
      borderColor: equipped ? kOchre : Colors.white10,
      borderWidth: equipped ? 2 : 1,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: Text(item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: displayFont(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kVelvetInk)),
          ),
          const SizedBox(width: 6),
          status,
        ],
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
                const Text('A mystery calabash — rare cloth & motifs await.',
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
