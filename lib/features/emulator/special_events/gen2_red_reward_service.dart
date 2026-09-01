import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import '../../pokemon/models/pokemon_game_profile.dart';
import 'gen2_red_reward.dart';

enum Gen2RedRewardStatus {
  noSave,
  incompatibleSave,
  unsupported,
  partyFull,
  available,
  delivered,
}

class Gen2RedRewardResult {
  final Gen2RedRewardStatus status;
  final String? backupPath;

  const Gen2RedRewardResult({required this.status, this.backupPath});

  bool get succeeded => status == Gen2RedRewardStatus.delivered;
}

/// Delivers the preserved shiny PCNY rewards into an international Gen II
/// party save. Both save copies and their checksums are updated atomically.
class Gen2RedRewardService {
  static const int minimumSaveLength = 0x8000;
  static const int _partyCapacity = 6;
  static const int _partyStructLength = 48;
  static const int _nameLength = 11;

  const Gen2RedRewardService();

  Future<Gen2RedRewardStatus> inspect({
    required String savePath,
    required PokemonGameVersion version,
  }) async {
    if (!_supports(version)) return Gen2RedRewardStatus.unsupported;
    final save = File(savePath);
    if (!await save.exists()) return Gen2RedRewardStatus.noSave;
    return inspectBytes(await save.readAsBytes(), version: version);
  }

  Gen2RedRewardStatus inspectBytes(
    List<int> bytes, {
    required PokemonGameVersion version,
  }) {
    if (!_supports(version)) return Gen2RedRewardStatus.unsupported;
    if (bytes.length < minimumSaveLength) {
      return Gen2RedRewardStatus.incompatibleSave;
    }
    final count = bytes[_partyOffset(version)];
    if (count > _partyCapacity) return Gen2RedRewardStatus.incompatibleSave;
    if (count == _partyCapacity) return Gen2RedRewardStatus.partyFull;
    return Gen2RedRewardStatus.available;
  }

  Future<Gen2RedRewardResult> deliver({
    required String savePath,
    required PokemonGameVersion version,
    required Gen2RedReward reward,
  }) async {
    final status = await inspect(savePath: savePath, version: version);
    if (status != Gen2RedRewardStatus.available) {
      return Gen2RedRewardResult(status: status);
    }

    final save = File(savePath);
    final bytes = await save.readAsBytes();
    final backupPath = await _availableBackupPath(savePath, reward);
    await save.copy(backupPath);

    _appendReward(bytes, version, reward);
    _mirrorAndChecksum(bytes, version);

    try {
      await save.writeAsBytes(bytes, flush: true);
    } catch (_) {
      await File(backupPath).copy(savePath);
      rethrow;
    }
    return Gen2RedRewardResult(
      status: Gen2RedRewardStatus.delivered,
      backupPath: backupPath,
    );
  }

  void _appendReward(
    Uint8List bytes,
    PokemonGameVersion version,
    Gen2RedReward reward,
  ) {
    final party = _partyOffset(version);
    final count = bytes[party];
    bytes[party] = count + 1;
    bytes[party + 1 + count] = reward.speciesId;
    bytes[party + 2 + count] = 0xFF;

    final recordOffset = party + 8 + count * _partyStructLength;
    bytes.setRange(
      recordOffset,
      recordOffset + _partyStructLength,
      _partyRecord(reward),
    );

    final otOffset = party + 8 + _partyCapacity * _partyStructLength;
    final nicknameOffset = otOffset + _partyCapacity * _nameLength;
    bytes.setRange(
      otOffset + count * _nameLength,
      otOffset + (count + 1) * _nameLength,
      _encodeName('PCNY${String.fromCharCode(97 + (reward.requiredLeagueWins - 1) % 4)}'),
    );
    bytes.setRange(
      nicknameOffset + count * _nameLength,
      nicknameOffset + (count + 1) * _nameLength,
      _encodeName(reward.name.toUpperCase()),
    );

    final dexByte = (reward.speciesId - 1) >> 3;
    final dexMask = 1 << ((reward.speciesId - 1) & 7);
    final owned = version == PokemonGameVersion.crystal ? 0x2A27 : 0x2A4C;
    final seen = version == PokemonGameVersion.crystal ? 0x2A47 : 0x2A6C;
    bytes[owned + dexByte] |= dexMask;
    bytes[seen + dexByte] |= dexMask;
  }

  Uint8List _partyRecord(Gen2RedReward reward) {
    final data = Uint8List(_partyStructLength);
    final moves = _moves[reward]!;
    final base = _baseStats[reward.speciesId]!;
    final experience = reward == Gen2RedReward.mew
        ? _mediumSlowExperience(reward.level)
        : (5 * reward.level * reward.level * reward.level) ~/ 4;
    final hp = _stat(base.$1, reward.level, hp: true);

    data[0] = reward.speciesId;
    data[1] = 0;
    data.setRange(2, 6, moves.map((move) => move.$1));
    _write16(data, 6, 2002 + reward.requiredLeagueWins);
    _write24(data, 8, experience);
    // Stat experience remains zero. AA/AA is a legal shiny DV spread.
    data[21] = 0xAA;
    data[22] = 0xAA;
    data.setRange(23, 27, moves.map((move) => move.$2));
    data[27] = 70;
    data[31] = reward.level;
    _write16(data, 34, hp);
    _write16(data, 36, hp);
    _write16(data, 38, _stat(base.$2, reward.level));
    _write16(data, 40, _stat(base.$3, reward.level));
    _write16(data, 42, _stat(base.$4, reward.level));
    _write16(data, 44, _stat(base.$5, reward.level));
    _write16(data, 46, _stat(base.$6, reward.level));
    return data;
  }

