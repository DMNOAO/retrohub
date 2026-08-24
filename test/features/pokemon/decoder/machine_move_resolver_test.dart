import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/core/assets/game_asset_profile.dart';
import 'package:retrohub/features/pokemon/decoder/machine_move_resolver.dart';

void main() {
  test('identifica los tres movimientos del tutor de Cristal', () {
    final profile = GameAssetProfile.fromTitle(
      title: 'Pokémon Cristal',
      console: 'GBC',
    );

    expect(MachineMoveResolver.label(profile, 53), 'Tutor');
    expect(MachineMoveResolver.label(profile, 58), 'Tutor');
    expect(MachineMoveResolver.label(profile, 85), 'Tutor');
  });

  test('mantiene los números de MT de tercera generación', () {
    final profile = GameAssetProfile.fromTitle(
      title: 'Pokémon Esmeralda',
      console: 'GBA',
    );

    expect(MachineMoveResolver.label(profile, 58), 'MT 13');
    expect(MachineMoveResolver.label(profile, 85), 'MT 24');
    expect(MachineMoveResolver.label(profile, 53), 'MT 35');
  });
}
