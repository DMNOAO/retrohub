import '../../data/database/app_database.dart';

enum PokemonAssetGame {
  redBlue,
  yellow,
  gold,
  silver,
  crystal,
  rubySapphire,
  emerald,
  fireRedLeafGreen,
  unsupported,
}

enum PokemonAssetRegion { kanto, johto, hoenn, unknown }

class GameAssetProfile {
  final PokemonAssetGame game;
  final PokemonAssetRegion region;
  final String pokemonSpriteSet;
  final String pokemonExtension;
  final String trainerSpriteSet;
  final String? protagonistAsset;
  final String? rivalAsset;
  final String? championAsset;
  final String? sourceTitle;

  const GameAssetProfile({
    required this.game,
    required this.region,
    required this.pokemonSpriteSet,
    required this.pokemonExtension,
    required this.trainerSpriteSet,
    this.protagonistAsset,
    this.rivalAsset,
    this.championAsset,
    this.sourceTitle,
  });

  factory GameAssetProfile.fromGame(Game game) {
    return GameAssetProfile.fromTitle(title: game.title, console: game.console, savedSpriteSet: game.spriteSet);
  }

  factory GameAssetProfile.fromTitle({required String title, required String console, String? savedSpriteSet}) {
    final value = title.toLowerCase();

    if (value.contains('amarillo') || value.contains('yellow')) {
      return GameAssetProfile(game: PokemonAssetGame.yellow, region: PokemonAssetRegion.kanto, pokemonSpriteSet: savedSpriteSet ?? 'gb/yellow', pokemonExtension: 'png', trainerSpriteSet: 'gb', protagonistAsset: 'assets/sprites/characters/protagonists/red_yellow.png', rivalAsset: 'assets/sprites/characters/rivals/blue_kanto_yellow.png', championAsset: 'assets/sprites/characters/champions/blue_kanto_yellow.png', sourceTitle: value);
    }
    if (value.contains('cristal') || value.contains('crystal')) {
      return GameAssetProfile(game: PokemonAssetGame.crystal, region: PokemonAssetRegion.johto, pokemonSpriteSet: savedSpriteSet ?? 'gbc/crystal', pokemonExtension: 'gif', trainerSpriteSet: 'gbc', protagonistAsset: 'assets/sprites/characters/protagonists/ethan_crystal.png', rivalAsset: 'assets/sprites/characters/rivals/silver_johto.png', championAsset: 'assets/sprites/characters/champions/lance_johto.png', sourceTitle: value);
    }
    if (value.contains('oro') || value.contains('gold')) {
      return GameAssetProfile(game: PokemonAssetGame.gold, region: PokemonAssetRegion.johto, pokemonSpriteSet: savedSpriteSet ?? 'gbc/gold', pokemonExtension: 'png', trainerSpriteSet: 'gbc', protagonistAsset: 'assets/sprites/characters/protagonists/ethan_gold_silver.png', rivalAsset: 'assets/sprites/characters/rivals/silver_johto.png', championAsset: 'assets/sprites/characters/champions/lance_johto.png', sourceTitle: value);
    }
    if (value.contains('plata') || value.contains('silver')) {
      return GameAssetProfile(game: PokemonAssetGame.silver, region: PokemonAssetRegion.johto, pokemonSpriteSet: savedSpriteSet ?? 'gbc/silver', pokemonExtension: 'png', trainerSpriteSet: 'gbc', protagonistAsset: 'assets/sprites/characters/protagonists/ethan_gold_silver.png', rivalAsset: 'assets/sprites/characters/rivals/silver_johto.png', championAsset: 'assets/sprites/characters/champions/lance_johto.png', sourceTitle: value);
    }
    if (value.contains('esmeralda') || value.contains('emerald')) {
      return GameAssetProfile(game: PokemonAssetGame.emerald, region: PokemonAssetRegion.hoenn, pokemonSpriteSet: savedSpriteSet ?? 'gba/emerald', pokemonExtension: 'gif', trainerSpriteSet: 'gba/Hoenn', protagonistAsset: 'assets/sprites/characters/protagonists/brendan_emerald.png', rivalAsset: 'assets/sprites/characters/rivals/may_emerald.png', championAsset: 'assets/sprites/characters/champions/wallace_hoenn.png', sourceTitle: value);
    }
    if (value.contains('ruby') || value.contains('rubi') || value.contains('rubí') || value.contains('sapphire') || value.contains('zafiro')) {
      return GameAssetProfile(game: PokemonAssetGame.rubySapphire, region: PokemonAssetRegion.hoenn, pokemonSpriteSet: savedSpriteSet ?? 'gba/ruby_sapphire', pokemonExtension: 'png', trainerSpriteSet: 'gba/Hoenn', protagonistAsset: 'assets/sprites/characters/protagonists/brendan_ruby_sapphire.png', rivalAsset: 'assets/sprites/characters/rivals/may_ruby_sapphire.png', championAsset: 'assets/sprites/characters/champions/steven_hoenn.png', sourceTitle: value);
    }
    if (value.contains('fire') || value.contains('leaf') || value.contains('rojo fuego') || value.contains('verde hoja')) {
      return GameAssetProfile(game: PokemonAssetGame.fireRedLeafGreen, region: PokemonAssetRegion.kanto, pokemonSpriteSet: savedSpriteSet ?? 'gba/fire_red_leaf_green', pokemonExtension: 'png', trainerSpriteSet: 'gba/Kanto', protagonistAsset: 'assets/sprites/characters/protagonists/red_fire_red_leaf_green.png', rivalAsset: 'assets/sprites/characters/rivals/blue_kanto_frlg.png', championAsset: 'assets/sprites/characters/champions/blue_kanto_frlg.png', sourceTitle: value);
    }
    if (value.contains('rojo') || value.contains('red') || value.contains('azul') || value.contains('blue')) {
      return GameAssetProfile(game: PokemonAssetGame.redBlue, region: PokemonAssetRegion.kanto, pokemonSpriteSet: savedSpriteSet ?? 'gb/red_blue', pokemonExtension: 'png', trainerSpriteSet: 'gb', protagonistAsset: 'assets/sprites/characters/protagonists/red_red_blue.png', rivalAsset: 'assets/sprites/characters/rivals/blue_kanto.png', championAsset: 'assets/sprites/characters/champions/blue_kanto.png', sourceTitle: value);
    }

    final normalizedConsole = console.toLowerCase();
    return GameAssetProfile(game: PokemonAssetGame.unsupported, region: PokemonAssetRegion.unknown, pokemonSpriteSet: savedSpriteSet ?? 'gb/red_blue', pokemonExtension: 'png', trainerSpriteSet: normalizedConsole == 'gbc' ? 'gbc' : normalizedConsole == 'gba' ? 'gba/Hoenn' : 'gb', sourceTitle: value);
  }
}
