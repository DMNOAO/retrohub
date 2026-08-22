import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/core/assets/game_asset_profile.dart';
import 'package:retrohub/features/journal/data/pokedex_detail_data.dart';

void main() {
  test('Charmander usa la ficha de Rojo Fuego y Verde Hoja', () {
    final profile = GameAssetProfile.fromTitle(
      title: 'Pokemon_Rojo_Fuego',
      console: 'GBA',
    );
    final detail = PokedexDetailData.forGame(profile, 4);

    expect(detail.entry, isNotEmpty);
    expect(detail.levelMoves.any((move) => move.name == 'Garra Metal'), isTrue);
    expect(
      detail.machineMoves.any((move) => move.name == 'Lanzallamas'),
      isTrue,
    );
    expect(
      detail.encounters.any((encounter) => encounter.location == 'Pueblo Paleta'),
      isTrue,
    );
  });
}
