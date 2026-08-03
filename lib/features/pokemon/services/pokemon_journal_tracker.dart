import 'dart:async';
import 'dart:developer' as developer;
import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../data/database/app_database.dart';
import '../../emulator/presentation/widget/libretro_game_view.dart';
import '../decoder/pokemon_decoder.dart';
import '../memory/pokemon_controller_memory_reader.dart';
import '../models/pokemon_game_profile.dart';
import '../models/pokemon_gym_leader.dart';
import '../models/pokemon_memory_snapshot.dart';
import '../models/emerald_trainer.dart';
import '../models/ruby_sapphire_trainer.dart';
import '../models/trainer_class.dart';

class PokemonJournalTracker {
  final AppDatabase database;
  final String gameId;
  final String gameTitle;
  final String romPath;
  final LibretroGameController controller;
  final int Function() playTimeMinutes;

  Timer? _timer;
  PokemonMemorySnapshot? _accepted;
  PokemonMemorySnapshot? _candidate;
  int _candidateRepeats = 0;
  DateTime? _lastSnapshotSavedAt;
  PokemonPartyMember? _lastCapturedPokemon;
  String? _lastDefeatedTrainer;
  bool _persistentStateRestored = false;
  bool _gymLeaderEventsRepaired = false;
  bool _busy = false;

  // Estado transitorio de combate (Fase 4.2/4.3): se recuerda contra qué
  // entrenador se está peleando mientras dura el combate, para poder
  // identificarlo recién cuando el combate termina.
  int? _pendingTrainerClass;
  int? _pendingTrainerId;
  int? _pendingBattleResult;
  bool _trainerBattlePending = false;
  // Snapshot crudo del sondeo anterior, solo para detectar transiciones de
  // combate. Se actualiza en TODOS los sondeos (a diferencia de _accepted,
  // que se congela mientras el resto del estado no cambie) porque durante
  // un combate el dinero/equipo/ubicación normalmente no cambian, y con el
  // mecanismo de estabilidad el estado de combate quedaría atascado.
  PokemonMemorySnapshot? _lastRawSnapshot;

  // IDs reales de clase de entrenador (constants/trainer_constants.asm,
  // Gen2 Crystal/Gold, pegado por el usuario). Rival y Campeón se
  // registran como eventos especiales; los líderes de gimnasio se
  // excluyen aquí porque ya se registran vía medalla obtenida (evitar
  // duplicados).
  static const int _classRival1 = 0x09;
  static const int _classRival2 = 0x2A;
  static const int _classChampion = 0x10; // Lance
  static const Set<int> _eliteFourClasses = {0x0B, 0x0D, 0x0E, 0x0F}; // Will, Bruno, Karen, Koga
  static const Set<int> _gymLeaderClasses = {
    0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, // Johto
    0x11, 0x12, 0x13, 0x15, 0x1A, 0x23, 0x2E, // Kanto
  };

  PokemonJournalTracker({
    required this.database,
    required this.gameId,
    required this.gameTitle,
    required this.romPath,
    required this.controller,
    required this.playTimeMinutes,
  });

  void start() {
    _timer ??= Timer.periodic(
      const Duration(seconds: 2),
      (_) => unawaited(_poll()),
    );
    unawaited(_poll());
  }

  Future<void> stop({bool saveFinalSnapshot = true}) async {
    _timer?.cancel();
    _timer = null;
    if (saveFinalSnapshot && _accepted != null) {
      await _saveSnapshot(_accepted!);
    }
  }

