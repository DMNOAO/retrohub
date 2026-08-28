import '../../../core/assets/game_asset_profile.dart';
import '../../pokemon/decoder/pokemon_decoder.dart';
import 'pokedex_models.dart';

class Gen4AcquisitionData {
  const Gen4AcquisitionData._();

  static List<PokedexAcquisition> forGame(
    GameAssetProfile profile,
    int pokemonId,
  ) => profile.game == PokemonAssetGame.heartGoldSoulSilver
      ? _hgss(profile, pokemonId)
      : _sinnoh(profile, pokemonId);

  static List<PokedexAcquisition> _sinnoh(
    GameAssetProfile profile,
    int id,
  ) {
    final platinum = profile.game == PokemonAssetGame.platinum;
    final pearl = !platinum && _titleHas(profile, const ['pearl', 'perla']);
    final result = <PokedexAcquisition>[];
    if (const {387, 390, 393}.contains(id)) {
      result.add(_choice('Lago Veraz', 'El Profesor Serbal permite elegir a ${_name(id)} como inicial. Solo puedes escoger uno.'));
    }
    switch (id) {
      case 63:
        result.add(_trade('Ciudad Pirita', 'un Machop'));
        break;
      case 93:
        result.add(_trade('Ciudad Puntaneva', 'un Medicham', note: 'El Haunter recibido lleva una Piedra Eterna y no evoluciona.'));
        break;
      case 441:
        result.add(_trade('Ciudad Vetusta', 'un Buizel'));
        break;
      case 133:
        result.add(_gift('Ciudad Corazón · Casa de Tecla', platinum ? 'Tecla entrega a Eevee durante la aventura.' : 'Tecla entrega a Eevee después de obtener la Pokédex Nacional.'));
        break;
      case 137:
        if (platinum) result.add(_gift('Ciudad Rocavelo', 'Un residente entrega a Porygon.'));
        break;
      case 175:
        if (platinum) result.add(const PokedexAcquisition(method: 'Huevo regalo', location: 'Ciudad Vetusta', detail: 'Cintia entrega un huevo que eclosiona en Togepi.'));
        break;
      case 440:
        if (!platinum) result.add(const PokedexAcquisition(method: 'Huevo regalo', location: 'Ciudad Corazón', detail: 'Un Montañero entrega un huevo que eclosiona en Happiny.'));
        break;
      case 447:
        result.add(const PokedexAcquisition(method: 'Huevo regalo', location: 'Isla Hierro', detail: 'Quinoa entrega un huevo de Riolu después de completar la misión en la isla. Requiere espacio en el equipo.'));
        break;
      case 408:
        result.add(platinum
            ? _fossil('Subsuelo → Museo Minero de Ciudad Pirita', 'El Fósil Cráneo aparece si el ID de Entrenador es impar.')
            : pearl
                ? _other('Pokémon Diamante', 'El Fósil Cráneo no aparece en Pokémon Perla.')
                : _fossil('Subsuelo → Museo Minero de Ciudad Pirita', 'Desentierra el Fósil Cráneo y restáuralo para obtener a Cranidos.'));
        break;
      case 410:
        result.add(platinum
            ? _fossil('Subsuelo → Museo Minero de Ciudad Pirita', 'El Fósil Coraza aparece si el ID de Entrenador es par.')
            : pearl
                ? _fossil('Subsuelo → Museo Minero de Ciudad Pirita', 'Desentierra el Fósil Coraza y restáuralo para obtener a Shieldon.')
                : _other('Pokémon Perla', 'El Fósil Coraza no aparece en Pokémon Diamante.'));
        break;
      case 425:
        result.add(const PokedexAcquisition(method: 'Encuentro semanal', location: 'Valle Eólico', detail: 'Drifloon aparece los viernes después de expulsar al Equipo Galaxia.'));
        break;
      case 442:
        result.add(_static('Torre Sagrada · Ruta 209', 'Coloca la Piedra Espíritu y saluda a otros jugadores 32 veces en el Subsuelo para invocar a Spiritomb.'));
        break;
      case 479:
        result.add(_static('Vieja Mansión', platinum ? 'Interactúa con el televisor después de obtener la Pokédex Nacional.' : 'Interactúa con el televisor durante la noche después de obtener la Pokédex Nacional.'));
        break;
      case 480:
        result.add(_static('Caverna Agudeza', 'Encuentro disponible después de resolver el conflicto de la Columna Lanza.'));
        break;
      case 481:
        result.add(_roaming('Sinnoh', 'Comienza a recorrer la región después de encontrarlo en la Caverna Veraz.'));
        break;
      case 482:
        result.add(_static('Caverna Valor', 'Encuentro disponible después de resolver el conflicto de la Columna Lanza.'));
        break;
      case 483:
        result.add(platinum
            ? _static('Columna Lanza · Orbe Diamante', 'Obtén el Orbe Diamante en el Monte Corona después de la Liga para abrir su portal.')
            : pearl
                ? _other('Pokémon Diamante', 'Dialga no se captura en Pokémon Perla.')
                : _static('Columna Lanza', 'Encuentro principal de la historia.'));
        break;
      case 484:
        result.add(platinum
            ? _static('Columna Lanza · Orbe Perla', 'Obtén el Orbe Perla en el Monte Corona después de la Liga para abrir su portal.')
            : pearl
                ? _static('Columna Lanza', 'Encuentro principal de la historia.')
                : _other('Pokémon Perla', 'Palkia no se captura en Pokémon Diamante.'));
        break;
      case 485:
        result.add(_static('Montaña Dura', 'Devuelve la Piedra Magma después de completar la misión con Bulgur para que aparezca Heatran.'));
        break;
      case 486:
        result.add(_static('Templo Puntaneva', 'Requiere llevar a Regirock, Regice y Registeel en el equipo.'));
        break;
      case 487:
        result.add(_static(platinum ? 'Mundo Distorsión' : 'Cueva Retorno', platinum ? 'Encuentro principal durante el desenlace contra Helio.' : 'Encuentro disponible después de obtener la Pokédex Nacional.'));
        break;
      case 488:
        result.add(_roaming('Sinnoh', 'Visita Isla Plenilunio para obtener la Pluma Lunar; Cresselia comenzará a recorrer la región.'));
        break;
      case 489:
        result.add(_event('Transferencia desde Pokémon Ranger', 'Manaphy llega como huevo especial y debe eclosionar.'));
        break;
      case 490:
        result.add(_event('Huevo de Manaphy', 'Se obtiene criando a Manaphy o Phione con Ditto; Phione no evoluciona a Manaphy.'));
        break;
      case 491:
        result.add(_event('Isla Lunanueva', 'La Tarjeta Miembro habilita la posada cerrada de Ciudad Canal y el encuentro con Darkrai.'));
        break;
      case 492:
        result.add(_event('Paraíso Floral', 'La Carta del Profesor Oak activa la escena de la Ruta 224 y abre el Camino Marino.'));
        break;
      case 493:
        result.add(_event('Sala del Origen', 'La Flauta Azur activa la escalera en la Columna Lanza. El objeto existe en el juego, pero nunca fue distribuido oficialmente.'));
        break;
    }
    if (!platinum) {
      final source = pearl
          ? (_diamondOnly.contains(id) ? 'Pokémon Diamante' : null)
          : (_pearlOnly.contains(id) ? 'Pokémon Perla' : null);
      if (source != null && !result.any((item) => item.method == 'Otra versión')) {
        result.add(_other(source, '${_name(id)} no puede obtenerse directamente en esta edición.'));
      }
    }
    return result;
  }

