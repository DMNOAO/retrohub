import '../../../core/assets/game_asset_profile.dart';
import '../../pokemon/decoder/pokemon_decoder.dart';
import 'pokedex_models.dart';

class Gen5AcquisitionData {
  const Gen5AcquisitionData._();

  static List<PokedexAcquisition> forGame(
    GameAssetProfile profile,
    int pokemonId,
  ) => profile.game == PokemonAssetGame.black2White2
      ? _sequels(profile, pokemonId)
      : _originals(profile, pokemonId);

  static List<PokedexAcquisition> _originals(
    GameAssetProfile profile,
    int id,
  ) {
    final white = _isWhite(profile);
    final result = <PokedexAcquisition>[];
    if (const {495, 498, 501}.contains(id)) {
      result.add(_choice('Pueblo Arcilla', 'La Profesora Encina entrega a ${_name(id)} como inicial. Solo puedes escoger uno.'));
    }
    switch (id) {
      case 511:
        result.add(_conditionalGift('Solar de los Sueños', 'Se recibe si elegiste a Tepig como inicial.'));
        break;
      case 513:
        result.add(_conditionalGift('Solar de los Sueños', 'Se recibe si elegiste a Oshawott como inicial.'));
        break;
      case 515:
        result.add(_conditionalGift('Solar de los Sueños', 'Se recibe si elegiste a Snivy como inicial.'));
        break;
      case 546:
        if (white) result.add(_trade('Ciudad Esmalte', 'un Petilil'));
        break;
      case 548:
        if (!white) result.add(_trade('Ciudad Esmalte', 'un Cottonee'));
        break;
      case 570:
        result.add(_event('Ciudad Porcelana · Game Freak', 'Lleva un Celebi con encuentro fatídico para revelar y recibir a Zorua.'));
        break;
      case 571:
        result.add(_event('Bosque de los Perdidos', 'Lleva uno de los perros legendarios variocolor de evento para revelar a Zoroark.'));
        break;
      case 564:
        result.add(_fossil('Castillo Ancestral → Museo de Ciudad Esmalte', 'Elige el Fósil Tapa para restaurar a Tirtouga. Solo puedes escoger un fósil de Teselia.'));
        break;
      case 566:
        result.add(_fossil('Castillo Ancestral → Museo de Ciudad Esmalte', 'Elige el Fósil Pluma para restaurar a Archen. Solo puedes escoger un fósil de Teselia.'));
        break;
      case 636:
        result.add(const PokedexAcquisition(method: 'Huevo regalo', location: 'Ruta 18', detail: 'Un Pokémon Ranger entrega un huevo que eclosiona en Larvesta. Requiere espacio en el equipo.'));
        break;
      case 518:
        result.add(const PokedexAcquisition(method: 'Encuentro semanal', location: 'Solar de los Sueños', detail: 'Musharna aparece los viernes en el sótano después de obtener la Pokédex Nacional.'));
        break;
      case 555:
        result.add(_static('Castillo Ancestral', 'Usa un Caramelo Furia en una de las estatuas para despertar a Darmanitan con Modo Daruma.'));
        break;
      case 637:
        result.add(_static('Castillo Ancestral', 'Volcarona espera al final de las ruinas después de completar la historia principal.'));
        break;
      case 638:
        result.add(_static('Cueva Loza', 'Encuentro con Cobalion; abrirá el acceso narrativo a Terrakion y Virizion.'));
        break;
      case 639:
        result.add(_static('Calle Victoria', 'Encuentro disponible después de conocer a Cobalion.'));
        break;
      case 640:
        result.add(_static('Bosque Azulejo', 'Encuentro disponible después de conocer a Cobalion.'));
        break;
      case 641:
        result.add(white
            ? _other('Pokémon Negro', 'Tornadus no aparece en Pokémon Blanco.')
            : _roaming('Teselia', 'Comienza a recorrer la región después del evento meteorológico de la Ruta 7.'));
        break;
      case 642:
        result.add(white
            ? _roaming('Teselia', 'Comienza a recorrer la región después del evento meteorológico de la Ruta 7.')
            : _other('Pokémon Blanco', 'Thundurus no aparece en Pokémon Negro.'));
        break;
      case 645:
        result.add(_static('Santuario Abundancia', 'Lleva a Tornadus y Thundurus en el equipo para hacer aparecer a Landorus.'));
        break;
      case 643:
        result.add(white
            ? _other('Pokémon Negro', 'Reshiram no se captura en Pokémon Blanco.')
            : _static('Castillo de N', 'Encuentro obligatorio durante el desenlace de la historia.'));
        break;
      case 644:
        result.add(white
            ? _static('Castillo de N', 'Encuentro obligatorio durante el desenlace de la historia.')
            : _other('Pokémon Blanco', 'Zekrom no se captura en Pokémon Negro.'));
        break;
      case 646:
        result.add(_static('Boquete Gigante', 'Encuentro disponible después de completar la historia principal.'));
        break;
      case 494:
        result.add(_event('Isla Libertad', 'El Pase Libertad habilita el viaje desde Ciudad Porcelana y el encuentro con Victini.'));
        break;
      case 647:
        result.add(_event('Distribución oficial', 'Keldeo se recibe directamente. Al llevarlo al Pantano Teja puede aprender Sable Místico.'));
        break;
      case 648:
        result.add(_event('Distribución oficial', 'Meloetta se recibe directamente. En el Café Sonata aprende Canto Arcaico.'));
        break;
      case 649:
        result.add(_event('Distribución oficial', 'Genesect se recibe directamente mediante Regalo Misterioso.'));
        break;
    }
    final source = white
        ? (_blackOnly.contains(id) ? 'Pokémon Negro' : null)
        : (_whiteOnly.contains(id) ? 'Pokémon Blanco' : null);
    if (source != null && !result.any((item) => item.method == 'Otra versión')) {
      result.add(_other(source, '${_name(id)} no aparece directamente en esta edición.'));
    }
    return result;
  }

