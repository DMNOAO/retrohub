import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../models/pokemon_game_profile.dart';

class NdsTrainerInfo {
  final int trainerId;
  final int classId;
  final String className;
  final String spritePath;

  const NdsTrainerInfo({
    required this.trainerId,
    required this.classId,
    required this.className,
    required this.spritePath,
  });
}

/// Resuelve la clase real de un entrenador leyendo su entrada en el NARC de
/// la propia ROM. El índice del miembro coincide con el trainerId usado por
/// el motor de combate.
final class NdsTrainerResolver {
  const NdsTrainerResolver._();

  static final Map<String, Map<int, NdsTrainerInfo?>> _cache =
      <String, Map<int, NdsTrainerInfo?>>{};
  static final Map<String, Map<int, Uint8List>> _trainerDataCache =
      <String, Map<int, Uint8List>>{};

  /// Busca en la RAM activa entradas TRData completas cargadas por el juego.
  /// A diferencia de las banderas de EventWork, el índice encontrado aquí sí
  /// es el trainerId real usado por la ROM.
  static Future<List<NdsTrainerInfo>> findLoadedTrainers({
    required String romPath,
    required PokemonGameVersion version,
    required List<int> systemRam,
  }) async {
    if (!_isSupported(version) || systemRam.length < 12) {
      return const <NdsTrainerInfo>[];
    }
    final records = await _readAllTrainerData(
      romPath: romPath,
      version: version,
    );
    if (records.isEmpty) return const <NdsTrainerInfo>[];

    final prefixes = <int, List<int>>{};
    for (final entry in records.entries) {
      if (entry.key <= 0 || entry.value.length < 12) continue;
      prefixes.putIfAbsent(_u32(entry.value, 0), () => <int>[]).add(entry.key);
    }
    final found = <NdsTrainerInfo>[];
    final seen = <int>{};
    for (var offset = 0; offset + 12 <= systemRam.length; offset += 4) {
      final candidates = prefixes[_u32(systemRam, offset)];
      if (candidates == null) continue;
      for (final trainerId in candidates) {
        if (seen.contains(trainerId)) continue;
        final record = records[trainerId]!;
        if (offset + record.length > systemRam.length) continue;
        var matches = true;
        for (var i = 0; i < record.length; i++) {
          if (systemRam[offset + i] != record[i]) {
            matches = false;
            break;
          }
        }
        if (!matches) continue;
        seen.add(trainerId);
        final info = forClassId(
          version: version,
          trainerId: trainerId,
          classId: record[1],
        );
        if (info != null) found.add(info);
      }
    }
    return found;
  }

  static Future<NdsTrainerInfo?> resolve({
    required String romPath,
    required PokemonGameVersion version,
    required int trainerId,
  }) async {
    if (trainerId <= 0 || !_isSupported(version)) return null;
    final cache = _cache.putIfAbsent(
      '$romPath:${version.name}',
      () => <int, NdsTrainerInfo?>{},
    );
    if (cache.containsKey(trainerId)) return cache[trainerId];

    try {
      final classId = await _readTrainerClass(
        romPath: romPath,
        version: version,
        trainerId: trainerId,
      );
      final info = classId == null
          ? null
          : forClassId(
              version: version,
              trainerId: trainerId,
              classId: classId,
            );
      cache[trainerId] = info;
      return info;
    } catch (_) {
      cache[trainerId] = null;
      return null;
    }
  }

