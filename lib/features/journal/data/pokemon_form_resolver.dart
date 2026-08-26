import '../../../core/assets/game_asset_profile.dart';

class PokemonFormInfo {
  final String id;
  final String label;
  final String? suffix;
  final bool female;

  const PokemonFormInfo({
    required this.id,
    required this.label,
    this.suffix,
    this.female = false,
  });
}

abstract final class PokemonFormResolver {
  static bool _supportsGen3(GameAssetProfile profile) =>
      profile.game == PokemonAssetGame.rubySapphire ||
      profile.game == PokemonAssetGame.emerald ||
      profile.game == PokemonAssetGame.fireRedLeafGreen;

  static bool _supportsGen4(GameAssetProfile profile) =>
      profile.game == PokemonAssetGame.diamondPearl ||
      profile.game == PokemonAssetGame.platinum ||
      profile.game == PokemonAssetGame.heartGoldSoulSilver;

  static bool _supportsAlternateForms(GameAssetProfile profile) =>
      _supportsGen3(profile) || _supportsGen4(profile);

  static List<PokemonFormInfo> forPokemon(
    GameAssetProfile profile,
    int pokemonId,
  ) {
    if (!_supportsAlternateForms(profile)) return const <PokemonFormInfo>[];

    if (pokemonId == 201) {
      return <PokemonFormInfo>[
        const PokemonFormInfo(id: 'unown-a', label: 'A', suffix: 'a'),
        for (var code = 98; code <= 122; code++)
          PokemonFormInfo(
            id: 'unown-${String.fromCharCode(code)}',
            label: String.fromCharCode(code).toUpperCase(),
            suffix: String.fromCharCode(code),
          ),
        const PokemonFormInfo(id: 'unown-exclamation', label: '!', suffix: 'exclamation'),
        const PokemonFormInfo(id: 'unown-question', label: '?', suffix: 'question'),
      ];
    }

    final forms = <int, List<PokemonFormInfo>>{
      386: const [
        PokemonFormInfo(id: 'normal', label: 'Normal'),
        PokemonFormInfo(id: 'attack', label: 'Ataque', suffix: 'attack'),
        PokemonFormInfo(id: 'defense', label: 'Defensa', suffix: 'defense'),
        PokemonFormInfo(id: 'speed', label: 'Velocidad', suffix: 'speed'),
      ],
      412: const [
        PokemonFormInfo(id: 'plant', label: 'Planta'),
        PokemonFormInfo(id: 'sandy', label: 'Arena', suffix: 'sandy'),
        PokemonFormInfo(id: 'trash', label: 'Basura', suffix: 'trash'),
      ],
      413: const [
        PokemonFormInfo(id: 'plant', label: 'Planta'),
        PokemonFormInfo(id: 'sandy', label: 'Arena', suffix: 'sandy'),
        PokemonFormInfo(id: 'trash', label: 'Basura', suffix: 'trash'),
      ],
      421: const [
        PokemonFormInfo(id: 'overcast', label: 'Encapotada'),
        PokemonFormInfo(id: 'sunshine', label: 'Soleada', suffix: 'sunshine'),
      ],
      422: const [
        PokemonFormInfo(id: 'west', label: 'Oeste'),
        PokemonFormInfo(id: 'east', label: 'Este', suffix: 'east'),
      ],
      423: const [
        PokemonFormInfo(id: 'west', label: 'Oeste'),
        PokemonFormInfo(id: 'east', label: 'Este', suffix: 'east'),
      ],
      479: const [
        PokemonFormInfo(id: 'normal', label: 'Normal'),
        PokemonFormInfo(id: 'heat', label: 'Calor', suffix: 'heat'),
        PokemonFormInfo(id: 'wash', label: 'Lavado', suffix: 'wash'),
        PokemonFormInfo(id: 'frost', label: 'Frío', suffix: 'frost'),
        PokemonFormInfo(id: 'fan', label: 'Ventilador', suffix: 'fan'),
        PokemonFormInfo(id: 'mow', label: 'Corte', suffix: 'mow'),
      ],
      487: const [
        PokemonFormInfo(id: 'altered', label: 'Modificada'),
        PokemonFormInfo(id: 'origin', label: 'Origen', suffix: 'origin'),
      ],
      492: const [
        PokemonFormInfo(id: 'land', label: 'Tierra'),
        PokemonFormInfo(id: 'sky', label: 'Cielo', suffix: 'sky'),
      ],
    };

    final result = <PokemonFormInfo>[...?forms[pokemonId]];
    if (_supportsGen4(profile) && _femaleSpriteIds.contains(pokemonId)) {
      result.add(const PokemonFormInfo(id: 'female', label: 'Hembra', female: true));
    }
    return result;
  }

  static const Set<int> _femaleSpriteIds = <int>{
    3, 12, 19, 20, 25, 26, 41, 42, 44, 45, 64, 65, 84, 85, 97,
    111, 112, 118, 119, 123, 129, 130, 154, 165, 166, 178, 185,
    186, 190, 194, 195, 198, 202, 203, 207, 208, 212, 214, 215,
    217, 221, 224, 229, 232, 255, 256, 257, 267, 269, 272, 274,
    275, 307, 308, 315, 316, 317, 322, 323, 332, 350, 369, 396,
    397, 398, 399, 400, 401, 402, 403, 404, 405, 407, 415, 417,
    418, 419, 424, 443, 444, 445, 449, 450, 453, 454, 456, 457,
    459, 460, 461, 464, 465, 473,
  };
}
