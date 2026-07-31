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
    return 'assets/sprites/characters/trainers/${profile.trainerSpriteSet}/${_normalize(trainerClass)}.png';
  }

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