  static NdsTrainerInfo? forClassId({
    required PokemonGameVersion version,
    required int trainerId,
    required int classId,
  }) {
    final isGen5 = version == PokemonGameVersion.black ||
        version == PokemonGameVersion.white ||
        version == PokemonGameVersion.black2 ||
        version == PokemonGameVersion.white2;
    final special = (isGen5 ? _unovaSpecialClasses : _sinnohSpecialClasses)[classId];
    if (special != null) {
      final path = classId == 63 && !isGen5
          ? (version == PokemonGameVersion.platinum
              ? 'assets/sprites/characters/rivals/barry_pt.gif'
              : 'assets/sprites/characters/rivals/barry_dp.png')
          : special.$2;
      return NdsTrainerInfo(
        trainerId: trainerId,
        classId: classId,
        className: special.$1,
        spritePath: path,
      );
    }
    final entry = (isGen5 ? _unovaClasses : _sinnohClasses)[classId];
    if (entry == null) return null;
    final region = isGen5 ? 'Unova' : 'Sinnoh';
    final suffix = isGen5 ? 'unova_gen5.gif' : 'sinnoh_gen4.png';
    return NdsTrainerInfo(
      trainerId: trainerId,
      classId: classId,
      className: entry.$1,
      spritePath:
          'assets/sprites/characters/trainers/nds/$region/${entry.$2}_$suffix',
    );
  }

  /// Respaldo sin acceso a la ROM para eventos históricos ya guardados.
  /// Los eventos nuevos deben usar [resolveGen5TrainerFlag].
  static NdsTrainerInfo? forGen5TrainerFlag(int trainerFlagId) {
    final classId = _unovaTrainerFlagClasses[trainerFlagId];
    if (classId == null) return null;
    return forClassId(
      version: PokemonGameVersion.white,
      trainerId: trainerFlagId,
      classId: classId,
    );
  }

  static bool _isSupported(PokemonGameVersion version) => switch (version) {
        PokemonGameVersion.diamond ||
        PokemonGameVersion.pearl ||
        PokemonGameVersion.platinum ||
        PokemonGameVersion.black ||
        PokemonGameVersion.white ||
        PokemonGameVersion.black2 ||
        PokemonGameVersion.white2 => true,
        _ => false,
      };

  static Future<int?> _readTrainerClass({
    required String romPath,
    required PokemonGameVersion version,
    required int trainerId,
  }) async {
    final file = File(romPath);
    if (!await file.exists()) return null;
    final handle = await file.open();
    try {
      final header = await _readAt(handle, 0, 0x50);
      final fntOffset = _u32(header, 0x40);
      final fntSize = _u32(header, 0x44);
      final fatOffset = _u32(header, 0x48);
      if (fntOffset <= 0 || fntSize <= 0 || fatOffset <= 0) return null;
      final fnt = await _readAt(handle, fntOffset, fntSize);
      final path = version == PokemonGameVersion.black ||
              version == PokemonGameVersion.white ||
              version == PokemonGameVersion.black2 ||
              version == PokemonGameVersion.white2
          ? 'a/0/9/2'
          : 'poketool/trainer/trdata.narc';
      final fileId = _findNitroFileId(fnt, path);
      if (fileId == null) return null;
      final fat = await _readAt(handle, fatOffset + fileId * 8, 8);
      final start = _u32(fat, 0);
      final end = _u32(fat, 4);
      if (end <= start) return null;
      final narc = await _readAt(handle, start, end - start);
      final member = _narcMember(narc, trainerId);
      return member != null && member.length > 1 ? member[1] : null;
    } finally {
      await handle.close();
    }
  }

  static Future<Map<int, Uint8List>> _readAllTrainerData({
    required String romPath,
    required PokemonGameVersion version,
  }) async {
    final key = '$romPath:${version.name}';
    final cached = _trainerDataCache[key];
    if (cached != null) return cached;
    final result = <int, Uint8List>{};
    final file = File(romPath);
    if (!await file.exists()) return result;
    final handle = await file.open();
    try {
      final header = await _readAt(handle, 0, 0x50);
      final fntOffset = _u32(header, 0x40);
      final fntSize = _u32(header, 0x44);
      final fatOffset = _u32(header, 0x48);
      final fnt = await _readAt(handle, fntOffset, fntSize);
      final path = version == PokemonGameVersion.black ||
              version == PokemonGameVersion.white ||
              version == PokemonGameVersion.black2 ||
              version == PokemonGameVersion.white2
          ? 'a/0/9/2'
          : 'poketool/trainer/trdata.narc';
      final fileId = _findNitroFileId(fnt, path);
      if (fileId == null) return result;
      final fat = await _readAt(handle, fatOffset + fileId * 8, 8);
      final start = _u32(fat, 0);
      final end = _u32(fat, 4);
      final narc = await _readAt(handle, start, end - start);
      final count = _narcMemberCount(narc);
      for (var trainerId = 1; trainerId < count; trainerId++) {
        final member = _narcMember(narc, trainerId);
        if (member != null && member.length >= 12) result[trainerId] = member;
      }
      _trainerDataCache[key] = result;
      return result;
    } finally {
      await handle.close();
    }
  }