  Future<void> _poll() async {
    if (_busy || !controller.isAttached) return;
    _busy = true;

    try {
      final profile = PokemonGameProfile.fromGameIdentity(
        gameTitle: gameTitle,
        romPath: romPath,
      );
      await _restorePersistentState();
      final current = PokemonControllerMemoryReader(
        controller: controller,
        profile: profile,
      ).capture();

      if (current == null || !_isPlausible(current)) return;

      await _ensureEmeraldGymLeaderEvents(current);

      final PokemonMemorySnapshot? previousRaw = _lastRawSnapshot;
      _lastRawSnapshot = current;
      if (previousRaw != null) {
        await _recordBattleChanges(previousRaw, current);
      }

      if (_candidate != null && _sameCoreState(_candidate!, current)) {
        _candidateRepeats++;
      } else {
        _candidate = current;
        _candidateRepeats = 1;
      }

      // Evita registrar bytes transitorios: el estado debe repetirse dos lecturas.
      if (_candidateRepeats < 2) return;

      final stable = _candidate!;
      final previous = _accepted;

      if (previous == null) {
        _accepted = stable;
        await _saveSnapshot(stable);
        await _insertEvent(
          type: 'pokemon_progress_detected',
          title: 'Partida Pokémon detectada',
          description: 'RetroHub comenzó a leer el progreso de la ROM.',
          metadata: _metadata(stable),
        );
        await _ensureKantoUnlockEvent(stable);
        return;
      }

      _accepted = stable;

      if (_sameCoreState(previous, stable)) {
        final last = _lastSnapshotSavedAt;
        if (last == null ||
            DateTime.now().difference(last) >= const Duration(minutes: 1)) {
          await _saveSnapshot(stable);
        }
        return;
      }

      await _recordChanges(previous, stable);
      await _saveSnapshot(stable);
    } catch (error, stackTrace) {
      developer.log(
        'Error al actualizar la bitácora Pokémon',
        name: 'PokemonJournalTracker',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _busy = false;
    }
  }

  bool _isPlausible(PokemonMemorySnapshot value) {
    return value.money >= 0 &&
        value.money <= 999999 &&
        value.badgesMask >= 0 &&
        value.badgesMask <= 0xFFFF &&
        value.partySpeciesIds.length <= 6 &&
        value.partySpeciesIds.every((id) => id >= 1 && id <= 386);
  }

  bool _sameCoreState(PokemonMemorySnapshot a, PokemonMemorySnapshot b) {
    return a.playerName == b.playerName &&
        a.trainerId == b.trainerId &&
        a.currentMapId == b.currentMapId &&
        a.playerX == b.playerX &&
        a.playerY == b.playerY &&
        a.money == b.money &&
        a.badgesMask == b.badgesMask &&
        _sameParty(a.party, b.party) &&
        a.pokedexSeen == b.pokedexSeen &&
        a.pokedexCaught == b.pokedexCaught &&
        a.nationalDexUnlocked == b.nationalDexUnlocked;
  }

  bool _sameList(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _sameParty(List<PokemonPartyMember> a, List<PokemonPartyMember> b) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      final left = a[index];
      final right = b[index];
      if (left.pokedexId != right.pokedexId ||
          left.level != right.level ||
          left.currentHp != right.currentHp ||
          left.maximumHp != right.maximumHp ||
          left.status != right.status ||
          left.nickname != right.nickname ||
          left.isShiny != right.isShiny) {
        return false;
      }
    }
    return true;
  }

