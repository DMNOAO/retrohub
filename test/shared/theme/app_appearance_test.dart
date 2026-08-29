import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/shared/theme/app_appearance.dart';

void main() {
  test('las paletas de las portadas conservan sus acentos legendarios', () {
    expect(AppAppearance.crystal.secondary, const Color(0xFF9D75EA));
    expect(AppAppearance.ruby.secondary, const Color(0xFF3C8DFF));
    expect(AppAppearance.sapphire.secondary, const Color(0xFFFF5A5F));
  });

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
