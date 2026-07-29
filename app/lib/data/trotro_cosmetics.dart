/// A buyable / equippable tro tro cosmetic.
class ShopItem {
  final String id;
  final String category; // 'rim' | 'kente' | 'roof' | 'horn'
  final String name;
  final int costShards; // 0 = owned by default
  const ShopItem({
    required this.id,
    required this.category,
    required this.name,
    required this.costShards,
  });

  bool get isDefault => costShards == 0;
}

/// Cosmetics every user owns from the start (the cost-0 defaults).
const Set<String> kDefaultOwned = {
  'rim_silver',
  'kente_classic',
  'roof_none',
  'horn_vroom',
};

/// Ordered category keys and their display labels. Rim/roof are retired for the
/// gameplay bus (its cartoon wheels are baked in), so only trim + horn show.
const List<String> kCosmeticCategories = ['kente', 'trail', 'horn'];
const Map<String, String> kCategoryLabel = {
  'rim': 'Rims',
  'kente': 'Kente Cloth',
  'trail': 'Journey Glow',
  'roof': 'Roof rack',
  'horn': 'Celebration Sound',
};

/// The Garage catalog.
const List<ShopItem> kCosmetics = [
  // Rims
  ShopItem(id: 'rim_silver', category: 'rim', name: 'Silver', costShards: 0),
  ShopItem(id: 'rim_gold', category: 'rim', name: 'Gold', costShards: 8),
  ShopItem(
      id: 'rim_terracotta',
      category: 'rim',
      name: 'Terracotta',
      costShards: 8),
  ShopItem(
      id: 'rim_charcoal', category: 'rim', name: 'Charcoal', costShards: 6),
  // Kente trim
  ShopItem(
      id: 'kente_classic', category: 'kente', name: 'None', costShards: 0),
  ShopItem(
      id: 'kente_goldgreen',
      category: 'kente',
      name: 'Gold & green',
      costShards: 12),
  ShopItem(
      id: 'kente_redblack',
      category: 'kente',
      name: 'Red & black',
      costShards: 12),
  // Roof rack
  ShopItem(id: 'roof_none', category: 'roof', name: 'None', costShards: 0),
  ShopItem(
      id: 'roof_rack', category: 'roof', name: 'Market rack', costShards: 15),
  // Journey Glow — the ambient lighting theme of your world map.
  ShopItem(id: 'trail_ember', category: 'trail', name: 'Ember', costShards: 0),
  ShopItem(
      id: 'trail_gold', category: 'trail', name: 'Golden Hour', costShards: 40),
  ShopItem(
      id: 'trail_emerald', category: 'trail', name: 'Emerald', costShards: 40),
  ShopItem(
      id: 'trail_royal', category: 'trail', name: 'Royal Kente', costShards: 60),
  // Horn (sound stored now; audio pack lands with the sprite refactor)
  ShopItem(id: 'horn_vroom', category: 'horn', name: 'Vroom', costShards: 0),
  ShopItem(id: 'horn_honk', category: 'horn', name: 'Honk', costShards: 10),
  ShopItem(
      id: 'horn_afro', category: 'horn', name: 'Afro horn', costShards: 20),
];

/// The default (cost-0) item id for a category.
String defaultForCategory(String category) => kCosmetics
    .firstWhere((i) => i.category == category && i.isDefault)
    .id;

/// The user's owned + equipped cosmetics.
class CosmeticState {
  final Set<String> owned;
  final Map<String, String> equipped;
  final Set<String> avatarsUnlocked; // family members bought early with shards
  const CosmeticState(this.owned, this.equipped,
      {this.avatarsUnlocked = const {}});

  static const empty = CosmeticState(kDefaultOwned, {});

  /// The equipped id for a category, falling back to its default.
  String equippedIn(String category) =>
      equipped[category] ?? defaultForCategory(category);
}
