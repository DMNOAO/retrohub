import 'dart:developer' as developer;

import '../../emulator/data/libretro_bridge.dart';
import '../../emulator/presentation/widget/libretro_game_view.dart';
import '../decoder/pokemon_decoder.dart';
import '../models/pokemon_game_profile.dart';
import '../models/pokemon_memory_snapshot.dart';
import 'pokemon_addresses.dart';
import 'pokemon_emerald_memory_reader.dart';
import 'pokemon_memory_profile_resolver.dart';

class RuntimeRtcDiagnostics {
  final DateTime sampledAt;
  final List<int> rawBytes;
  final int? day;
  final int? hour;
  final int? minute;
  final int? second;
  final String state;

  const RuntimeRtcDiagnostics({
    required this.sampledAt,
    required this.rawBytes,
    required this.day,
    required this.hour,
    required this.minute,
    required this.second,
    required this.state,
  });

  String get rawHex => rawBytes
      .map((int value) => value.toRadixString(16).padLeft(2, '0'))
      .join(' ')
      .toUpperCase();
}

abstract final class RuntimeDiagnosticsLog {
  static const int _maximumEntries = 120;
  static final List<String> journalDecisions = <String>[];
  static final List<String> snapshotComparisons = <String>[];
  static final List<RuntimeRtcDiagnostics> rtcSamples =
      <RuntimeRtcDiagnostics>[];
  static int? _previousRtcSeconds;

  static RuntimeRtcDiagnostics recordRtc(List<int> bytes) {
    int? day;
    int? hour;
    int? minute;
    int? second;
    int? totalSeconds;

    if (bytes.length >= 5) {
      // RETRO_MEMORY_RTC no define un formato común. SameBoy expone los
      // registros MBC3 en orden segundos/minutos/horas/día bajo/día alto.
      // Si el core agrega una cabecera, los registros están al final.
      final int start = bytes.length == 5 ? 0 : bytes.length - 5;
      final int candidateSecond = bytes[start];
      final int candidateMinute = bytes[start + 1];
      final int candidateHour = bytes[start + 2];
      if (candidateSecond < 60 &&
          candidateMinute < 60 &&
          candidateHour < 24) {
        second = candidateSecond;
        minute = candidateMinute;
        hour = candidateHour;
        day = bytes[start + 3] | ((bytes[start + 4] & 0x01) << 8);
        totalSeconds = (((day * 24) + hour) * 60 + minute) * 60 + second;
      }
    }

    String state = 'RTC unavailable';
    if (totalSeconds != null) {
      final int? previous = _previousRtcSeconds;
      state = previous == null
          ? 'RTC initial sample'
          : totalSeconds < previous
              ? 'RTC backwards'
              : totalSeconds == previous
                  ? 'RTC frozen'
                  : 'RTC advancing';
      _previousRtcSeconds = totalSeconds;
    }

    final RuntimeRtcDiagnostics sample = RuntimeRtcDiagnostics(
      sampledAt: DateTime.now(),
      rawBytes: List<int>.unmodifiable(bytes),
      day: day,
      hour: hour,
      minute: minute,
      second: second,
      state: state,
    );
    rtcSamples.add(sample);
    _trim(rtcSamples);
    developer.log(
      '${sample.state} | raw=${sample.rawHex} | '
      'day=${sample.day} hour=${sample.hour} minute=${sample.minute} '
      'second=${sample.second}',
      name: 'RetroHub.RuntimeDiagnostics.RTC',
    );
    return sample;
  }

  static void recordJournalDecision(String decision, String reason) {
    journalDecisions.add(
      '${DateTime.now().toIso8601String()} | $decision | Reason: $reason',
    );
    _trim(journalDecisions);
    developer.log(
      '$decision | Reason: $reason',
      name: 'RetroHub.RuntimeDiagnostics.Journal',
    );
  }

  static void recordSnapshotComparison(String comparison) {
    snapshotComparisons.add(
      '${DateTime.now().toIso8601String()} | $comparison',
    );
    _trim(snapshotComparisons);
    developer.log(
      comparison,
      name: 'RetroHub.RuntimeDiagnostics.Snapshot',
    );
  }

  static void _trim(List<Object> entries) {
    if (entries.length > _maximumEntries) {
      entries.removeRange(0, entries.length - _maximumEntries);
    }
  }
}

class PokemonControllerMemoryReader {
  final LibretroGameController controller;
  final PokemonGameProfile profile;

  const PokemonControllerMemoryReader({
    required this.controller,
    required this.profile,
  });

  PokemonMemorySnapshot? capture() {
    if (!controller.isAttached) return null;

    _captureRtcDiagnostics();

    if (profile.version == PokemonGameVersion.emerald ||
        profile.version == PokemonGameVersion.ruby ||
        profile.version == PokemonGameVersion.sapphire) {
      return PokemonEmeraldMemoryReader(
        controller: controller,
        profile: profile,
      ).capture();
    }

    return _capture(
      (int offset, int length) => controller.readMemoryBlock(
        memoryId: LibretroMemoryRegion.systemRam,
        offset: offset,
        length: length,
      ),
    );
  }