  static List<PokedexAcquisition> _hgss(
    GameAssetProfile profile,
    int id,
  ) {
    final soulSilver = _titleHas(profile, const ['soulsilver', 'soul silver', 'plata soul']);
    final result = <PokedexAcquisition>[];
    if (const {152, 155, 158}.contains(id)) {
      result.add(_choice('Pueblo Primavera · Laboratorio del Profesor Elm', 'Elige a ${_name(id)} como inicial. Solo puedes escoger uno.'));
    }
    if (const {1, 4, 7}.contains(id)) {
      result.add(_choice('Pueblo Paleta · Laboratorio del Profesor Oak', 'Después de vencer a Rojo, el Profesor Oak permite escoger uno de los iniciales de Kanto.'));
    }
    if (const {252, 255, 258}.contains(id)) {
      result.add(_choice('Silph S.A. · Ciudad Azafrán', 'Después de vencer a Rojo, Máximo permite escoger uno de los iniciales de Hoenn.'));
    }
    switch (id) {
      case 95:
        result.add(_trade('Ciudad Malva', 'un Bellsprout'));
        break;
      case 66:
        result.add(_trade('Centro Comercial de Ciudad Trigal', 'un Drowzee'));
        break;
      case 100:
        result.add(_trade('Ciudad Olivo', 'un Krabby'));
        break;
      case 82:
        result.add(_trade('Central de Energía de Kanto', 'un Dugtrio'));
        break;
      case 142:
        result.add(_trade('Ruta 14', 'un Chansey'));
        break;
      case 374:
        result.add(_trade('Silph S.A. · Ciudad Azafrán', 'un Forretress', note: 'Disponible después de ayudar a Máximo y completar sus encuentros.'));
        break;
      case 21:
        result.add(_gift('Acceso sur de la Ruta 35', 'Te confían temporalmente a Kenya con un correo para la Ruta 31.'));
        break;
      case 131:
        result.add(const PokedexAcquisition(method: 'Encuentro único semanal', location: 'Cueva Unión · B2', detail: 'Lapras aparece los viernes después de conseguir Surf.'));
        break;
      case 133:
        result.add(_gift('Ciudad Trigal', 'Bill entrega a Eevee después de conocerlo en el Centro Pokémon de Ciudad Iris.'));
        break;
      case 143:
        result.add(_static('Ciudad Carmín', 'Despierta a Snorlax con la emisión de la Poké Flauta de la radio.'));
        break;
      case 147:
        result.add(_gift('Guarida Dragón', 'El Maestro entrega a Dratini; puede conocer Velocidad Extrema si respondes correctamente.'));
        break;
      case 175:
        result.add(const PokedexAcquisition(method: 'Huevo regalo', location: 'Centro Pokémon de Ciudad Malva', detail: 'El ayudante de Elm entrega el huevo de Togepi después de vencer a Pegaso.'));
        break;
      case 185:
        result.add(_static('Ruta 36', 'Usa la Regadera para combatir al Sudowoodo que bloquea el camino.'));
        break;
      case 213:
        result.add(_gift('Ciudad Orquídea', 'Mania te confía temporalmente a Shuckie.'));
        break;
      case 236:
        result.add(_gift('Monte Mortero', 'Kiyo entrega a Tyrogue después de ser derrotado.'));
        break;
      case 130:
        result.add(_static('Lago de la Furia', 'Encuentro único con el Gyarados rojo variocolor.'));
        break;
      case 102:
        result.add(_special('Golpe Cabeza', 'Árboles de Johto y Kanto', 'Exeggcute puede caer al usar Golpe Cabeza en árboles de zonas boscosas.'));
        break;
      case 190:
        result.add(_special('Golpe Cabeza', 'Rutas 28, 33, 42, 44–47 y Monte Plateado', 'Aipom aparece al usar Golpe Cabeza en determinados grupos de árboles.'));
        break;
      case 204:
        result.add(_special('Golpe Cabeza', 'Árboles de zonas boscosas de Johto', 'Pineco puede caer al usar Golpe Cabeza.'));
        break;
      case 214:
        result.add(_special('Golpe Cabeza', 'Rutas 7, 11, 28, 33, 42, 44–47 y Monte Plateado', 'Heracross aparece al usar Golpe Cabeza en determinados grupos de árboles.'));
        break;
      case 123:
      case 127:
        result.add(_special('Concurso de Captura de Bichos', 'Parque Nacional', '${_name(id)} puede capturarse durante el concurso de los martes, jueves y sábados.'));
        break;
      case 144:
        result.add(_static('Islas Espuma', 'Articuno espera en las profundidades de las islas.'));
        break;
      case 145:
        result.add(_static('Central de Energía', 'Zapdos espera fuera de la central después de devolver la Maquinaria.'));
        break;
      case 146:
        result.add(_static('Monte Plateado', 'Moltres se encuentra dentro del Monte Plateado.'));
        break;
      case 150:
        result.add(_static('Cueva Celeste', 'Mewtwo aparece después de conseguir las 16 medallas.'));
        break;
      case 243:
      case 244:
        result.add(_roaming('Johto', 'Comienza a recorrer Johto después del encuentro en la Torre Quemada.'));
        break;
      case 245:
        result.add(_static('Ruta 25', 'Completa la persecución de Suicune por Johto y Kanto para combatirlo.'));
        break;
      case 249:
        result.add(_static('Islas Remolino', 'Requiere el Ala Plateada y la Campana Oleaje.'));
        break;
      case 250:
        result.add(_static('Torre Campana', 'Requiere el Ala Arcoíris y la Campana Clara.'));
        break;
      case 380:
      case 381:
        final native = soulSilver ? id == 381 : id == 380;
        result.add(native
            ? _roaming('Kanto', 'Comienza a recorrer Kanto después de recuperar la muñeca de Copiona.')
            : _event('Museo de Ciudad Plateada', 'La Piedra Enigma permite combatir al miembro del dúo ausente de esta versión.'));
        break;
      case 382:
        result.add(soulSilver
            ? _other('Pokémon HeartGold', 'Kyogre no aparece en Pokémon SoulSilver.')
            : _static('Torre Oculta', 'El Profesor Oak entrega la Esfera Azul después de vencer a Rojo.'));
        break;
      case 383:
        result.add(soulSilver
            ? _static('Torre Oculta', 'El Profesor Oak entrega la Esfera Roja después de vencer a Rojo.')
            : _other('Pokémon SoulSilver', 'Groudon no aparece en Pokémon HeartGold.'));
        break;
      case 384:
        result.add(_static('Torre Oculta', 'Muestra a Oak un Kyogre de HeartGold y un Groudon de SoulSilver para recibir la Esfera Verde.'));
        break;
      case 172:
        result.add(_event('Encinar · Santuario del Bosque', 'El Pichu color Pikachu variocolor activa el encuentro con Pichu Picoreja.'));
        break;
      case 251:
        result.add(_event('Encinar · Santuario del Bosque', 'Un Celebi de evento activa el viaje temporal y el combate contra Giovanni.'));
        break;
      case 483:
      case 484:
      case 487:
        result.add(_event('Ruinas Sinjoh', 'Un Arceus de evento permite escoger un único huevo de Dialga, Palkia o Giratina al nivel 1.'));
        break;
    }
    final source = soulSilver
        ? (_heartGoldOnly.contains(id) ? 'Pokémon HeartGold' : null)
        : (_soulSilverOnly.contains(id) ? 'Pokémon SoulSilver' : null);
    if (source != null && !result.any((item) => item.method == 'Otra versión')) {
      result.add(_other(source, '${_name(id)} no aparece directamente en esta edición.'));
    }
    return result;
  }

