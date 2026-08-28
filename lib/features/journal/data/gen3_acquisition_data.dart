import '../../../core/assets/game_asset_profile.dart';
import '../../pokemon/decoder/pokemon_decoder.dart';
import 'pokedex_models.dart';

class Gen3AcquisitionData {
  const Gen3AcquisitionData._();

  static List<PokedexAcquisition> forGame(
    GameAssetProfile profile,
    int pokemonId,
  ) {
    if (profile.game == PokemonAssetGame.fireRedLeafGreen) {
      return _frlg(profile, pokemonId);
    }
    return _hoenn(profile, pokemonId);
  }

  static List<PokedexAcquisition> _hoenn(
    GameAssetProfile profile,
    int id,
  ) {
    final emerald = profile.game == PokemonAssetGame.emerald;
    final sapphire = !emerald && _titleHas(profile, const ['sapphire', 'zafiro']);
    final result = <PokedexAcquisition>[];
    if (const {252, 255, 258}.contains(id)) {
      result.add(_choice('Villa Raíz · Laboratorio del Profesor Abedul', 'Elige a ${_name(id)} como Pokémon inicial. Solo puedes escoger uno.'));
    }
    switch (id) {
      case 296:
        if (!emerald) result.add(_trade('Ciudad Férrica', 'un Slakoth'));
        break;
      case 300:
        if (!emerald) result.add(_trade('Ciudad Arborada', 'un Pikachu'));
        break;
      case 311:
        if (emerald) result.add(_trade('Ciudad Arborada', 'un Volbeat'));
        break;
      case 273:
        if (emerald) result.add(_trade('Ciudad Férrica', 'un Ralts'));
        break;
      case 116:
        if (emerald) result.add(_trade('Pueblo Oromar', 'un Bagon'));
        break;
      case 222:
        if (!emerald) result.add(_trade('Pueblo Oromar', 'un Bellossom'));
        break;
      case 52:
        if (emerald) result.add(_trade('Frente Batalla', 'un Skitty'));
        break;
      case 345:
        result.add(_fossil('Desierto de la Ruta 111 → Devon S.A.', emerald ? 'Recoge el Fósil Raíz en la Torre Espejismo. El otro fósil puede recuperarse después de la Liga en el Túnel Desértico.' : 'Elige el Fósil Raíz; el otro fósil se hundirá en la arena.'));
        break;
      case 347:
        result.add(_fossil('Desierto de la Ruta 111 → Devon S.A.', emerald ? 'Recoge el Fósil Garra en la Torre Espejismo. El otro fósil puede recuperarse después de la Liga en el Túnel Desértico.' : 'Elige el Fósil Garra; el otro fósil se hundirá en la arena.'));
        break;
      case 351:
        result.add(_gift('Instituto Meteorológico · Ruta 119', 'Un científico te entrega a Castform después de expulsar al equipo villano.'));
        break;
      case 360:
        result.add(const PokedexAcquisition(method: 'Huevo regalo', location: 'Pueblo Lavacalda', detail: 'Una anciana entrega un huevo que eclosiona en Wynaut. Necesitas espacio en el equipo.'));
        break;
      case 374:
        result.add(_gift('Ciudad Algaria · Casa de Máximo', 'Después de superar la Liga, Máximo deja una Poké Ball con Beldum.'));
        break;
      case 352:
        result.add(_static('Rutas 119 y 120', 'Algunos Kecleon invisibles bloquean el paso; usa el Devon Scope para revelarlos.'));
        break;
      case 377:
        result.add(_static('Ruinas Desierto', 'Resuelve el enigma de la Cámara Sellada para abrir la tumba de Regirock.'));
        break;
      case 378:
        result.add(_static('Cueva Insular', 'Resuelve el enigma de la Cámara Sellada para abrir la tumba de Regice.'));
        break;
      case 379:
        result.add(_static('Tumba Antigua', 'Resuelve el enigma de la Cámara Sellada para abrir la tumba de Registeel.'));
        break;
      case 380:
        result.addAll(_eonDragon(profile, id, sapphire: sapphire, emerald: emerald));
        break;
      case 381:
        result.addAll(_eonDragon(profile, id, sapphire: sapphire, emerald: emerald));
        break;
      case 382:
        if (sapphire) result.add(_static('Caverna Abisal', 'Encuentro de la historia con Kyogre.'));
        if (emerald) result.add(_static('Cueva Marina', 'Después de la Liga, localiza la alteración meteorológica indicada por el Instituto Meteorológico.'));
        break;
      case 383:
        if (!sapphire && !emerald) result.add(_static('Caverna Abisal', 'Encuentro de la historia con Groudon.'));
        if (emerald) result.add(_static('Cueva Terrena', 'Después de la Liga, localiza la alteración meteorológica indicada por el Instituto Meteorológico.'));
        break;
      case 384:
        result.add(_static('Pilar Celeste', emerald ? 'Encuentro disponible durante la historia y nuevamente capturable en la cima.' : 'Encuentro disponible después de superar la Liga Pokémon.'));
        break;
      case 151:
        result.add(emerald
            ? _event('Isla Suprema', 'El Mapa Viejo permite seguir y capturar a Mew. Este objeto solo tuvo distribución oficial japonesa.')
            : _other('Pokémon Esmeralda', 'El encuentro de Isla Suprema no existe en Rubí o Zafiro.'));
        break;
      case 249:
        result.add(emerald
            ? _event('Roca Ombligo', 'El Misti-Ticket permite llegar a la isla y capturar a Lugia.')
            : _other('Pokémon Esmeralda o FR/LG', 'El encuentro de Roca Ombligo no está disponible en Rubí o Zafiro.'));
        break;
      case 250:
        result.add(emerald
            ? _event('Roca Ombligo', 'El Misti-Ticket permite llegar a la isla y capturar a Ho-Oh.')
            : _other('Pokémon Esmeralda o FR/LG', 'El encuentro de Roca Ombligo no está disponible en Rubí o Zafiro.'));
        break;
      case 385:
        result.add(_event('Distribución oficial', 'Jirachi no aparece durante la aventura normal; requiere distribución o transferencia compatible.'));
        break;
      case 386:
        result.add(emerald
            ? _event('Isla Origen', 'El Ori-Ticket permite resolver el rompecabezas del triángulo y combatir contra Deoxys.')
            : _other('Pokémon Esmeralda o FR/LG', 'Deoxys no tiene un encuentro dentro de Rubí o Zafiro.'));
        break;
    }
    final unavailable = _hoennUnavailable(id, sapphire: sapphire, emerald: emerald);
    if (unavailable != null) result.add(unavailable);
    return result;
  }

