import 'package:flutter/material.dart';
import '../data/trotro_cosmetics.dart';
import '../services/progress_service.dart';
import '../services/sound_service.dart';
import '../theme.dart';
import '../widgets/composable_trotro.dart';

const Color _terra = Color(0xFFBE5235);

/// "The Garage" — spend Golden Kente shards to customise the tro tro.
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
  int _shards = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final stats = await _service.loadStats();
    final cos = await _service.loadCosmetics();
    if (!mounted) return;
    setState(() {
      _shards = stats.shards;
      _cos = cos;
      _loading = false;
    });
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
    final skin = _loading
        ? (widget.initialSkin ?? const TroTroSkin())
        : TroTroSkin.fromEquipped(_cos.equipped);
    return Scaffold(
      appBar: AppBar(
        title: const Text('The Garage'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Row(children: [
              const Icon(Icons.diamond_rounded, color: _terra, size: 18),
              const SizedBox(width: 5),
              Text('$_shards',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: ink, fontSize: 15)),
            ]),
          ),
        ],
      ),
      body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                // Live preview — always rendered so the Hero flight from the
                // map has a destination during the push transition.
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBF8F2),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: silverLight, width: 1.5),
                  ),
                  child: Center(
                      child: ComposableTroTro(skin: skin, width: 240)),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text('Earn shards with 3-star lessons.',
                      style: TextStyle(color: slate, fontSize: 12.5)),
                ),
                const SizedBox(height: 12),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.only(top: 30),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (!_loading)
                  for (final cat in kCosmeticCategories) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(2, 12, 0, 8),
                    child: Text(kCategoryLabel[cat] ?? cat,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: ink)),
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
      status = const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check_circle_rounded, color: _terra, size: 16),
        SizedBox(width: 4),
        Text('Equipped',
            style: TextStyle(
                color: _terra, fontSize: 12, fontWeight: FontWeight.w800)),
      ]);
    } else if (owned) {
      status = const Text('Equip',
          style: TextStyle(
              color: ink, fontSize: 12, fontWeight: FontWeight.w800));
    } else {
      status = Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.diamond_rounded,
            color: affordable ? _terra : silver, size: 14),
        const SizedBox(width: 4),
        Text('${item.costShards}',
            style: TextStyle(
                color: affordable ? ink : slate,
                fontSize: 12,
                fontWeight: FontWeight.w800)),
      ]);
    }

    final width = (MediaQuery.of(context).size.width - 16 * 2 - 10) / 2;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: equipped ? _terra : silverLight,
              width: equipped ? 2 : 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(item.name,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: ink)),
            ),
            const SizedBox(width: 6),
            status,
          ],
        ),
      ),
    );
  }
}
