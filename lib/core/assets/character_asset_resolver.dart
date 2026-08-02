import 'game_asset_profile.dart';

class CharacterAssetResolver {
  const CharacterAssetResolver._();

  static String? protagonist(GameAssetProfile profile) => profile.protagonistAsset;
  static String? rival(GameAssetProfile profile) => profile.rivalAsset;
  static String? champion(GameAssetProfile profile) => profile.championAsset;

  static String trainer({
    required GameAssetProfile profile,
    required String trainerClass,
  }) {
    final normalized = _normalize(trainerClass);
    final fileName = _trainerFileNames[normalized] ?? normalized;
    return 'assets/sprites/characters/trainers/${profile.trainerSpriteSet}/$fileName.png';
  }

  // Las clases se muestran en español, pero los assets usan nombres
  // definitivos en inglés. Esta tabla también permite reconstruir sprites
  // de eventos guardados antes de que se persistiera spritePath.
  static const Map<String, String> _trainerFileNames = <String, String>{
    'bella': 'beauty',
    'caballero': 'gentleman',
    'calvo': 'cue_ball',
    'campista': 'camper',
    'cazabichos': 'bug_catcher',
    'chica': 'lass',
    'senorita': 'lass',
    'domador': 'tamer',
    'dominguera': 'picnicker',
    'excursionista_campo': 'picnicker',
    'entrenador_guay': 'cooltrainer_male',
    'mister_genial': 'cooltrainer_male',
    'entrenadora_guay': 'cooltrainer_female',
    'miss_genial': 'cooltrainer_female',
    'exorcista': 'channeler',
    'joven': 'youngster',
    'jugon': 'gambler',
    'karateka': 'black_belt',
    'cinturon_negro': 'black_belt',
    'ladron': 'burglar',
    'malabarista': 'juggler',
    'marinero': 'sailor',
    'mecanico': 'engineer',
    'medium': 'medium',
    'mentalista': 'psychic',
    'medium_psiquico': 'psychic',
    'excursionista': 'hiker',
    'montanero': 'hiker',
    'motorista': 'biker',
    'nadador': 'swimmer_male',
    'nadadora': 'swimmer_female',
    'ave_cuidador': 'bird_keeper',
    'ornitologo': 'bird_keeper',
    'pescador': 'fisherman',
    'fanatico_pokemon': 'pokemaniac',
    'pokemaniaco': 'pokemaniac',
    'rockero': 'rocker',
    'empollon': 'super_nerd',
    'supernecio': 'super_nerd',
    'colegial': 'schoolboy',
    'escolar': 'schoolboy',
    'esquiadora': 'skier',
    'profesora': 'teacher',
    'guitarrista': 'guitarist',
    'lanzallamas': 'firebreather',
    'comefuego': 'firebreather',
    'sabio': 'sage',
    'pensador': 'sage',
    'snowboarder': 'snowboarder',
    'aficionado_pokemon_m': 'pokefan_male',
    'aficionada_pokemon_f': 'pokefan_female',
    'chica_kimono': 'kimono_girl',
    'gemelas': 'twins',
    'oficial': 'officer',
    'policia': 'officer',
  };

  static String specialTrainer(String key) {
    final normalized = _normalize(key);
    if (normalized == 'red_mt_silver' || normalized == 'eusine') {
      return 'assets/sprites/characters/special_trainers/$normalized.png';
    }
    return 'assets/sprites/characters/special_trainers/battle_frontier/emerald/$normalized.png';
  }

  static String villain({required String team, required String character}) {
    return 'assets/sprites/characters/villains/${_normalize(team)}/${_normalize(character)}.png';
  }

  static String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }
}