  static List<PokedexAcquisition> _eonDragon(
    GameAssetProfile profile,
    int id, {
    required bool sapphire,
    required bool emerald,
  }) {
    if (emerald) {
      return [
        _roaming('Hoenn', 'Después de la Liga, la respuesta dada a tu madre determina si Latias o Latios recorrerá Hoenn.'),
        _event('Isla del Sur', 'El Ticket Eón permite encontrar al miembro del dúo que no elegiste.'),
      ];
    }
    final roaming = (sapphire && id == 380) || (!sapphire && id == 381);
    return [
      roaming
          ? _roaming('Hoenn', 'Comienza a recorrer la región después de superar la Liga Pokémon.')
          : _event('Isla del Sur', 'El Ticket Eón permite encontrar al miembro del dúo que no recorre esta versión.'),
    ];
  }

  static PokedexAcquisition? _hoennUnavailable(
    int id, {
    required bool sapphire,
    required bool emerald,
  }) {
    String? source;
    if (emerald) {
      if (_emeraldMissing.contains(id)) source = 'Pokémon Rubí o Zafiro';
    } else if (sapphire && _rubyOnly.contains(id)) {
      source = 'Pokémon Rubí';
    } else if (!sapphire && _sapphireOnly.contains(id)) {
      source = 'Pokémon Zafiro';
    }
    return source == null ? null : _other(source, '${_name(id)} no aparece en esta edición. Debes intercambiarlo desde $source.');
  }