  int _stat(int base, int level, {bool hp = false}) {
    final value = ((base * 2 + 10) * level) ~/ 100;
    return hp ? value + level + 10 : value + 5;
  }

  int _mediumSlowExperience(int level) {
    return math.max(
      0,
      (6 * level * level * level) ~/ 5 -
          15 * level * level +
          100 * level -
          140,
    ).toInt();
  }

  List<int> _encodeName(String value) {
    final result = List<int>.filled(_nameLength, 0x50);
    final normalized = value.replaceAll('-', '');
    for (var index = 0; index < normalized.length && index < 10; index++) {
      final code = normalized.codeUnitAt(index);
      if (code >= 65 && code <= 90) {
        result[index] = 0x80 + code - 65;
      } else if (code >= 97 && code <= 122) {
        result[index] = 0xA0 + code - 97;
      }
    }
    return result;
  }

  void _mirrorAndChecksum(
    Uint8List bytes,
    PokemonGameVersion version,
  ) {
    if (version == PokemonGameVersion.crystal) {
      bytes.setRange(0x1209, 0x1D83, bytes.sublist(0x2009, 0x2B83));
      _write16LittleEndian(bytes, 0x2D0D, _sum(bytes, 0x2009, 0x2B83));
      _write16LittleEndian(bytes, 0x1F0D, _sum(bytes, 0x1209, 0x1D83));
      return;
    }

    const sections = <(int, int, int)>[
      (0x2009, 0x222F, 0x15C7),
      (0x222F, 0x23D9, 0x3D96),
      (0x23D9, 0x2856, 0x0C6B),
      (0x2856, 0x288A, 0x7E39),
      (0x288A, 0x2D69, 0x10E8),
    ];
    for (final section in sections) {
      bytes.setRange(
        section.$3,
        section.$3 + section.$2 - section.$1,
        bytes.sublist(section.$1, section.$2),
      );
    }
    _write16LittleEndian(bytes, 0x2D69, _sum(bytes, 0x2009, 0x2D69));
    final backupSum =
        _sum(bytes, 0x0C6B, 0x17ED) +
        _sum(bytes, 0x3D96, 0x3F40) +
        _sum(bytes, 0x7E39, 0x7E6D);
    _write16LittleEndian(bytes, 0x7E6D, backupSum & 0xFFFF);
  }

  int _sum(List<int> bytes, int start, int end) {
    var sum = 0;
    for (var index = start; index < end; index++) {
      sum = (sum + bytes[index]) & 0xFFFF;
    }
    return sum;
  }

  int _partyOffset(PokemonGameVersion version) =>
      version == PokemonGameVersion.crystal ? 0x2865 : 0x288A;

  bool _supports(PokemonGameVersion version) =>
      version == PokemonGameVersion.gold ||
      version == PokemonGameVersion.silver ||
      version == PokemonGameVersion.crystal;

  void _write16(Uint8List bytes, int offset, int value) {
    bytes[offset] = (value >> 8) & 0xFF;
    bytes[offset + 1] = value & 0xFF;
  }

  void _write16LittleEndian(Uint8List bytes, int offset, int value) {
    bytes[offset] = value & 0xFF;
    bytes[offset + 1] = (value >> 8) & 0xFF;
  }

  void _write24(Uint8List bytes, int offset, int value) {
    bytes[offset] = (value >> 16) & 0xFF;
    bytes[offset + 1] = (value >> 8) & 0xFF;
    bytes[offset + 2] = value & 0xFF;
  }

  Future<String> _availableBackupPath(
    String savePath,
    Gen2RedReward reward,
  ) async {
    final base = '$savePath.before-${reward.eventKey}.bak';
    if (!await File(base).exists()) return base;
    var suffix = 2;
    while (await File('$base.$suffix').exists()) {
      suffix++;
    }
    return '$base.$suffix';
  }

  static const Map<int, (int, int, int, int, int, int)> _baseStats = {
    144: (90, 85, 100, 85, 95, 125),
    145: (90, 90, 85, 100, 125, 90),
    146: (90, 100, 90, 90, 125, 85),
    243: (90, 85, 75, 115, 115, 100),
    244: (115, 115, 85, 100, 90, 75),
    245: (100, 75, 115, 85, 90, 115),
    249: (106, 90, 130, 110, 90, 154),
    250: (106, 130, 90, 90, 110, 154),
    150: (106, 110, 90, 130, 154, 90),
    151: (100, 100, 100, 100, 100, 100),
  };

  static const Map<Gen2RedReward, List<(int, int)>> _moves = {
    Gen2RedReward.articuno: [(54, 30), (97, 30), (170, 5), (58, 10)],
    Gen2RedReward.zapdos: [(86, 20), (97, 30), (197, 5), (65, 20)],
    Gen2RedReward.moltres: [(83, 15), (97, 30), (203, 10), (53, 15)],
    Gen2RedReward.raikou: [(43, 30), (84, 30), (46, 20), (98, 30)],
    Gen2RedReward.entei: [(43, 30), (52, 25), (46, 20), (83, 15)],
    Gen2RedReward.suicune: [(43, 30), (55, 25), (46, 20), (16, 35)],
    Gen2RedReward.lugia: [(177, 5), (219, 25), (16, 35), (105, 20)],
    Gen2RedReward.hoOh: [(221, 5), (219, 25), (16, 35), (105, 20)],
    Gen2RedReward.mewtwo: [(244, 10), (248, 15), (54, 30), (94, 10)],
    Gen2RedReward.mew: [(1, 35), (0, 0), (0, 0), (0, 0)],
  };
}
