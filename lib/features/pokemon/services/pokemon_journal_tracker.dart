import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../data/database/app_database.dart';
import '../../emulator/presentation/widget/libretro_game_view.dart';
import '../decoder/pokemon_decoder.dart';
import '../memory/pokemon_controller_memory_reader.dart';
import '../models/pokemon_game_profile.dart';
import '../models/pokemon_memory_snapshot.dart';

class PokemonJournalTracker {
  final AppDatabase database;
  final String gameId;
  final String romPath;
  final LibretroGameController controller;
  final int Function() playTimeMinutes;

  Timer? _timer;
  PokemonMemorySnapshot? _accepted;
  PokemonMemorySnapshot? _candidate;
  int _candidateRepeats = 0;
  DateTime? _lastSnapshotSavedAt;
  PokemonPartyMember? _lastCapturedPokemon;
  bool _busy = false;

  PokemonJournalTracker({
    required this.database,
    required this.gameId,
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
      final profile = PokemonGameProfile.fromRomPath(romPath);
      final current = PokemonControllerMemoryReader(
        controller: controller,
        profile: profile,
      ).capture();

      if (current == null || !_isPlausible(current)) return;

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

      if (_sameCoreState(previous, stable)) {
        final last = _lastSnapshotSavedAt;
        if (last == null ||
            DateTime.now().difference(last) >= const Duration(minutes: 1)) {
          await _saveSnapshot(stable);
        }
        return;
      }

      _accepted = stable;
      await _recordChanges(previous, stable);
      await _saveSnapshot(stable);
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
        value.partySpeciesIds.every((id) => id >= 0 && id <= 255);
  }

  bool _sameCoreState(PokemonMemorySnapshot a, PokemonMemorySnapshot b) {
    return a.playerName == b.playerName &&
        a.trainerId == b.trainerId &&
        a.currentMapId == b.currentMapId &&
        a.playerX == b.playerX &&
        a.playerY == b.playerY &&
        a.money == b.money &&
        a.badgesMask == b.badgesMask &&
        _sameList(a.partySpeciesIds, b.partySpeciesIds) &&
        a.pokedexSeen == b.pokedexSeen &&
        a.pokedexCaught == b.pokedexCaught;
  }

  bool _sameList(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _recordChanges(
    PokemonMemorySnapshot previous,
    PokemonMemorySnapshot current,
  ) async {
    if (!_isKantoUnlocked(previous) && _isKantoUnlocked(current)) {
      await _ensureKantoUnlockEvent(current);
    }
    if (previous.currentMapId != current.currentMapId) {
      await _insertEvent(
        type: 'location_changed',
        title: 'Nueva ubicación',
        description: PokemonDecoder.mapName(current.profile, current.currentMapId),
        metadata: _metadata(current),
      );
    }

    final newBadges = current.badgesMask & ~previous.badgesMask;
    if (newBadges != 0) {
      for (var index = 0; index < (current.profile.isGen2 ? 16 : 8); index++) {
        if ((newBadges & (1 << index)) == 0) continue;
        final badgeName = PokemonDecoder.badgeName(current.profile, index);
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
        playTimeMinutes: Value(playTimeMinutes()),
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
      'memoryShift': value.memoryShift,
    };
  }
}
