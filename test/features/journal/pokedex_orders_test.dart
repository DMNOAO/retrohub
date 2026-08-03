import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/features/journal/pokedex_orders.dart';

void main() {
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
}
