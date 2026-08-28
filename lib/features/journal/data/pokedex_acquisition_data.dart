import '../../../core/assets/game_asset_profile.dart';
import '../../pokemon/decoder/pokemon_decoder.dart';
import 'pokedex_models.dart';

class PokedexAcquisitionData {
  const PokedexAcquisitionData._();

  static List<PokedexAcquisition> forGame(
    GameAssetProfile profile,
    int pokemonId,
  ) => switch (profile.game) {
    PokemonAssetGame.redBlue || PokemonAssetGame.yellow =>
      _kanto(profile, pokemonId),
    PokemonAssetGame.gold ||
    PokemonAssetGame.silver ||
    PokemonAssetGame.crystal => _johto(profile, pokemonId),
    _ => const <PokedexAcquisition>[],
  };

  static List<PokedexAcquisition> _kanto(
    GameAssetProfile profile,
    int pokemonId,
  ) {
    final yellow = profile.game == PokemonAssetGame.yellow;
    final blue = !yellow && _isBlue(profile);
    final result = <PokedexAcquisition>[
      ...?_kantoStory(profile, pokemonId),
      ...?_kantoTrade(yellow, pokemonId),
      ...?_kantoPrize(yellow: yellow, blue: blue, pokemonId: pokemonId),
    ];
    final unavailable = _kantoUnavailable(
      yellow: yellow,
      blue: blue,
      pokemonId: pokemonId,
    );
    if (unavailable != null) result.add(unavailable);
    return result;
  }

  static List<PokedexAcquisition>? _kantoStory(
    GameAssetProfile profile,
    int pokemonId,
  ) {
    final yellow = profile.game == PokemonAssetGame.yellow;
    if (!yellow && const {1, 4, 7}.contains(pokemonId)) {
      return [
        _choice(
          'Pueblo Paleta · Laboratorio del Profesor Oak',
          'Elige a ${PokemonDecoder.pokemonName(pokemonId)} como inicial. Solo puedes escoger uno entre Bulbasaur, Charmander y Squirtle.',
        ),
      ];
    }
    if (yellow) {
      switch (pokemonId) {
        case 1:
          return [
            _gift('Ciudad Celeste', 'Una cuidadora te entrega a Bulbasaur cuando Pikachu tiene suficiente amistad.'),
          ];
        case 4:
          return [
            _gift('Ruta 24', 'Un entrenador te entrega a Charmander para que lo cuides.'),
          ];
        case 7:
          return [
            _gift('Ciudad Carmín', 'La Agente Mara te entrega a Squirtle después de conseguir la Medalla Trueno.'),
          ];
        case 25:
          return [
            _gift('Pueblo Paleta · Laboratorio del Profesor Oak', 'Pokémon inicial de esta edición. Este Pikachu se niega a evolucionar.'),
          ];
      }
    }
    switch (pokemonId) {
      case 106:
      case 107:
        return [
          _choice('Dojo Karate · Ciudad Azafrán', 'Premio tras vencer al Maestro Karateka. Debes elegir entre Hitmonlee y Hitmonchan.'),
        ];
      case 129:
        return [_purchase('Centro Pokémon de la Ruta 4', 'Un vendedor ofrece un Magikarp por 500 ₽.')];
      case 131:
        return [_gift('Silph S.A. · Ciudad Azafrán', 'Un empleado te entrega a Lapras durante la incursión del Team Rocket.')];
      case 133:
        return [_gift('Mansión Azulona · Ciudad Azulona', 'Entra por la puerta trasera y recoge la Poké Ball de Eevee en la azotea.')];
      case 138:
        return [_fossil('Monte Moon → Laboratorio Pokémon de Isla Canela', 'Elige el Fósil Helix y entrégalo en el laboratorio para revivir a Omanyte.')];
      case 140:
        return [_fossil('Monte Moon → Laboratorio Pokémon de Isla Canela', 'Elige el Fósil Domo y entrégalo en el laboratorio para revivir a Kabuto.')];
      case 142:
        return [_fossil('Museo de Ciudad Plateada → Laboratorio de Isla Canela', 'Consigue el Ámbar Viejo y entrégalo en el laboratorio para revivir a Aerodactyl.')];
      case 143:
        return [_static('Rutas 12 y 16', 'Despierta a uno de los dos Snorlax con la Poké Flauta.')];
      case 144:
        return [_static('Islas Espuma', 'Encuentro único con Articuno.')];
      case 145:
        return [_static('Central de Energía', 'Encuentro único con Zapdos.')];
      case 146:
        return [_static('Calle Victoria', 'Encuentro único con Moltres.')];
      case 150:
        return [_static('Cueva Celeste', 'Encuentro único con Mewtwo, disponible después de superar la Liga Pokémon.')];
      case 151:
        return [_event('Distribución oficial', 'Mew no puede encontrarse durante la aventura normal; requiere un evento oficial o intercambio.')];
    }
    return null;
  }