  void _captureRtcDiagnostics() {
    if (!profile.isGen2) return;
    final int size = controller
            .inspectMemoryRegions()['rtc'] ??
        0;
    final List<int> bytes = size <= 0
        ? const <int>[]
        : controller.readMemoryBlock(
            memoryId: LibretroMemoryRegion.rtc,
            offset: 0,
            length: size,
          );
    RuntimeDiagnosticsLog.recordRtc(bytes);
  }

  PokemonMemorySnapshot? _capture(
    List<int> Function(int offset, int length) read,
  ) {
    if (!profile.memoryMapVerified || profile.addresses == null) return null;

    final ResolvedPokemonMemoryProfile? resolved =
        PokemonMemoryProfileResolver.resolve(
      profile: profile,
      read: read,
    );
    if (resolved == null) return null;

    final PokemonMemoryAddresses a = resolved.addresses;

    int byte(int offset) {
      final List<int> values = read(offset, 1);
      return values.isEmpty ? 0 : values.first;
    }

    int word(int offset) {
      final List<int> values = read(offset, 2);
      return values.length < 2 ? 0 : (values[0] << 8) | values[1];
    }

    final int count = byte(a.partyCount);
    final List<int> species = read(a.partySpecies, 7);
    final List<PokemonPartyMember> party = <PokemonPartyMember>[];

    for (int i = 0; i < count && i < species.length; i++) {
      final int id = species[i];
      final int dex = PokemonDecoder.dexId(profile, id);
      final List<int> mon = read(
        a.partyMons + i * a.partyStructLength,
        a.partyStructLength,
      );
      if (mon.length != a.partyStructLength) continue;

      bool shiny = false;
      if (profile.isGen2 &&
          a.partyDvOffset != null &&
          mon.length > a.partyDvOffset! + 1) {
        shiny = PokemonDecoder.isGen2Shiny(
          mon[a.partyDvOffset!],
          mon[a.partyDvOffset! + 1],
        );
      }

      final int level = a.partyLevelOffset < mon.length
          ? mon[a.partyLevelOffset]
          : 0;

      party.add(
        PokemonPartyMember(
          internalSpeciesId: id,
          pokedexId: dex,
          name: PokemonDecoder.pokemonName(dex),
          level: level,
          isShiny: shiny,
        ),
      );
    }

    final int map = profile.isGen2 && a.currentMapGroup != null
        ? (byte(a.currentMapGroup!) << 8) | byte(a.currentMap)
        : byte(a.currentMap);

    final int johtoBadges = byte(a.obtainedBadges);
    final int badges = johtoBadges |
        ((a.kantoBadges == null ? 0 : byte(a.kantoBadges!)) << 8);

    final List<int> moneyBytes = read(a.playerMoney, 3);
    final int money = profile.isGen2
        ? PokemonDecoder.decodeUnsignedBigEndian(moneyBytes)
        : _safeBcd(moneyBytes);

    final int? battleState = a.battleMode != null
        ? byte(a.battleMode!)
        : (a.isInBattle != null ? byte(a.isInBattle!) : null);
    final int? otherTrainerClassId =
        a.otherTrainerClass != null ? byte(a.otherTrainerClass!) : null;
    final int? otherTrainerIdValue =
        a.otherTrainerId != null ? byte(a.otherTrainerId!) : null;
    final int? battleResultRaw =
        a.battleResult != null ? byte(a.battleResult!) : null;

    final List<int> seenBytes = read(a.pokedexSeen, a.pokedexBytes);
    final List<int> caughtBytes = read(a.pokedexOwned, a.pokedexBytes);

    List<int> decodedDexIds(List<int> bytes) {
      final result = <int>[];
      final maximum = profile.isGen2 ? 251 : 151;
      for (var byteIndex = 0; byteIndex < bytes.length; byteIndex++) {
        for (var bit = 0; bit < 8; bit++) {
          final dexId = byteIndex * 8 + bit + 1;
          if (dexId <= maximum && (bytes[byteIndex] & (1 << bit)) != 0) {
            result.add(dexId);
          }
        }
      }
      return result;
    }

    return PokemonMemorySnapshot(
      capturedAt: DateTime.now(),
      profile: profile,
      memoryShift: resolved.shift,
      playerName: PokemonDecoder.decodeText(
        read(a.playerName, a.playerNameLength),
      ),
      trainerId: word(a.playerId),
      currentMapId: map,
      playerX: byte(a.playerX),
      playerY: byte(a.playerY),
      money: money,
      badgesMask: badges,
      pokedexSeen: PokemonDecoder.countBits(seenBytes),
      pokedexCaught: PokemonDecoder.countBits(caughtBytes),
      seenPokemonIds: decodedDexIds(seenBytes),
      caughtPokemonIds: decodedDexIds(caughtBytes),
      party: party,
      battleState: battleState,
      otherTrainerClassId: otherTrainerClassId,
      otherTrainerId: otherTrainerIdValue,
      battleResultRaw: battleResultRaw,
    );
  }

  int _safeBcd(List<int> bytes) {
    final int value = PokemonDecoder.decodeBcd(bytes);
    return value < 0 ? 0 : value;
  }
}