  Future<void> _recordChanges(
    PokemonMemorySnapshot previous,
    PokemonMemorySnapshot current,
  ) async {
    if (!previous.nationalDexUnlocked && current.nationalDexUnlocked) {
      await _insertEvent(
        type: 'national_pokedex_unlocked',
        title: 'Pokédex Nacional desbloqueada',
        description: 'Ya puedes consultar las 386 especies conocidas.',
        metadata: _metadata(current),
      );
    }
    if (!_isKantoUnlocked(previous) && _isKantoUnlocked(current)) {
      await _ensureKantoUnlockEvent(current);
    }
    if (previous.currentMapId != current.currentMapId) {
      final PokemonLocation? location =
          PokemonDecoder.locationFor(current.profile, current.currentMapId);
      final String name = location?.name ??
          PokemonDecoder.mapName(current.profile, current.currentMapId);

      final (String type, String title) = switch (location?.kind) {
        PokemonLocationKind.city => ('city_arrived', 'Llegó a $name'),
        PokemonLocationKind.route => ('route_arrived', 'Entró a $name'),
        PokemonLocationKind.league => ('league_arrived', 'Llegó a la Liga Pokémon'),
        _ => ('location_changed', 'Nueva ubicación'),
      };

      await _insertEvent(
        type: type,
        title: title,
        description: name,
        metadata: _metadata(current),
      );
    }

    final newBadges = current.badgesMask & ~previous.badgesMask;
    if (newBadges != 0) {
      for (var index = 0; index < (current.profile.isGen2 ? 16 : 8); index++) {
        if ((newBadges & (1 << index)) == 0) continue;
        final badgeName = PokemonDecoder.badgeName(current.profile, index);

        // Se registra primero la derrota del líder (si está confirmado el
        // nombre para esa medalla) y luego la medalla, para mantener el
        // orden cronológico real: primero el combate, después el premio.
        final GymLeaderInfo? leader =
            GymLeaderAssetResolver.forBadge(current.profile, index);
        if (leader != null) {
          _lastDefeatedTrainer = leader.name;
          await _insertEvent(
            type: 'gym_leader_defeated',
            title: 'Derrotó a ${leader.name}',
            description: 'Venció al líder de gimnasio ${leader.name}.',
            metadata: <String, dynamic>{
              ..._metadata(current),
              'leaderName': leader.name,
              'spritePath': leader.spritePath,
              'badgeIndex': index,
            },
          );
        }

        await _insertEvent(
          type: 'badge_obtained',
          title: badgeName,
          description: 'Conseguiste $badgeName. Ahora tienes ${current.badgeCount} medalla(s).',
          metadata: <String, dynamic>{
            ..._metadata(current),
            'newBadgesMask': newBadges,
            'badgeIndex': index,
            'badgeName': badgeName,
          },
        );
      }
    }

    final caughtIncrease = current.pokedexCaught - previous.pokedexCaught;
    if (caughtIncrease > 0) {
      final previousIds = previous.partySpeciesIds.toSet();
      final candidates = current.party.where((pokemon) => !previousIds.contains(pokemon.pokedexId)).toList();
      if (candidates.isNotEmpty) {
        _lastCapturedPokemon = candidates.last;
        await _insertEvent(
          type: 'pokemon_captured',
          title: '${_lastCapturedPokemon!.name} capturado',
          description: 'Se registró una nueva captura en la Pokédex.',
          metadata: <String, dynamic>{
            ..._metadata(current),
            'pokemonId': _lastCapturedPokemon!.pokedexId,
            'pokemonName': _lastCapturedPokemon!.name,
            'level': _lastCapturedPokemon!.level,
            'isShiny': _lastCapturedPokemon!.isShiny,
          },
        );
      }
    }

    if (!_sameList(previous.partySpeciesIds, current.partySpeciesIds)) {
      await _insertEvent(
        type: 'party_changed',
        title: 'Equipo actualizado',
        description: 'El equipo ahora tiene ${current.partySpeciesIds.length} Pokémon.',
        metadata: _metadata(current),
      );
    }
  }