  static List<PokedexAcquisition>? _kantoTrade(bool yellow, int pokemonId) {
    final trade = (yellow ? _yellowTrades : _redBlueTrades)[pokemonId];
    if (trade == null) return null;
    return [
      PokedexAcquisition(
        method: 'Intercambio con NPC',
        location: trade.$1,
        detail: 'Entrega ${trade.$2} para recibir a ${PokemonDecoder.pokemonName(pokemonId)}${trade.$3}.',
      ),
    ];
  }

  static List<PokedexAcquisition>? _kantoPrize({
    required bool yellow,
    required bool blue,
    required int pokemonId,
  }) {
    final prizes = yellow ? _yellowPrizes : blue ? _bluePrizes : _redPrizes;
    final coins = prizes[pokemonId];
    if (coins == null) return null;
    return [_prize('Casino de Ciudad Azulona', 'Canjea $coins fichas para recibir a ${PokemonDecoder.pokemonName(pokemonId)}.')];
  }

  static PokedexAcquisition? _kantoUnavailable({
    required bool yellow,
    required bool blue,
    required int pokemonId,
  }) {
    final source = yellow
        ? _yellowMissing[pokemonId]
        : blue
        ? (_redExclusiveIds.contains(pokemonId) ? 'Pokémon Rojo' : null)
        : (_blueExclusiveIds.contains(pokemonId) ? 'Pokémon Azul' : null);
    if (source == null) return null;
    return _otherVersion(source, '${PokemonDecoder.pokemonName(pokemonId)} no puede obtenerse directamente en esta edición. Debes intercambiarlo desde $source.');
  }

  static List<PokedexAcquisition> _johto(
    GameAssetProfile profile,
    int pokemonId,
  ) {
    final result = <PokedexAcquisition>[
      if (profile.game == PokemonAssetGame.crystal &&
          _oddEggIds.contains(pokemonId))
        const PokedexAcquisition(
          method: 'Huevo regalo · Resultado aleatorio',
          location: 'Guardería Pokémon · Ruta 34',
          detail:
              'Puede eclosionar del Huevo Raro en Pokémon Cristal. La especie se determina al recibir el huevo.',
        ),
      ...?_johtoStory(profile, pokemonId),
      ...?_johtoTrade(profile, pokemonId),
      ...?_johtoPrize(profile, pokemonId),
    ];
    final unavailable = _johtoUnavailable(profile, pokemonId);
    if (unavailable != null) result.add(unavailable);
    if (_timeCapsuleIds.contains(pokemonId)) {
      result.add(
        PokedexAcquisition(
          method: 'Cápsula del Tiempo',
          location: 'Intercambio desde Rojo, Azul o Amarillo',
          detail: '${PokemonDecoder.pokemonName(pokemonId)} no aparece en las ediciones de Johto. Debes transferirlo desde un juego de primera generación.',
        ),
      );
    }
    return result;
  }

