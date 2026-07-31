enum FrontierSymbolRank { silver, gold }

enum FrontierSymbolType {
  knowledge,
  guts,
  tactics,
  luck,
  spirit,
  ability,
  bravery,
}

class FrontierAssetResolver {
  const FrontierAssetResolver._();

  static String symbol(FrontierSymbolType type, FrontierSymbolRank rank) {
    return 'assets/sprites/frontier_symbols/emerald/${type.name}_${rank.name}.png';
  }

  static String trainer(String key) {
    return 'assets/sprites/characters/special_trainers/battle_frontier/emerald/$key.png';
  }
}