  static int _narcMemberCount(Uint8List narc) {
    if (narc.length < 0x20 || ascii.decode(narc.sublist(0, 4)) != 'NARC') {
      return 0;
    }
    var cursor = _u16(narc, 0x0C);
    while (cursor + 10 <= narc.length) {
      final tag = ascii.decode(narc.sublist(cursor, cursor + 4));
      final size = _u32(narc, cursor + 4);
      if (size < 8 || cursor + size > narc.length) return 0;
      if (tag == 'BTAF') return _u16(narc, cursor + 8);
      cursor += size;
    }
    return 0;
  }

  static Future<Uint8List> _readAt(
    RandomAccessFile file,
    int offset,
    int length,
  ) async {
    await file.setPosition(offset);
    return file.read(length);
  }

  static int? _findNitroFileId(Uint8List fnt, String wantedPath) {
    final parts = wantedPath.split('/');
    var directoryIndex = 0;
    for (var depth = 0; depth < parts.length; depth++) {
      final table = directoryIndex * 8;
      if (table + 8 > fnt.length) return null;
      var cursor = _u32(fnt, table);
      var fileId = _u16(fnt, table + 4);
      final wanted = parts[depth];
      var matchedDirectory = false;
      while (cursor < fnt.length) {
        final marker = fnt[cursor++];
        if (marker == 0) break;
        final isDirectory = (marker & 0x80) != 0;
        final nameLength = marker & 0x7F;
        if (cursor + nameLength > fnt.length) return null;
        final name = ascii.decode(fnt.sublist(cursor, cursor + nameLength));
        cursor += nameLength;
        if (isDirectory) {
          if (cursor + 2 > fnt.length) return null;
          final child = _u16(fnt, cursor) - 0xF000;
          cursor += 2;
          if (name == wanted) {
            if (depth == parts.length - 1) return null;
            directoryIndex = child;
            matchedDirectory = true;
            break;
          }
        } else {
          if (name == wanted && depth == parts.length - 1) return fileId;
          fileId++;
        }
      }
      if (depth < parts.length - 1 && !matchedDirectory) return null;
    }
    return null;
  }

  static Uint8List? _narcMember(Uint8List narc, int memberId) {
    if (narc.length < 0x20 || ascii.decode(narc.sublist(0, 4)) != 'NARC') {
      return null;
    }
    var cursor = _u16(narc, 0x0C);
    int? allocationTable;
    int? imageData;
    while (cursor + 8 <= narc.length) {
      final tag = ascii.decode(narc.sublist(cursor, cursor + 4));
      final size = _u32(narc, cursor + 4);
      if (size < 8 || cursor + size > narc.length) return null;
      if (tag == 'BTAF') allocationTable = cursor;
      if (tag == 'GMIF') imageData = cursor + 8;
      cursor += size;
    }
    if (allocationTable == null || imageData == null) return null;
    final count = _u16(narc, allocationTable + 8);
    if (memberId >= count) return null;
    final entry = allocationTable + 12 + memberId * 8;
    final start = imageData + _u32(narc, entry);
    final end = imageData + _u32(narc, entry + 4);
    if (start < imageData || end <= start || end > narc.length) return null;
    return Uint8List.sublistView(narc, start, end);
  }