  static bool _titleHas(GameAssetProfile profile, List<String> values) {
    final title = (profile.sourceTitle ?? '').toLowerCase();
    return values.any(title.contains);
  }

  static String _name(int id) => PokemonDecoder.pokemonName(id);
  static PokedexAcquisition _gift(String l, String d) => PokedexAcquisition(method: 'Regalo', location: l, detail: d);
  static PokedexAcquisition _choice(String l, String d) => PokedexAcquisition(method: 'Regalo · Elección', location: l, detail: d);
  static PokedexAcquisition _trade(String l, String r, {String? note}) => PokedexAcquisition(method: 'Intercambio con NPC', location: l, detail: 'Entrega $r para recibir este Pokémon.${note == null ? '' : ' $note'}');
  static PokedexAcquisition _fossil(String l, String d) => PokedexAcquisition(method: 'Restauración de fósil', location: l, detail: d);
  static PokedexAcquisition _static(String l, String d) => PokedexAcquisition(method: 'Encuentro único', location: l, detail: d);
  static PokedexAcquisition _roaming(String l, String d) => PokedexAcquisition(method: 'Pokémon errante', location: l, detail: d);
  static PokedexAcquisition _event(String l, String d) => PokedexAcquisition(method: 'Evento', location: l, detail: d);
  static PokedexAcquisition _special(String m, String l, String d) => PokedexAcquisition(method: m, location: l, detail: d);
  static PokedexAcquisition _other(String l, String d) => PokedexAcquisition(method: 'Otra versión', location: l, detail: d);

  static const Set<int> _diamondOnly = {86, 87, 123, 198, 246, 247, 248, 303, 304, 305, 306, 352, 408, 409, 434, 435, 483};
  static const Set<int> _pearlOnly = {79, 80, 127, 200, 228, 229, 234, 371, 372, 373, 410, 411, 431, 432, 484};
  static const Set<int> _heartGoldOnly = {56, 57, 58, 59, 138, 139, 167, 168, 207, 226, 231, 232, 302, 343, 344, 382, 458, 472};
  static const Set<int> _soulSilverOnly = {37, 38, 52, 53, 140, 141, 165, 166, 216, 217, 225, 227, 303, 316, 317, 383};
}