  static List<PokedexAcquisition>? _johtoStory(
    GameAssetProfile profile,
    int pokemonId,
  ) {
    final crystal = profile.game == PokemonAssetGame.crystal;
    if (const {152, 155, 158}.contains(pokemonId)) {
      return [
        _choice('Pueblo Primavera · Laboratorio del Profesor Elm', 'Elige a ${PokemonDecoder.pokemonName(pokemonId)} como inicial. Solo puedes escoger uno entre Chikorita, Cyndaquil y Totodile.'),
      ];
    }
    switch (pokemonId) {
      case 21:
        return [_gift('Acceso sur de la Ruta 35', 'Te confían temporalmente a Kenya, un Spearow con correo para entregar en la Ruta 31.')];
      case 100:
        return [_static('Guarida del Team Rocket · Pueblo Caoba', 'Tres Electrode alimentan el generador y pueden ser combatidos o capturados.')];
      case 130:
        return [_static('Lago de la Furia', 'Encuentro único con el Gyarados rojo variocolor.')];
      case 131:
        return [const PokedexAcquisition(method: 'Encuentro único semanal', location: 'Cueva Unión · Planta B2', detail: 'Aparece los viernes después de conseguir la Medalla Planicie.')];
      case 133:
        return [_gift('Ciudad Trigal', 'Bill te entrega a Eevee en su casa después de conocerlo en Ciudad Iris.')];
      case 143:
        return [_static('Ciudad Carmín', 'Despierta a Snorlax con la emisión de la Poké Flauta de la Radio de Kanto.')];
      case 147:
        if (!crystal) return null;
        return [_gift('Guarida Dragón', 'El Maestro te entrega a Dratini. Si respondes correctamente su prueba, conocerá Velocidad Extrema.')];
      case 175:
        return [const PokedexAcquisition(method: 'Huevo regalo', location: 'Centro Pokémon de Ciudad Malva', detail: 'El ayudante del Profesor Elm te entrega el Huevo Misterioso después de vencer a Pegaso; eclosiona en Togepi.')];
      case 185:
        return [_static('Ruta 36', 'Usa la Regadera para revelar y combatir al Sudowoodo que bloquea el camino.')];
      case 213:
        return [_gift('Ciudad Orquídea', 'Mania te confía a Shuckie para protegerlo. Puede pedir que lo devuelvas más adelante.')];
      case 236:
        return [_gift('Monte Mortero', 'Kiyo te entrega a Tyrogue después de vencerlo. Necesitas un espacio libre en el equipo.')];
      case 243:
      case 244:
        return [_roaming('Johto', 'Comienza a recorrer las rutas después del encuentro en la Torre Quemada.')];
      case 245:
        return [
          crystal
              ? _static('Torre Hojalata', 'Encuentro único con Suicune después de completar la historia del Claro Bell.')
              : _roaming('Johto', 'Comienza a recorrer las rutas después del encuentro en la Torre Quemada.'),
        ];
      case 249:
        return [_static('Islas Remolino', 'Encuentro único con Lugia. Requiere el Ala Plateada y usar Torbellino.')];
      case 250:
        return [_static('Torre Hojalata', 'Encuentro único con Ho-Oh. Requiere el Ala Arcoíris.')];
      case 251:
        return [
          _event(
            crystal ? 'Encinar · Santuario del Bosque' : 'Distribución oficial',
            crystal
                ? 'El evento de la GS Ball permite combatir y capturar a Celebi. En cartuchos occidentales originales requiere activación de evento.'
                : 'Celebi no aparece durante la aventura normal de Oro o Plata; requiere una distribución oficial o intercambio.',
          ),
        ];
    }
    return null;
  }

  static List<PokedexAcquisition>? _johtoTrade(
    GameAssetProfile profile,
    int pokemonId,
  ) {
    final crystal = profile.game == PokemonAssetGame.crystal;
    final trade = _johtoCommonTrades[pokemonId] ??
        (crystal ? _crystalTrades : _goldSilverTrades)[pokemonId];
    if (trade == null) return null;
    return [
      PokedexAcquisition(
        method: 'Intercambio con NPC',
        location: trade.$1,
        detail: 'Entrega ${trade.$2} para recibir a ${PokemonDecoder.pokemonName(pokemonId)}.',
      ),
    ];
  }

