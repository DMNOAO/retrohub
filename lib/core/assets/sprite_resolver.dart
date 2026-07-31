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

  static String pokemonForGame({
    required GameAssetProfile profile,
    required int pokemonId,
    bool isShiny = false,
  }) {
    return pokemon(
      spriteSet: profile.pokemonSpriteSet,
      pokemonId: pokemonId,
      extension: profile.pokemonExtension,
      isShiny: isShiny,
    );
  }
}