  /// Detecta el fin de un combate de entrenador y registra el evento
  /// correspondiente (rival, Alto Mando, Campeón, o genérico).
  ///
  /// Se corre en cada sondeo, independientemente de si cambió el resto
  /// del estado (dinero, ubicación, etc.), porque un combate puede
  /// empezar y terminar sin que nada más cambie mientras tanto.
  Future<void> _recordBattleChanges(
    PokemonMemorySnapshot previous,
    PokemonMemorySnapshot current,
  ) async {
    if (current.profile.version == PokemonGameVersion.emerald ||
        current.profile.version == PokemonGameVersion.ruby ||
        current.profile.version == PokemonGameVersion.sapphire) {
      final Set<int> previousIds = previous.defeatedTrainerIds.toSet();
      final List<int> newTrainerIds = current.defeatedTrainerIds
          .where((id) => !previousIds.contains(id))
          .toList(growable: false);
      if (newTrainerIds.isNotEmpty) {
        // La bandera se activa únicamente tras la primera victoria. Es una
        // señal estable y compatible con ROMs de cualquier idioma.
        _trainerBattlePending = false;
        _pendingTrainerClass = null;
        _pendingTrainerId = null;
        _pendingBattleResult = null;
        for (final int trainerId in newTrainerIds) {
          await _recordGen3TrainerVictory(
            current: current,
            trainerId: trainerId,
          );
        }
        return;
      }
    }

    if (current.battleState == null) return; // versión sin soporte de combate

    if (current.battleState == 2) {
      _trainerBattlePending = true;
      _pendingTrainerClass = current.otherTrainerClassId;
      _pendingTrainerId = current.otherTrainerId;
      final int? rawResult = current.battleResultRaw;
      if (current.profile.version != PokemonGameVersion.emerald ||
          (rawResult != null && rawResult != 0)) {
        _pendingBattleResult = rawResult;
      }
    } else if (_trainerBattlePending && current.battleResultRaw != null) {
      // Gen III asigna el resultado al cerrar el combate. Conservar la
      // última lectura evita perderlo cuando los globals se limpian antes
      // del siguiente sondeo.
      final int rawResult = current.battleResultRaw!;
      if (current.profile.version != PokemonGameVersion.emerald ||
          rawResult != 0) {
        _pendingBattleResult = rawResult;
      }
    }

    final bool nowOutOfBattle = current.battleState == 0;
    // En Android (sobre todo con x2/x4) el sondeo puede observar estados
    // transitorios entre el combate de entrenador y el regreso a 0. No se
    // exige que la lectura inmediatamente anterior siga siendo 2: la sesión
    // queda pendiente hasta que el juego esté realmente fuera de combate.
    if (!_trainerBattlePending || !nowOutOfBattle) return;

    final int? classId = _pendingTrainerClass;
    final int? trainerId = _pendingTrainerId;
    _trainerBattlePending = false;
    _pendingTrainerClass = null;
    _pendingTrainerId = null;

    // Gen I/II usan WIN = 0 en wBattleResult y conservan flags auxiliares en
    // los bits altos. Emerald usa gBattleOutcome y B_OUTCOME_WON = 1. Ante
    // cualquier duda (sin dato de resultado) no se registra un evento.
    final int? result = _pendingBattleResult ?? current.battleResultRaw;
    _pendingBattleResult = null;
    if (result == null) return;
    final bool won = current.profile.isGen3
        ? result == 1
        : (result & 0x3F) == 0;
    if (!won) return;

    if (current.profile.isGen3) {
      await _recordGen3TrainerVictory(
        current: current,
        trainerId: trainerId,
      );
      return;
    }

    if (classId == null || classId == 0) {
      // Gen1 (Red/Blue/Yellow): no se pudo verificar esta sesión cómo
      // identificar la clase del entrenador rival, así que solo se
      // registra el evento genérico (permitido explícitamente como
      // "primera versión" en la especificación de esta fase).
      if (current.profile.isGen2) return; // Gen2 sin classId: no arriesgar
      await _insertEvent(
        type: 'trainer_defeated',
        title: 'Ganó un combate de entrenador',
        description: 'Venció a un entrenador durante su aventura.',
        metadata: _metadata(current),
      );
      await _rememberLastDefeatedTrainer('Entrenador', current);
      return;
    }

    if (_gymLeaderClasses.contains(classId)) {
      return; // ya se registra vía medalla obtenida, evitar duplicado
    }

    if (classId == _classRival1 || classId == _classRival2) {
      await _insertEvent(
        type: 'rival_defeated',
        title: 'Derrotó a su rival',
        description: 'Ganó el combate contra su rival.',
        metadata: <String, dynamic>{
          ..._metadata(current),
          'trainerClassId': classId,
          'trainerId': trainerId,
          'spritePath': TrainerClassResolver.forClassId(classId)?.spritePath,
        },
      );
      await _rememberLastDefeatedTrainer('Rival', current);
      return;
    }

    if (classId == _classChampion) {
      await _insertEvent(
        type: 'champion_defeated',
        title: 'Se convirtió en Campeón Pokémon',
        description: 'Derrotó al Campeón de la Liga Pokémon.',
        metadata: <String, dynamic>{
          ..._metadata(current),
          'trainerClassId': classId,
          'spritePath': TrainerClassResolver.forClassId(classId)?.spritePath,
        },
      );
      await _rememberLastDefeatedTrainer(
        TrainerClassResolver.forClassId(classId)?.name ?? 'Campeón',
        current,
      );
      return;
    }

    if (_eliteFourClasses.contains(classId)) {
      final String name =
          TrainerClassResolver.forClassId(classId)?.name ?? 'Alto Mando';
      await _insertEvent(
        type: 'elite_four_defeated',
        title: 'Derrotó a $name',
        description: 'Venció a un miembro del Alto Mando.',
        metadata: <String, dynamic>{
          ..._metadata(current),
          'trainerClassId': classId,
          'spritePath': TrainerClassResolver.forClassId(classId)?.spritePath,
        },
      );
      await _rememberLastDefeatedTrainer(name, current);
      return;
    }

    final TrainerClassInfo? info = TrainerClassResolver.forClassId(classId);
    await _insertEvent(
      type: 'trainer_defeated',
      title: info != null
          ? 'Ganó contra ${info.name}'
          : 'Ganó un combate de entrenador',
      description: 'Venció a un entrenador durante su aventura.',
      metadata: <String, dynamic>{
        ..._metadata(current),
        'trainerClassId': classId,
        'trainerClass': info?.name,
        'spritePath': info?.spritePath,
      },
    );
    await _rememberLastDefeatedTrainer(info?.name ?? 'Entrenador', current);
  }