  static List<PokedexAcquisition> _frlg(
    GameAssetProfile profile,
    int id,
  ) {
    final leafGreen = _titleHas(profile, const ['leaf', 'verde hoja']);
    final result = <PokedexAcquisition>[];
    if (const {1, 4, 7}.contains(id)) {
      result.add(_choice('Pueblo Paleta · Laboratorio del Profesor Oak', 'Elige a ${_name(id)} como inicial. Solo puedes escoger uno.'));
    }
    switch (id) {
      case 29:
        if (!leafGreen) result.add(_trade('Ruta 5', 'un Nidoran♂'));
        break;
      case 32:
        if (leafGreen) result.add(_trade('Ruta 5', 'un Nidoran♀'));
        break;
      case 30:
        if (!leafGreen) result.add(_trade('Ruta 11', 'un Nidorino'));
        break;
      case 33:
        if (leafGreen) result.add(_trade('Ruta 11', 'una Nidorina'));
        break;
      case 83:
        result.add(_trade('Ciudad Carmín', 'un Spearow'));
        break;
      case 86:
        result.add(_trade('Laboratorio Pokémon · Isla Canela', 'un Ponyta'));
        break;
      case 101:
        result.add(_trade('Laboratorio Pokémon · Isla Canela', 'un Raichu'));
        break;
      case 108:
        result.add(_trade('Ruta 18', leafGreen ? 'un Slowbro' : 'un Golduck'));
        break;
      case 114:
        result.add(_trade('Laboratorio Pokémon · Isla Canela', 'un Venonat'));
        break;
      case 122:
        result.add(_trade('Ruta 2', 'un Abra'));
        break;
      case 124:
        result.add(_trade('Ciudad Celeste', 'un Poliwhirl'));
        break;
      case 106:
      case 107:
        result.add(_choice('Dojo Karate · Ciudad Azafrán', 'Premio tras vencer al Maestro Karateka. Debes elegir entre Hitmonlee y Hitmonchan.'));
        break;
      case 129:
        result.add(const PokedexAcquisition(method: 'Compra', location: 'Centro Pokémon de la Ruta 4', detail: 'Un vendedor ofrece un Magikarp por 500 ₽.'));
        break;
      case 131:
        result.add(_gift('Silph S.A. · Ciudad Azafrán', 'Un empleado te entrega a Lapras durante la incursión del Team Rocket.'));
        break;
      case 133:
        result.add(_gift('Mansión Azulona · Ciudad Azulona', 'Recoge la Poké Ball de Eevee en la azotea entrando por la puerta trasera.'));
        break;
      case 138:
        result.add(_fossil('Monte Moon → Laboratorio de Isla Canela', 'Elige el Fósil Helix para revivir a Omanyte.'));
        break;
      case 140:
        result.add(_fossil('Monte Moon → Laboratorio de Isla Canela', 'Elige el Fósil Domo para revivir a Kabuto.'));
        break;
      case 142:
        result.add(_fossil('Museo de Ciudad Plateada → Laboratorio de Isla Canela', 'Entrega el Ámbar Viejo para revivir a Aerodactyl.'));
        break;
      case 175:
        result.add(const PokedexAcquisition(method: 'Huevo regalo', location: 'Laberinto Acuático · Isla Quarta', detail: 'Un anciano entrega un huevo de Togepi si el primer Pokémon del equipo tiene suficiente amistad.'));
        break;
      case 143:
        result.add(_static('Rutas 12 y 16', 'Despierta a Snorlax con la Poké Flauta.'));
        break;
      case 144:
        result.add(_static('Islas Espuma', 'Encuentro único con Articuno.'));
        break;
      case 145:
        result.add(_static('Central de Energía', 'Encuentro único con Zapdos.'));
        break;
      case 146:
        result.add(_static('Monte Ascuas', 'Encuentro único con Moltres.'));
        break;
      case 150:
        result.add(_static('Cueva Celeste', 'Encuentro disponible después de superar la Liga y completar la misión de las Islas Sete.'));
        break;
      case 243:
      case 244:
      case 245:
        result.add(_roaming('Kanto', 'Solo uno de los tres puede recorrer Kanto después de la Liga; depende del inicial elegido.'));
        break;
      case 249:
        result.add(_event('Roca Ombligo', 'El Misti-Ticket permite combatir contra Lugia.'));
        break;
      case 250:
        result.add(_event('Roca Ombligo', 'El Misti-Ticket permite combatir contra Ho-Oh.'));
        break;
      case 386:
        result.add(_event('Isla Origen', 'El Ori-Ticket permite resolver el rompecabezas y combatir contra Deoxys.'));
        break;
    }
    final opposite = leafGreen
        ? (_fireRedOnly.contains(id) ? 'Pokémon Rojo Fuego' : null)
        : (_leafGreenOnly.contains(id) ? 'Pokémon Verde Hoja' : null);
    if (opposite != null) result.add(_other(opposite, '${_name(id)} no aparece en esta edición. Debes intercambiarlo desde $opposite.'));
    return result;
  }

  static bool _titleHas(GameAssetProfile profile, List<String> values) {
    final title = (profile.sourceTitle ?? '').toLowerCase();
    return values.any(title.contains);
  }

  static String _name(int id) => PokemonDecoder.pokemonName(id);
  static PokedexAcquisition _gift(String location, String detail) => PokedexAcquisition(method: 'Regalo', location: location, detail: detail);
  static PokedexAcquisition _choice(String location, String detail) => PokedexAcquisition(method: 'Regalo · Elección', location: location, detail: detail);
  static PokedexAcquisition _trade(String location, String requested) => PokedexAcquisition(method: 'Intercambio con NPC', location: location, detail: 'Entrega $requested para recibir este Pokémon.');
  static PokedexAcquisition _fossil(String location, String detail) => PokedexAcquisition(method: 'Restauración de fósil', location: location, detail: detail);
  static PokedexAcquisition _static(String location, String detail) => PokedexAcquisition(method: 'Encuentro único', location: location, detail: detail);
  static PokedexAcquisition _roaming(String location, String detail) => PokedexAcquisition(method: 'Pokémon errante', location: location, detail: detail);
  static PokedexAcquisition _event(String location, String detail) => PokedexAcquisition(method: 'Evento', location: location, detail: detail);
  static PokedexAcquisition _other(String location, String detail) => PokedexAcquisition(method: 'Otra versión', location: location, detail: detail);

  static const Set<int> _rubyOnly = {273, 274, 275, 303, 335, 338, 383};
  static const Set<int> _sapphireOnly = {270, 271, 272, 302, 336, 337, 382};
  static const Set<int> _emeraldMissing = {283, 284, 307, 308, 315, 335, 337};
  static const Set<int> _fireRedOnly = {
    23, 24, 43, 44, 45, 54, 55, 58, 59, 90, 91, 123, 125, 182, 194, 195,
    198, 211, 212, 225, 227, 239,
  };
  static const Set<int> _leafGreenOnly = {
    27, 28, 37, 38, 69, 70, 71, 79, 80, 120, 121, 126, 127, 183, 184,
    199, 200, 215, 223, 224, 226, 240, 298,
  };
}
