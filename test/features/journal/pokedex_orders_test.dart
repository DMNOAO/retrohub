import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/features/journal/pokedex_orders.dart';

void main() {
  test('Teselia conserva a Victini como número regional 000', () {
    expect(unovaBlackWhitePokedexOrder, hasLength(156));
    expect(unovaBlackWhitePokedexOrder.first, 494);
    expect(unovaBlackWhitePokedexOrder[1], 495);
    expect(unovaBlackWhitePokedexOrder.last, 649);
  });

  test('Hoenn keeps the official 202-species regional order', () {
    expect(hoennPokedexOrder, hasLength(202));
    expect(hoennPokedexOrder.toSet(), hasLength(202));
    expect(hoennPokedexOrder.take(9), <int>[252, 253, 254, 255, 256, 257, 258, 259, 260]);
    expect(hoennPokedexOrder.skip(198), <int>[383, 384, 385, 386]);
  });

  test('regional counters ignore species outside the Hoenn Pokédex', () {
    expect(
      pokedexIdsInOrder(<int>[1, 25, 252, 386], hoennPokedexOrder),
      <int>{25, 252, 386},
    );
  });

  test('Sinnoh regional Pokédexes keep their game-specific sizes', () {
    expect(sinnohDiamondPearlPokedexOrder, hasLength(151));
    expect(sinnohDiamondPearlPokedexOrder.toSet(), hasLength(151));
    expect(sinnohPlatinumPokedexOrder, hasLength(210));
    expect(sinnohPlatinumPokedexOrder.toSet(), hasLength(210));
    expect(sinnohDiamondPearlPokedexOrder.first, 387);
    expect(sinnohDiamondPearlPokedexOrder.last, 490);
    expect(sinnohPlatinumPokedexOrder.last, 487);
  });

  test('HGSS keeps the updated 256-species Johto order', () {
    expect(johtoHeartGoldSoulSilverPokedexOrder, hasLength(256));
    expect(johtoHeartGoldSoulSilverPokedexOrder.toSet(), hasLength(256));
    expect(
      johtoHeartGoldSoulSilverPokedexOrder.take(9),
      <int>[152, 153, 154, 155, 156, 157, 158, 159, 160],
    );
    expect(johtoHeartGoldSoulSilverPokedexOrder.last, 251);
    expect(johtoHeartGoldSoulSilverPokedexOrder, containsAll(<int>[424, 469, 473]));
  });
}