  static List<PokedexAcquisition> _sequels(
    GameAssetProfile profile,
    int id,
  ) {
    final white = _isWhite(profile);
    final result = <PokedexAcquisition>[];
    if (const {495, 498, 501}.contains(id)) {
      result.add(_choice('Ciudad Engobe', 'Bel entrega a ${_name(id)} como inicial. Solo puedes escoger uno.'));
    }
    switch (id) {
      case 546:
        if (white) result.add(_trade('Ruta 4', 'un Petilil'));
        break;
      case 548:
        if (!white) result.add(_trade('Ruta 4', 'un Cottonee'));
        break;
      case 133:
        result.add(_gift('Ciudad Porcelana · Oficina de Tecla', 'Tecla entrega a Eevee después de superar la Liga Pokémon.'));
        break;
      case 570:
        result.add(_gift('Ciudad Fayenza', 'Ruga entrega el Zorua que perteneció a N.'));
        break;
      case 585:
        result.add(_gift('Instituto de Investigación Estacional · Ruta 6', 'Un científico entrega un Deerling con su habilidad oculta.'));
        break;
      case 129:
        result.add(const PokedexAcquisition(method: 'Compra', location: 'Puente Progreso', detail: 'Un vendedor ofrece un Magikarp por 500 ₽ después de la Liga.'));
        break;
      case 443:
        if (!white) result.add(_gift('Ciudad Negra · Rascacielos Negro', 'Benga entrega un Gible variocolor después de superar el Área 10.'));
        break;
      case 147:
        if (white) result.add(_gift('Bosque Blanco · Cavernogal Blanco', 'Benga entrega un Dratini variocolor después de superar el Área 10.'));
        break;
      case 628:
        if (white) result.add(const PokedexAcquisition(method: 'Encuentro semanal', location: 'Ruta 4', detail: 'Braviary con habilidad oculta aparece los lunes.'));
        break;
      case 630:
        if (!white) result.add(const PokedexAcquisition(method: 'Encuentro semanal', location: 'Ruta 4', detail: 'Mandibuzz con habilidad oculta aparece los jueves.'));
        break;
      case 593:
        result.add(const PokedexAcquisition(method: 'Encuentro semanal', location: 'Bahía Arenisca', detail: 'Un Jellicent con habilidad oculta aparece ciertos días; sexo y día dependen de la versión.'));
        break;
      case 558:
        result.add(_static('Ruta 4', 'Usa la Colagro para apartar al Crustle que bloquea el camino.'));
        break;
      case 637:
        result.add(_static('Castillo Ancestral', 'Volcarona espera en la cámara interior y puede combatirse durante la aventura.'));
        break;
      case 638:
        result.add(_static('Ruta 13', 'Encuentro con Cobalion durante la historia.'));
        break;
      case 639:
        result.add(_static('Ruta 22', 'Encuentro con Terrakion durante la historia.'));
        break;
      case 640:
        result.add(_static('Ruta 11', 'Encuentro con Virizion durante la historia.'));
        break;
      case 377:
        result.add(_static('Ruinas Subterráneas', 'Resuelve el acertijo de la Cámara Pico Roca para combatir a Regirock.'));
        break;
      case 378:
        result.add(white
            ? _static('Ruinas Subterráneas', 'La Llave Iceberg de White 2 abre su cámara después de capturar a Regirock.')
            : _other('Pokémon Blanco 2 · Nexo Teselia', 'Requiere recibir la Llave Iceberg mediante Nexo Teselia.'));
        break;
      case 379:
        result.add(white
            ? _other('Pokémon Negro 2 · Nexo Teselia', 'Requiere recibir la Llave Hierro mediante Nexo Teselia.')
            : _static('Ruinas Subterráneas', 'La Llave Hierro de Black 2 abre su cámara después de capturar a Regirock.'));
        break;
      case 486:
        result.add(_static('Monte Tuerca', 'Lleva a Regirock, Regice y Registeel en el equipo para despertar a Regigigas.'));
        break;
      case 380:
        result.add(white ? _roaming('Solar de los Sueños', 'Latias aparece después de la Liga y debe perseguirse por las ruinas.') : _other('Pokémon Blanco 2', 'Latias no aparece en Pokémon Negro 2.'));
        break;
      case 381:
        result.add(white ? _other('Pokémon Negro 2', 'Latios no aparece en Pokémon Blanco 2.') : _roaming('Solar de los Sueños', 'Latios aparece después de la Liga y debe perseguirse por las ruinas.'));
        break;
      case 480:
        result.add(_static('Museo de Ciudad Esmalte', 'Después de visitar la Cueva Psique, Uxie aparece frente al museo.'));
        break;
      case 481:
        result.add(_static('Torre de los Cielos', 'Después de visitar la Cueva Psique, Mesprit aparece en la cima.'));
        break;
      case 482:
        result.add(_static('Ruta 23', 'Después de visitar la Cueva Psique, Azelf aparece en la ruta.'));
        break;
      case 485:
        result.add(_static('Montaña Reversia', 'Lleva la Piedra Magma al fondo de la montaña para invocar a Heatran.'));
        break;
      case 488:
        result.add(_static('Puente Progreso', 'Consigue el Ala Lunar en la Casa Extraña para hacer aparecer a Cresselia.'));
        break;
      case 643:
        result.add(white
            ? _static('Torre Duodraco', 'Después de vencer a N, la Piedra Luz permite despertar a Reshiram.')
            : _other('Pokémon Blanco 2', 'Reshiram no se obtiene en Pokémon Negro 2.'));
        break;
      case 644:
        result.add(white
            ? _other('Pokémon Negro 2', 'Zekrom no se obtiene en Pokémon Blanco 2.')
            : _static('Torre Duodraco', 'Después de vencer a N, la Piedra Oscura permite despertar a Zekrom.'));
        break;
      case 646:
        result.add(_static('Boquete Gigante', 'Después de capturar al dragón de N, vuelve al Boquete Gigante para combatir a Kyurem.'));
        break;
      case 647:
        result.add(_event('Distribución oficial', 'Keldeo activa una escena con Cobalion, Terrakion y Virizion en Arboleda Promesa.'));
        break;
      case 648:
        result.add(_event('Distribución oficial', 'Meloetta puede aprender Canto Arcaico en el Café Sonata de Ciudad Porcelana.'));
        break;
      case 649:
        result.add(_event('Distribución oficial', 'Genesect activa la entrega de módulos en el Laboratorio P+P.'));
        break;
    }
    final source = white
        ? (_black2Only.contains(id) ? 'Pokémon Negro 2' : null)
        : (_white2Only.contains(id) ? 'Pokémon Blanco 2' : null);
    if (source != null && !result.any((item) => item.method == 'Otra versión')) {
      result.add(_other(source, '${_name(id)} no aparece directamente en esta edición.'));
    }
    return result;
  }