  static int _u16(List<int> data, int offset) =>
      data[offset] | (data[offset + 1] << 8);
  static int _u32(List<int> data, int offset) =>
      _u16(data, offset) | (_u16(data, offset + 2) << 16);

  static const Map<int, (String, String)> _sinnohClasses = {
    2: ('Joven', 'joven'), 3: ('Chica', 'chica'),
    4: ('Campista', 'campista'), 5: ('Dominguera', 'dominguera'),
    6: ('Cazabichos', 'cazabichos'), 7: ('Señorita Aroma', 'senorita_aroma'),
    8: ('Gemelas', 'gemelas'), 9: ('Montañero', 'montanero'),
    10: ('Luchadora', 'luchadora'), 11: ('Pescador', 'pescador'),
    12: ('Ciclista', 'ciclista_hombre'), 13: ('Ciclista', 'ciclista_mujer'),
    14: ('Karateka', 'karateka'), 15: ('Artista', 'artista'),
    16: ('Criador', 'criador'), 17: ('Criadora', 'criadora'),
    18: ('Vaquera', 'vaquera'), 19: ('Corredor', 'corredor'),
    20: ('Pokéfan', 'pokefan_hombre'), 21: ('Pokéfan', 'pokefan_mujer'),
    22: ('Pokéchica', 'pokechica'), 23: ('Pareja joven', 'pareja_joven'),
    24: ('Entrenador Guay', 'entrenador_guay'),
    25: ('Entrenadora Guay', 'entrenadora_guay'),
    26: ('Camarera', 'camarera'), 27: ('Veterano', 'veterano'),
    28: ('Chico Ninja', 'chico_ninja'), 29: ('Domadragón', 'domadragon'),
    30: ('Ornitóloga', 'ornitologa'), 31: ('Dúo', 'duo'),
    32: ('Niño Bien', 'nino_bien'), 33: ('Damisela', 'damisela'),
    34: ('Caballero', 'duque'), 35: ('Marquesa', 'marquesa'),
    36: ('Bella', 'bella'), 37: ('Pokécolector', 'pokecolector'),
    38: ('Policía', 'policia'), 39: ('Pokémon Ranger', 'pokemon_ranger_hombre'),
    40: ('Pokémon Ranger', 'pokemon_ranger_mujer'),
    41: ('Científico', 'cientifico'), 42: ('Nadador', 'nadador'),
    43: ('Nadadora', 'nadadora'), 44: ('Playero', 'playero'),
    45: ('Playera', 'playera'), 46: ('Marinero', 'marinero'),
    47: ('Padre e hija', 'padre_e_hija'), 48: ('Ruinamaníaco', 'ruinamaniaco'),
    49: ('Médium', 'medium_hombre'), 50: ('Médium', 'medium_mujer'),
    51: ('Jugón', 'jugon'), 52: ('Guitarrista', 'guitarrista'),
    53: ('Entrenador Guay', 'entrenador_guay_montana'),
    54: ('Entrenadora Guay', 'entrenadora_guay_montana'),
    55: ('Esquiador', 'esquiador'), 56: ('Esquiadora', 'esquiadora'),
    57: ('Calvo', 'calvo'), 58: ('Payaso', 'payaso'),
    59: ('Obrero', 'obrero'), 60: ('Escolar', 'escolar_chico'),
    61: ('Escolar', 'escolar_chica'),
  };

