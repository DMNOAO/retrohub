import 'game_asset_profile.dart';

class BadgeAsset {
  final int index;
  final String key;
  final String displayName;
  final String path;

  const BadgeAsset({
    required this.index,
    required this.key,
    required this.displayName,
    required this.path,
  });
}

class BadgeAssetResolver {
  const BadgeAssetResolver._();

  static const _kanto = <(String, String)>[
    ('boulder', 'Medalla Roca'),
    ('cascade', 'Medalla Cascada'),
    ('thunder', 'Medalla Trueno'),
    ('rainbow', 'Medalla Arcoíris'),
    ('soul', 'Medalla Alma'),
    ('marsh', 'Medalla Pantano'),
    ('volcano', 'Medalla Volcán'),
    ('earth', 'Medalla Tierra'),
  ];

  static const _johto = <(String, String)>[
    ('zephyr', 'Medalla Céfiro'),
    ('hive', 'Medalla Colmena'),
    ('plain', 'Medalla Planicie'),
    ('fog', 'Medalla Niebla'),
    ('storm', 'Medalla Tormenta'),
    ('mineral', 'Medalla Mineral'),
    ('glacier', 'Medalla Glaciar'),
    ('rising', 'Medalla Dragón'),
  ];

  static const _hoenn = <(String, String)>[
    ('stone', 'Medalla Piedra'),
    ('knuckle', 'Medalla Puño'),
    ('dynamo', 'Medalla Dinamo'),
    ('heat', 'Medalla Calor'),
    ('balance', 'Medalla Equilibrio'),
    ('feather', 'Medalla Pluma'),
    ('mind', 'Medalla Mente'),
    ('rain', 'Medalla Lluvia'),
  ];

  static BadgeAsset resolve(GameAssetProfile profile, int index) {
    return resolveForRegion(profile.region, index);
  }

  static BadgeAsset resolveForRegion(PokemonAssetRegion region, int index) {
    final safeIndex = index.clamp(0, 7).toInt();
    final values = switch (region) {
      PokemonAssetRegion.johto => _johto,
      PokemonAssetRegion.hoenn => _hoenn,
      _ => _kanto,
    };
    final folder = switch (region) {
      PokemonAssetRegion.johto => 'Johto',
      PokemonAssetRegion.hoenn => 'Hoenn',
      _ => 'Kanto',
    };
    final item = values[safeIndex];
    return BadgeAsset(
      index: safeIndex,
      key: item.$1,
      displayName: item.$2,
      path: 'assets/sprites/badges/$folder/${item.$1}.png',
    );
  }
}