  static List<PokedexAcquisition>? _johtoPrize(
    GameAssetProfile profile,
    int pokemonId,
  ) {
    final crystal = profile.game == PokemonAssetGame.crystal;
    final gold = profile.game == PokemonAssetGame.gold;
    final prizes = <int, (String, int)>{
      if (crystal) ..._crystalPrizes else ..._goldSilverPrizes,
      if (gold) 23: ('Casino de Ciudad Trigal', 700),
      if (profile.game == PokemonAssetGame.silver) 27: ('Casino de Ciudad Trigal', 700),
    };
    final prize = prizes[pokemonId];
    if (prize == null) return null;
    return [_prize(prize.$1, 'Canjea ${prize.$2} fichas para recibir a ${PokemonDecoder.pokemonName(pokemonId)}.')];
  }

  static PokedexAcquisition? _johtoUnavailable(
    GameAssetProfile profile,
    int pokemonId,
  ) {
    String? source;
    if (profile.game == PokemonAssetGame.gold && _silverOnlyIds.contains(pokemonId)) {
      source = 'Pokémon Plata';
    } else if (profile.game == PokemonAssetGame.silver && _goldOnlyIds.contains(pokemonId)) {
      source = 'Pokémon Oro';
    } else if (profile.game == PokemonAssetGame.crystal) {
      source = _crystalMissing[pokemonId];
    }
    if (source == null) return null;
    return _otherVersion(source, '${PokemonDecoder.pokemonName(pokemonId)} no aparece en esta edición. Debes intercambiarlo desde $source.');
  }

  static bool _isBlue(GameAssetProfile profile) {
    final title = (profile.sourceTitle ?? '').toLowerCase();
    return title.contains('azul') || title.contains('blue');
  }

  static PokedexAcquisition _gift(String location, String detail) => PokedexAcquisition(method: 'Regalo', location: location, detail: detail);
  static PokedexAcquisition _choice(String location, String detail) => PokedexAcquisition(method: 'Regalo · Elección', location: location, detail: detail);
  static PokedexAcquisition _purchase(String location, String detail) => PokedexAcquisition(method: 'Compra', location: location, detail: detail);
  static PokedexAcquisition _fossil(String location, String detail) => PokedexAcquisition(method: 'Restauración de fósil', location: location, detail: detail);
  static PokedexAcquisition _static(String location, String detail) => PokedexAcquisition(method: 'Encuentro único', location: location, detail: detail);
  static PokedexAcquisition _roaming(String location, String detail) => PokedexAcquisition(method: 'Pokémon errante', location: location, detail: detail);
  static PokedexAcquisition _event(String location, String detail) => PokedexAcquisition(method: 'Evento', location: location, detail: detail);
  static PokedexAcquisition _prize(String location, String detail) => PokedexAcquisition(method: 'Premio por fichas', location: location, detail: detail);
  static PokedexAcquisition _otherVersion(String location, String detail) => PokedexAcquisition(method: 'Otra versión', location: location, detail: detail);

  static const Map<int, (String, String, String)> _redBlueTrades = {
    29: ('Pasadizo Subterráneo · Rutas 5–6', 'un Nidoran♂', ''),
    30: ('Ruta 11', 'un Nidorino', ''),
    83: ('Ciudad Carmín', 'un Spearow', ''),
    86: ('Laboratorio Pokémon · Isla Canela', 'un Ponyta', ''),
    101: ('Laboratorio Pokémon · Isla Canela', 'un Raichu', ''),
    108: ('Ruta 18', 'un Slowbro', ''),
    114: ('Laboratorio Pokémon · Isla Canela', 'un Venonat', ''),
    122: ('Ruta 2', 'un Abra', ''),
    124: ('Ciudad Celeste', 'un Poliwhirl', ''),
  };
  static const Map<int, (String, String, String)> _yellowTrades = {
    47: ('Ruta 18', 'un Tangela', ''),
    51: ('Ruta 11', 'un Lickitung', ''),
    68: ('Pasadizo Subterráneo · Rutas 5–6', 'un Cubone', '; el Machoke recibido evoluciona inmediatamente'),
    87: ('Laboratorio Pokémon · Isla Canela', 'un Growlithe', ''),
    89: ('Laboratorio Pokémon · Isla Canela', 'un Kangaskhan', ''),
    112: ('Laboratorio Pokémon · Isla Canela', 'un Golduck', ''),
    122: ('Ruta 2', 'un Clefairy', ''),
  };