  Future<void> _recordGen3TrainerVictory({
    required PokemonMemorySnapshot current,
    required int? trainerId,
  }) async {
    if (trainerId == null || trainerId <= 0) return;

    final EmeraldTrainerInfo info =
        current.profile.version == PokemonGameVersion.emerald
            ? EmeraldTrainerResolver.forTrainerId(trainerId)
            : RubySapphireTrainerResolver.forTrainerId(trainerId);
    if (info.kind == EmeraldTrainerKind.gymLeader) {
      // La primera victoria ya se registra al detectar la nueva medalla.
      // Así se conserva un solo evento con el orden combate -> medalla.
      return;
    }

    final (String type, String title, String description) = switch (info.kind) {
      EmeraldTrainerKind.rival => (
          'rival_defeated',
          'Derrotó a ${info.name}',
          'Ganó el combate contra su rival.',
        ),
      EmeraldTrainerKind.eliteFour => (
          'elite_four_defeated',
          'Derrotó a ${info.name}',
          'Venció a un miembro del Alto Mando de Hoenn.',
        ),
      EmeraldTrainerKind.champion => (
          'champion_defeated',
          'Se convirtió en Campeón Pokémon',
          'Derrotó al Campeón de la Liga de Hoenn.',
        ),
      EmeraldTrainerKind.frontierBrain => (
          'trainer_defeated',
          'Derrotó a ${info.name}',
          'Venció a un Cerebro de la Frontera.',
        ),
      EmeraldTrainerKind.specialTrainer => (
          'trainer_defeated',
          'Derrotó a ${info.name}',
          current.profile.version == PokemonGameVersion.emerald
              ? 'Superó uno de los combates especiales de Pokémon Esmeralda.'
              : 'Superó uno de los combates especiales de Pokémon Ruby/Sapphire.',
        ),
      EmeraldTrainerKind.regular => (
          'trainer_defeated',
          'Ganó contra ${info.name}',
          'Venció a un entrenador durante su aventura.',
        ),
      EmeraldTrainerKind.gymLeader => throw StateError(
          'Los líderes se registran al obtener la medalla.',
        ),
    };

    await _insertEvent(
      type: type,
      title: title,
      description: description,
      metadata: <String, dynamic>{
        ..._metadata(current),
        'trainerId': trainerId,
        'trainerClass': info.name,
        'spritePath': info.spritePath,
      },
    );
    await _rememberLastDefeatedTrainer(info.name, current);
  }