  static bool _isWhite(GameAssetProfile profile) {
    final title = (profile.sourceTitle ?? '').toLowerCase();
    return title.contains('white') || title.contains('blanco') || title.contains('blanca');
  }

  static String _name(int id) => PokemonDecoder.pokemonName(id);
  static PokedexAcquisition _gift(String l, String d) => PokedexAcquisition(method: 'Regalo', location: l, detail: d);
  static PokedexAcquisition _conditionalGift(String l, String d) => PokedexAcquisition(method: 'Regalo según inicial', location: l, detail: d);
  static PokedexAcquisition _choice(String l, String d) => PokedexAcquisition(method: 'Regalo · Elección', location: l, detail: d);
  static PokedexAcquisition _trade(String l, String r) => PokedexAcquisition(method: 'Intercambio con NPC', location: l, detail: 'Entrega $r para recibir este Pokémon.');
  static PokedexAcquisition _fossil(String l, String d) => PokedexAcquisition(method: 'Restauración de fósil', location: l, detail: d);
  static PokedexAcquisition _static(String l, String d) => PokedexAcquisition(method: 'Encuentro único', location: l, detail: d);
  static PokedexAcquisition _roaming(String l, String d) => PokedexAcquisition(method: 'Pokémon errante', location: l, detail: d);
  static PokedexAcquisition _event(String l, String d) => PokedexAcquisition(method: 'Evento', location: l, detail: d);
  static PokedexAcquisition _other(String l, String d) => PokedexAcquisition(method: 'Otra versión', location: l, detail: d);

  static const Set<int> _blackOnly = {574, 575, 576, 629, 630, 641, 643};
  static const Set<int> _whiteOnly = {577, 578, 579, 627, 628, 642, 644};
  static const Set<int> _black2Only = {13, 14, 15, 126, 167, 168, 185, 214, 240, 311, 313, 325, 326, 379, 381, 427, 428, 434, 435, 438, 574, 575, 576, 629, 630, 644};
  static const Set<int> _white2Only = {10, 11, 12, 122, 123, 125, 127, 165, 166, 239, 241, 300, 312, 314, 322, 323, 378, 380, 431, 432, 439, 577, 578, 579, 627, 628, 643};
}
