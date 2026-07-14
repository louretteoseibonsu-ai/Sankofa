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

/// Ordered category keys and their display labels.
const List<String> kCosmeticCategories = ['rim', 'kente', 'roof', 'horn'];
const Map<String, String> kCategoryLabel = {
  'rim': 'Rims',
  'kente': 'Kente trim',
  'roof': 'Roof rack',
  'horn': 'Horn',
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
      id: 'kente_classic', category: 'kente', name: 'Classic', costShards: 0),
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
  const CosmeticState(this.owned, this.equipped);

  static const empty = CosmeticState(kDefaultOwned, {});

  /// The equipped id for a category, falling back to its default.
  String equippedIn(String category) =>
      equipped[category] ?? defaultForCategory(category);
}