  static const Map<int, (String, String)> _sinnohSpecialClasses = {
    62: ('Roco', 'assets/sprites/characters/gym_leaders/nds/Sinnoh/roark_sinnoh.gif'),
    63: ('Barry', ''),
    64: ('Acerón', 'assets/sprites/characters/gym_leaders/nds/Sinnoh/byron_sinnoh.gif'),
    65: ('Alecrán', 'assets/sprites/characters/elite_four/nds/Sinnoh/aaron_sinnoh.gif'),
    66: ('Gaia', 'assets/sprites/characters/elite_four/nds/Sinnoh/bertha_sinnoh.gif'),
    67: ('Fausto', 'assets/sprites/characters/elite_four/nds/Sinnoh/flint_sinnoh.gif'),
    68: ('Delos', 'assets/sprites/characters/elite_four/nds/Sinnoh/lucian_sinnoh.gif'),
    69: ('Cintia', 'assets/sprites/characters/champions/cynthia_sinnoh.gif'),
    74: ('Marte', 'assets/sprites/characters/villains/galactic/mars.png'),
    75: ('Recluta Galaxia', 'assets/sprites/characters/villains/galactic/grunt_male.png'),
    76: ('Gardenia', 'assets/sprites/characters/gym_leaders/nds/Sinnoh/gardenia_sinnoh.gif'),
    77: ('Mananti', 'assets/sprites/characters/gym_leaders/nds/Sinnoh/crasher_wake_sinnoh.gif'),
    78: ('Brega', 'assets/sprites/characters/gym_leaders/nds/Sinnoh/maylene_sinnoh.gif'),
    79: ('Fantina', 'assets/sprites/characters/gym_leaders/nds/Sinnoh/fantina_sinnoh.gif'),
    80: ('Inverna', 'assets/sprites/characters/gym_leaders/nds/Sinnoh/candice_sinnoh.gif'),
    81: ('Lectro', 'assets/sprites/characters/gym_leaders/nds/Sinnoh/volkner_sinnoh.gif'),
    88: ('Helio', 'assets/sprites/characters/villains/galactic/cyrus.gif'),
    89: ('Júpiter', 'assets/sprites/characters/villains/galactic/jupiter.png'),
    90: ('Saturno', 'assets/sprites/characters/villains/galactic/saturn.png'),
    91: ('Recluta Galaxia', 'assets/sprites/characters/villains/galactic/grunt_female.png'),
  };

  static const Map<int, (String, String)> _unovaClasses = {
    2: ('Joven', 'joven'), 3: ('Chica', 'chica'),
    4: ('Escolar', 'escolar_chico'), 5: ('Escolar', 'escolar_chica'),
    6: ('Especialista', 'especialista'), 7: ('Quarterback', 'quarterback'),
    8: ('Camarero', 'camarero'), 9: ('Camarera', 'camarera'),
    13: ('Criada', 'criada'), 14: ('Preescolar', 'preescolar_nino'),
    15: ('Preescolar', 'preescolar_nina'), 16: ('Gemelas', 'gemelas'),
    17: ('Criador', 'criador'), 18: ('Criadora', 'criadora'),
    24: ('Pokémon Ranger', 'pokemon_ranger_hombre'),
    25: ('Pokémon Ranger', 'pokemon_ranger_mujer'), 26: ('Operario', 'operario'),
    27: ('Mochilero', 'mochilero'), 28: ('Mochilera', 'mochilera'),
    29: ('Pescador', 'pescador'), 30: ('Guitarrista', 'guitarrista'),
    31: ('Breakdancer', 'breakdancer'), 32: ('Arlequín', 'arlequin'),
    33: ('Artista', 'artista'), 34: ('Pastelera', 'pastelera'),
    35: ('Médium', 'medium_hombre'), 36: ('Médium', 'medium_mujer'),
    41: ('Niño Bien', 'nino_bien'), 42: ('Damisela', 'damisela'),
    43: ('Piloto', 'piloto'), 44: ('Operario', 'operario'),
    45: ('Pivot', 'pivot'), 46: ('Científica', 'cientifica'),
    48: ('Oficinista', 'oficinista'), 49: ('Entrenador Guay', 'entrenador_guay'),
    50: ('Entrenadora Guay', 'entrenadora_guay'), 51: ('Karateka', 'karateka'),
    52: ('Científico', 'cientifico'), 53: ('Delantero', 'delantero'),
    57: ('Calvo', 'calvo'), 58: ('Limpiador', 'limpiador'),
    59: ('Pokéfan', 'pokefan_hombre'), 60: ('Pokéfan', 'pokefan_mujer'),
    61: ('Enfermero', 'enfermero'), 62: ('Enfermera', 'enfermera'),
    63: ('Pandilleros', 'pandilleros'), 64: ('Luchadora', 'luchadora'),
    65: ('Dama Parasol', 'dama_parasol'), 66: ('Empresario', 'empresario_adulto'),
    67: ('Empresario', 'empresario_joven'), 68: ('Animadoras', 'animadoras'),
    69: ('Hinchas', 'hinchas'), 70: ('Veterano', 'veterano'),
    71: ('Veterana', 'veterana'), 72: ('Motorista', 'motorista'),
    73: ('Pitcher', 'pitcher'), 74: ('Montañero', 'montanero'),
    75: ('Marquesa', 'marquesa'), 76: ('Duque', 'duque'),
    83: ('Ferroviario', 'ferroviario'), 84: ('Nadador', 'nadador'),
    85: ('Nadadora', 'nadadora'), 86: ('Policía', 'policia'),
    87: ('Criada', 'criada'), 90: ('Ciclista', 'ciclista_hombre'),
    91: ('Ciclista', 'ciclista_mujer'),
  };

