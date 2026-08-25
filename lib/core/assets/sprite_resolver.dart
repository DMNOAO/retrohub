import 'game_asset_profile.dart';

class SpriteResolver {
  const SpriteResolver._();

  static String pokemon({
    required String spriteSet,
    required int pokemonId,
    String extension = 'png',
    bool isShiny = false,
  }) {
    final id = pokemonId.toString().padLeft(4, '0');
    final shinyPath = isShiny ? 'shiny/' : '';
    return 'assets/sprites/pokemon/$spriteSet/$shinyPath$id.$extension';
  }

  static String eggForGame({required GameAssetProfile profile}) {
    if (profile.pokemonSpriteSet.startsWith('nds/')) {
      return 'assets/sprites/pokemon/nds/heartgold-soulsilver/0egg.png';
    }
    return 'assets/sprites/pokemon/${profile.pokemonSpriteSet}/egg.png';
  }

  static String pokemonForGame({
    required GameAssetProfile profile,
    required int pokemonId,
    bool isShiny = false,
    bool isFemale = false,
    bool secondFrame = false,
  }) {
    final id = pokemonId.toString().padLeft(4, '0');
    final folders = <String>[
      if (isShiny) 'shiny',
      if (isFemale) 'female',
      if (secondFrame) 'frame2',
    ];
    final variantPath = folders.isEmpty ? '' : '${folders.join('/')}/';
    return 'assets/sprites/pokemon/${profile.pokemonSpriteSet}/$variantPath$id.${profile.pokemonExtension}';
  }
}
