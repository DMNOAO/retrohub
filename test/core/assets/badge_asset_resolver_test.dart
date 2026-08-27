import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/core/assets/badge_asset_resolver.dart';
import 'package:retrohub/core/assets/game_asset_profile.dart';

void main() {
  test('respeta el orden de medallas de Diamante y Perla', () {
    final profile = GameAssetProfile.fromTitle(
      title: 'Pokémon Diamante',
      console: 'NDS',
    );

    expect(BadgeAssetResolver.resolve(profile, 2).key, 'cobble');
    expect(BadgeAssetResolver.resolve(profile, 4).key, 'relic');
  });

  test('respeta el orden de medallas de Platino', () {
    final profile = GameAssetProfile.fromTitle(
      title: 'Pokémon Platino',
      console: 'NDS',
    );

    expect(BadgeAssetResolver.resolve(profile, 2).key, 'relic');
    expect(BadgeAssetResolver.resolve(profile, 3).key, 'cobble');
    expect(
      BadgeAssetResolver.resolve(profile, 2).path,
      'assets/sprites/badges/Sinnoh/relic.png',
    );
  });

  test('usa las medallas propias de Negro 2 y Blanco 2', () {
    final profile = GameAssetProfile.fromTitle(
      title: 'Pokémon Negro 2',
      console: 'NDS',
    );

    expect(BadgeAssetResolver.resolve(profile, 0).key, 'basic');
    expect(BadgeAssetResolver.resolve(profile, 1).key, 'toxic');
    expect(BadgeAssetResolver.resolve(profile, 6).key, 'legend');
    expect(BadgeAssetResolver.resolve(profile, 7).key, 'wave');
    expect(BadgeAssetResolver.resolve(profile, 7).displayName, 'Medalla Ola');
  });
}
