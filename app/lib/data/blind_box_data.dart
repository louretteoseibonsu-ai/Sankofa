import 'dart:math';

/// Rarity tiers for Ananse's Folklore Blind Boxes. Weights drive the roll and
/// tint the unboxing bloom.
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
}

/// The kind of functional payout a box can drop. Cosmetics are retired — every
/// reward now moves a real balance the learner cares about.
enum RewardKind { freeze, shards }

/// One possible drop from Ananse's calabash. A reward grants [freezeAmount]
/// streak freezes and/or [shardAmount] Golden Kente shards (usually one is 0).
class BoxReward {
  final String id;
  final String name; // display name
  final Rarity rarity;
  final RewardKind kind; // drives the reveal icon
  final int freezeAmount; // streak freezes granted
  final int shardAmount; // shards granted (a cashback / jackpot)
  const BoxReward({
    required this.id,
    required this.name,
    required this.rarity,
    required this.kind,
    this.freezeAmount = 0,
    this.shardAmount = 0,
  });
}

/// The functional reward pool. Tuned so every outcome is a real prize (never
/// "nothing"), with the legendary as a genuine jackpot. Expected value sits a
/// touch below [kBlindBoxCost] so the box stays a shard *sink*, with the thrill
/// in the variance.
const List<BoxReward> kBlindBoxPool = [
  BoxReward(
    id: 'freeze1',
    name: 'Streak Freeze',
    rarity: Rarity.common,
    kind: RewardKind.freeze,
    freezeAmount: 1,
  ),
  BoxReward(
    id: 'shards45',
    name: '45 Golden Shards',
    rarity: Rarity.rare,
    kind: RewardKind.shards,
    shardAmount: 45,
  ),
  BoxReward(
    id: 'freeze3',
    name: 'Triple Streak Freeze',
    rarity: Rarity.legendary,
    kind: RewardKind.freeze,
    freezeAmount: 3,
  ),
];

/// The outcome of opening one box.
class UnboxResult {
  final BoxReward reward;
  const UnboxResult(this.reward);
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

/// Pure unbox roll: pick a rarity, then a reward of that rarity. Side-effect
/// free so it's testable and the server can mirror it.
UnboxResult rollUnbox(Random r) {
  final rarity = rollRarity(r);
  final tier = kBlindBoxPool.where((b) => b.rarity == rarity).toList();
  final pool = tier.isEmpty ? kBlindBoxPool : tier;
  return UnboxResult(pool[r.nextInt(pool.length)]);
}

/// Shard price of a single blind box.
const int kBlindBoxCost = 40;