  static const Map<int, int> _redPrizes = {63: 180, 35: 500, 30: 1200, 147: 2800, 123: 5500, 137: 9999};
  static const Map<int, int> _bluePrizes = {63: 120, 35: 750, 33: 1200, 127: 2500, 147: 4600, 137: 6500};
  static const Map<int, int> _yellowPrizes = {63: 230, 37: 1000, 40: 2680, 123: 6500, 127: 6500, 137: 9999};

  static const Set<int> _redExclusiveIds = {23, 24, 43, 44, 45, 56, 57, 58, 59, 123, 125};
  static const Set<int> _blueExclusiveIds = {27, 28, 37, 38, 52, 53, 69, 70, 71, 126, 127};
  static const Map<int, String> _yellowMissing = {
    13: 'Pokémon Rojo o Azul', 14: 'Pokémon Rojo o Azul', 15: 'Pokémon Rojo o Azul',
    23: 'Pokémon Rojo', 24: 'Pokémon Rojo', 26: 'Pokémon Rojo o Azul',
    52: 'Pokémon Azul', 53: 'Pokémon Azul', 109: 'Pokémon Rojo o Azul',
    110: 'Pokémon Rojo o Azul', 124: 'Pokémon Rojo o Azul', 125: 'Pokémon Rojo',
    126: 'Pokémon Azul',
  };

  static const Map<int, (String, String)> _johtoCommonTrades = {
    82: ('Central de Energía de Kanto', 'un Dugtrio'),
    95: ('Ciudad Malva', 'un Bellsprout'),
    100: ('Ciudad Olivo', 'un Krabby'),
    142: ('Ruta 14', 'un Chansey'),
  };
  static const Map<int, (String, String)> _goldSilverTrades = {
    66: ('Centro Comercial de Ciudad Trigal', 'un Drowzee'),
    78: ('Ciudad Plateada', 'un Gloom'),
    112: ('Ciudad Endrino', 'un Dragonair hembra'),
  };
  static const Map<int, (String, String)> _crystalTrades = {
    66: ('Centro Comercial de Ciudad Trigal', 'un Abra'),
    85: ('Ciudad Endrino', 'un Dragonair hembra'),
    178: ('Ciudad Plateada', 'un Haunter'),
  };
  static const Map<int, (String, int)> _goldSilverPrizes = {
    63: ('Casino de Ciudad Trigal', 200), 147: ('Casino de Ciudad Trigal', 2100),
    122: ('Casino de Ciudad Azulona', 3333), 133: ('Casino de Ciudad Azulona', 6666),
    137: ('Casino de Ciudad Azulona', 9999),
  };
  static const Map<int, (String, int)> _crystalPrizes = {
    63: ('Casino de Ciudad Trigal', 100), 104: ('Casino de Ciudad Trigal', 800),
    202: ('Casino de Ciudad Trigal', 1500), 25: ('Casino de Ciudad Azulona', 2222),
    137: ('Casino de Ciudad Azulona', 5555), 246: ('Casino de Ciudad Azulona', 8888),
  };

  static const Set<int> _goldOnlyIds = {56, 57, 58, 59, 167, 168, 207, 216, 217, 226};
  static const Set<int> _silverOnlyIds = {37, 38, 52, 53, 165, 166, 225, 227, 231, 232};
  static const Map<int, String> _crystalMissing = {
    37: 'Pokémon Plata', 38: 'Pokémon Plata', 56: 'Pokémon Oro', 57: 'Pokémon Oro',
    179: 'Pokémon Oro o Plata', 180: 'Pokémon Oro o Plata', 181: 'Pokémon Oro o Plata',
    203: 'Pokémon Oro o Plata', 223: 'Pokémon Oro o Plata', 224: 'Pokémon Oro o Plata',
  };
  static const Set<int> _oddEggIds = {172, 173, 174, 236, 238, 239, 240};
  static const Set<int> _timeCapsuleIds = {
    1, 2, 3, 4, 5, 6, 7, 8, 9,
    138, 139, 140, 141, 144, 145, 146, 150, 151,
  };
}