  Future<void> _ensureEmeraldGymLeaderEvents(
    PokemonMemorySnapshot current,
  ) async {
    if (_gymLeaderEventsRepaired ||
        current.profile.version != PokemonGameVersion.emerald) {
      return;
    }
    _gymLeaderEventsRepaired = true;

    final events = await database.getProgressEventsByGame(gameId);
    final recordedBadgeIndexes = <int>{};
    for (final event in events) {
      if (event.eventType != 'gym_leader_defeated') continue;
      final rawMetadata = event.metadataJson;
      if (rawMetadata == null || rawMetadata.trim().isEmpty) continue;
      try {
        final decoded = jsonDecode(rawMetadata);
        if (decoded is! Map || decoded['badgeIndex'] is! num) continue;

        final badgeIndex = (decoded['badgeIndex'] as num).toInt();
        recordedBadgeIndexes.add(badgeIndex);

        // Los eventos recuperados por versiones anteriores pueden conservar
        // una ruta nula o antigua. Migra el registro existente a la ruta
        // canónica sin alterar su fecha ni crear una segunda victoria.
        final leader =
            GymLeaderAssetResolver.forBadge(current.profile, badgeIndex);
        if (leader != null && decoded['spritePath'] != leader.spritePath) {
          final updatedMetadata = Map<String, dynamic>.from(decoded);
          updatedMetadata['leaderName'] = leader.name;
          updatedMetadata['spritePath'] = leader.spritePath;
          await database.updateProgressEventMetadata(
            event.id,
            jsonEncode(updatedMetadata),
          );
        }
      } catch (_) {}
    }

    for (var index = 0; index < 8; index++) {
      if ((current.badgesMask & (1 << index)) == 0 ||
          recordedBadgeIndexes.contains(index)) {
        continue;
      }
      final leader = GymLeaderAssetResolver.forBadge(current.profile, index);
      if (leader == null) continue;

      _lastDefeatedTrainer = leader.name;
      await _insertEvent(
        type: 'gym_leader_defeated',
        title: 'Derrotó a ${leader.name}',
        description: 'Venció al líder de gimnasio ${leader.name}.',
        metadata: <String, dynamic>{
          ..._metadata(current),
          'leaderName': leader.name,
          'spritePath': leader.spritePath,
          'badgeIndex': index,
          'recoveredFromBadge': true,
        },
      );
    }
  }

  Future<void> _restorePersistentState() async {
    if (_persistentStateRestored) return;
    _persistentStateRestored = true;

    final latest = await database.getLatestProgressSnapshot(gameId);
    final storedName = latest?.lastDefeatedTrainer?.trim();
    if (storedName != null && storedName.isNotEmpty) {
      _lastDefeatedTrainer = storedName;
      return;
    }

    // Compatibilidad con eventos creados antes de que el resumen guardara
    // este campo: recupera el combate más reciente de Historia completa.
    final events = await database.getProgressEventsByGame(gameId);
    for (final event in events) {
      final name = _trainerNameFromEvent(event);
      if (name != null) {
        _lastDefeatedTrainer = name;
        return;
      }
    }
  }

  String? _trainerNameFromEvent(GameProgressEvent event) {
    const supportedTypes = <String>{
      'trainer_defeated',
      'rival_defeated',
      'gym_leader_defeated',
      'elite_four_defeated',
      'champion_defeated',
    };
    if (!supportedTypes.contains(event.eventType)) return null;

    Map<String, dynamic> metadata = const <String, dynamic>{};
    final rawMetadata = event.metadataJson;
    if (rawMetadata != null && rawMetadata.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawMetadata);
        if (decoded is Map) metadata = Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }

    final explicit = metadata['leaderName'] ?? metadata['trainerClass'];
    final explicitName = explicit?.toString().trim();
    if (explicitName != null && explicitName.isNotEmpty) return explicitName;
    if (event.eventType == 'rival_defeated') return 'Rival';
    if (event.eventType == 'champion_defeated') return 'Campeón Pokémon';

