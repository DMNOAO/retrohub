import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/shared/theme/app_appearance.dart';

void main() {
  group('AppAppearance.forGameTitle', () {
    test('distingue los remakes de Oro y Plata originales', () {
      expect(AppAppearance.forGameTitle('Pokémon HeartGold'), AppAppearance.heartGold);
      expect(AppAppearance.forGameTitle('Pokémon SoulSilver'), AppAppearance.soulSilver);
      expect(AppAppearance.forGameTitle('Pokémon Oro'), AppAppearance.gold);
      expect(AppAppearance.forGameTitle('Pokémon Plata'), AppAppearance.silver);
    });

    test('distingue las secuelas de Blanco y Negro', () {
      expect(AppAppearance.forGameTitle('Pokémon Blanco 2'), AppAppearance.white2);
      expect(AppAppearance.forGameTitle('Pokémon Negro 2'), AppAppearance.black2);
      expect(AppAppearance.forGameTitle('Pokémon Blanco'), AppAppearance.white);
      expect(AppAppearance.forGameTitle('Pokémon Negro'), AppAppearance.black);
    });
  });
}