  static const Map<int, (String, String)> _unovaSpecialClasses = {
    10: ('Maíz', 'assets/sprites/characters/gym_leaders/nds/Unova/chili_unova.gif'),
    11: ('Millo', 'assets/sprites/characters/gym_leaders/nds/Unova/cilan_unova.gif'),
    12: ('Zeo', 'assets/sprites/characters/gym_leaders/nds/Unova/cress_unova.gif'),
    19: ('Aloe', 'assets/sprites/characters/gym_leaders/nds/Unova/lenora_unova.gif'),
    20: ('Camus', 'assets/sprites/characters/gym_leaders/nds/Unova/burgh_unova.gif'),
    21: ('Camila', 'assets/sprites/characters/gym_leaders/nds/Unova/elesa_unova.png'),
    22: ('Yakón', 'assets/sprites/characters/gym_leaders/nds/Unova/clay_unova.gif'),
    23: ('Gerania', 'assets/sprites/characters/gym_leaders/nds/Unova/skyla_unova.gif'),
    37: ('Cheren', 'assets/sprites/characters/rivals/cheren_bw.gif'),
    38: ('Bel', 'assets/sprites/characters/rivals/bianca_bw.gif'),
    40: ('N', 'assets/sprites/characters/rivals/n_bw.gif'),
    54: ('Junco', 'assets/sprites/characters/gym_leaders/nds/Unova/brycen_unova.gif'),
    55: ('Lirio', 'assets/sprites/characters/gym_leaders/nds/Unova/drayden_unova.gif'),
    56: ('Iris', 'assets/sprites/characters/gym_leaders/nds/Unova/iris_unova.png'),
    78: ('Anís', 'assets/sprites/characters/elite_four/nds/Unova/shauntal_unova.gif'),
    79: ('Aza', 'assets/sprites/characters/elite_four/nds/Unova/grimsley_unova.gif'),
    80: ('Catleya', 'assets/sprites/characters/elite_four/nds/Unova/caitlin_unova.gif'),
    81: ('Lotto', 'assets/sprites/characters/elite_four/nds/Unova/marshal_unova.gif'),
    82: ('Ghechis', 'assets/sprites/characters/villains/plasma/ghetsis_bw.png'),
    89: ('Mirto', 'assets/sprites/characters/champions/alder_unova.gif'),
  };

  static const Map<int, int> _unovaTrainerFlagClasses = {
    // Ruta 2; verificado contra el evento de las 18:59 de Pokémon Blanca.
    145: 2, // Joven
  };
}
