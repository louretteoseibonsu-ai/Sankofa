/// The player's equipped family avatar plus the members they've unlocked early
/// with Golden Kente shards.
///
/// (Formerly `trotro_cosmetics.dart`, which also held the retired tro-tro skin
/// catalog. The bus and its cosmetics are gone; only the avatar state remains.)
class CosmeticState {
  /// Equipped selections, keyed by slot. Today only `'avatar'` is used, e.g.
  /// `{'avatar': 'uncle'}`.
  final Map<String, String> equipped;

  /// Family members bought ahead of their milestone with shards.
  final Set<String> avatarsUnlocked;

  const CosmeticState({
    this.equipped = const {},
    this.avatarsUnlocked = const {},
  });

  static const empty = CosmeticState();
}
