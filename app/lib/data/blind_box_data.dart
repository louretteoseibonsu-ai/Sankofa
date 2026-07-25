import 'dart:math';

/// Rarity tiers for Ananse's Folklore Blind Boxes. Weights drive the roll.
enum Rarity { common, rare, legendary }

extension RarityMeta on Rarity {
  String get label {
    switch (this) {
      case Rarity.common:
        return 'Common';
      case Rarity.rare:
        return 'Rare';
      case Rarity.legendary:
        return 'Legendary';
    }
  }

  /// Relative drop weight (higher = more likely).
  int get weight {
    switch (this) {
      case Rarity.common:
        return 70;
      case Rarity.rare:
        return 25;
      case Rarity.legendary:
        return 5;
    }
  }

  /// Shards refunded when a duplicate is rolled.
  int get dupeRefund {
    switch (this) {
      case Rarity.common:
        return 8;
      case Rarity.rare:
        return 20;
      case Rarity.legendary:
        return 30; // kept below kBlindBoxCost so a dupe never nets a profit
    }
  }
}

/// One possible drop. [category] maps to the layered-cosmetic slot
/// (e.g. 'kente') so a bus reward composites straight onto the Mascot via
/// `equipped`; 'figurine' rewards are dashboard collectibles (not bus layers).
class BoxReward {
  final String id; // equip id, e.g. 'kente_royalblue'
  final String category; // cosmetic slot, or 'figurine'
  final String name; // display name
  final Rarity rarity;
  const BoxReward({
    required this.id,
    required this.category,
    required this.name,
    required this.rarity,
  });

  bool get isBusCosmetic => category != 'figurine';
}

/// Starter reward pool. The two kente ids already have art; the rest are hooks
/// awaiting layered PNGs in trotro_gameplay/<category>/<id>.png (the reveal
/// degrades gracefully until then — Mascot skips missing layers).
const List<BoxReward> kBlindBoxPool = [
  BoxReward(
      id: 'kente_goldgreen',
      category: 'kente',
      name: 'Ashanti Gold Weave',
      rarity: Rarity.common),
  BoxReward(
      id: 'kente_redblack',
      category: 'kente',
      name: 'Adinkra Red & Black',
      rarity: Rarity.common),
  BoxReward(
      id: 'kente_bonwire',
      category: 'kente',
      name: 'Royal Bonwire Cloth',
      rarity: Rarity.rare),
  BoxReward(
      id: 'kente_sankofa',
      category: 'kente',
      name: 'Sankofa Motif',
      rarity: Rarity.rare),
  BoxReward(
      id: 'kente_chrome',
      category: 'kente',
      name: 'Midnight Chrome Finish',
      rarity: Rarity.legendary),
  BoxReward(
      id: 'fig_ananse',
      category: 'figurine',
      name: 'Ananse the Weaver',
      rarity: Rarity.legendary),
];

/// The outcome of opening one box.
class UnboxResult {
  final BoxReward reward;
  final bool duplicate; // already owned → converted to a shard refund
  final int refund; // shards returned on a duplicate (0 otherwise)
  const UnboxResult(this.reward, {this.duplicate = false, this.refund = 0});
}

/// Weighted rarity roll.
Rarity rollRarity(Random r) {
  final total = Rarity.values.fold<int>(0, (s, x) => s + x.weight);
  var n = r.nextInt(total);
  for (final x in Rarity.values) {
    if (n < x.weight) return x;
    n -= x.weight;
  }
  return Rarity.common;
}

/// Pure unbox roll: pick a rarity, then a reward of that rarity. If the id is
/// already [owned], flag it as a duplicate and compute the shard refund. This is
/// deliberately side-effect-free so it's testable and the server can mirror it.
UnboxResult rollUnbox(Random r, {Set<String> owned = const {}}) {
  final rarity = rollRarity(r);
  final tier = kBlindBoxPool.where((b) => b.rarity == rarity).toList();
  final pool = tier.isEmpty ? kBlindBoxPool : tier;
  final pick = pool[r.nextInt(pool.length)];
  final dup = owned.contains(pick.id);
  return UnboxResult(pick,
      duplicate: dup, refund: dup ? rarity.dupeRefund : 0);
}

/// Shard price of a single blind box.
const int kBlindBoxCost = 40;