    const prefixes = <String>['Derrotó a ', 'Ganó contra '];
    for (final prefix in prefixes) {
      if (event.title.startsWith(prefix)) {
        final value = event.title.substring(prefix.length).trim();
        if (value.isNotEmpty) return value;
      }
    }
    return 'Entrenador';
  }

  Future<void> _rememberLastDefeatedTrainer(
    String name,
    PokemonMemorySnapshot snapshot,
  ) async {
    _lastDefeatedTrainer = name;
    await _saveSnapshot(snapshot);
  }

  bool _isKantoUnlocked(PokemonMemorySnapshot value) {
    if (!value.profile.isGen2) return false;
    final johtoMask = value.badgesMask & 0xff;
    final kantoMask = (value.badgesMask >> 8) & 0xff;
    return johtoMask == 0xff || kantoMask != 0 || value.badgeCount >= 8;
  }

  Future<void> _ensureKantoUnlockEvent(PokemonMemorySnapshot value) async {
    if (!_isKantoUnlocked(value)) return;
    final existing = await database.getProgressEventsByGame(gameId);
    if (existing.any((event) => event.eventType == 'kanto_unlocked')) return;

    await _insertEvent(
      type: 'kanto_unlocked',
      title: 'Nueva región desbloqueada: Kanto',
      description: 'La aventura continúa más allá de Johto. Las ocho medallas de Kanto ya están disponibles.',
      metadata: <String, dynamic>{
        ..._metadata(value),
        'region': 'kanto',
        'totalBadgesAvailable': 16,
      },
    );
  }

  Future<void> _saveSnapshot(PokemonMemorySnapshot value) async {
    await database.insertProgressSnapshot(
      GameProgressSnapshotsCompanion(
        gameId: Value(gameId),
        savedAt: Value(DateTime.now()),
        playTimeMinutes: Value(value.gamePlayTimeMinutes ?? playTimeMinutes()),
        currentLocation: Value(
          PokemonDecoder.mapName(value.profile, value.currentMapId),
        ),
        partyJson: Value(
          jsonEncode(
            value.party.map((pokemon) => pokemon.toJson()).toList(),
          ),
        ),
        badgesJson: Value(
          jsonEncode(
            List.generate(
              value.profile.isGen2 ? 16 : 8,
              (index) => <String, dynamic>{
                'index': index,
                'obtained': (value.badgesMask & (1 << index)) != 0,
              },
            ),
          ),
        ),
        badgesCount: Value(value.badgeCount),
        pokedexSeen: Value(value.pokedexSeen),
        pokedexCaught: Value(value.pokedexCaught),
        lastCapturedPokemonJson: Value(
          _lastCapturedPokemon == null ? null : jsonEncode(_lastCapturedPokemon!.toJson()),
        ),
        lastDefeatedTrainer: Value(_lastDefeatedTrainer),
        leagueWins: const Value(0),
      ),
    );
    _lastSnapshotSavedAt = DateTime.now();
  }

  Future<void> _insertEvent({
    required String type,
    required String title,
    required String description,
    required Map<String, dynamic> metadata,
  }) {
    return database.insertProgressEvent(
      GameProgressEventsCompanion(
        gameId: Value(gameId),
        createdAt: Value(DateTime.now()),
        eventType: Value(type),
        title: Value(title),
        description: Value(description),
        metadataJson: Value(
          jsonEncode(<String, dynamic>{
            'playTimeMinutes': playTimeMinutes(),
            ...metadata,
          }),
        ),
      ),
    );
  }

  Map<String, dynamic> _metadata(PokemonMemorySnapshot value) {
    return <String, dynamic>{
      'source': 'pokemon_memory',
      'profile': value.profile.displayName,
      'playerName': value.playerName,
      'trainerId': value.trainerId,
      'mapId': value.currentMapId,
      'mapName': PokemonDecoder.mapName(value.profile, value.currentMapId),
      'x': value.playerX,
      'y': value.playerY,
      'money': value.money,
      'badgesMask': value.badgesMask,
      'partySpeciesIds': value.partySpeciesIds,
      'party': value.party.map((pokemon) => pokemon.toJson()).toList(),
      'pokedexSeen': value.pokedexSeen,
      'pokedexCaught': value.pokedexCaught,
      'nationalDexUnlocked': value.nationalDexUnlocked,
      'seenPokemonIds': value.seenPokemonIds,
      'caughtPokemonIds': value.caughtPokemonIds,
      'memoryShift': value.memoryShift,
      'playTimeMinutes': value.gamePlayTimeMinutes ?? playTimeMinutes(),
      'gamePlayTimeMinutes': value.gamePlayTimeMinutes,
    };
  }
}
