import 'dart:io';
import 'dart:typed_data';

import '../../pokemon/models/pokemon_game_profile.dart';

enum Gen1MewEventStatus {
  noSave,
  incompatibleSave,
  unsupported,
  partyFull,
  available,
  delivered,
}

class Gen1MewEventResult {
  final Gen1MewEventStatus status;
  final String? backupPath;

  const Gen1MewEventResult({required this.status, this.backupPath});

  bool get succeeded => status == Gen1MewEventStatus.delivered;
}

/// Delivers a level 5 event Mew to international Red, Blue, and Yellow saves.
class Gen1MewEventService {
  static const int _minimumSaveLength = 0x8000;
  static const int _partyOffset = 0x2F2C;
  static const int _partyCapacity = 6;
  static const int _recordLength = 44;
  static const int _nameLength = 11;
  static const int _mewInternalId = 0x15;

  const Gen1MewEventService();

  Future<Gen1MewEventStatus> inspect({
    required String savePath,
    required PokemonGameVersion version,
  }) async {
    if (!_supports(version)) return Gen1MewEventStatus.unsupported;
    final save = File(savePath);
    if (!await save.exists()) return Gen1MewEventStatus.noSave;
    final bytes = await save.readAsBytes();
    if (bytes.length < _minimumSaveLength) {
      return Gen1MewEventStatus.incompatibleSave;
    }
    final count = bytes[_partyOffset];
    if (count > _partyCapacity) return Gen1MewEventStatus.incompatibleSave;
    if (count == _partyCapacity) return Gen1MewEventStatus.partyFull;
    return Gen1MewEventStatus.available;
  }

  Future<Gen1MewEventResult> deliver({
    required String savePath,
    required PokemonGameVersion version,
  }) async {
    final status = await inspect(savePath: savePath, version: version);
    if (status != Gen1MewEventStatus.available) {
      return Gen1MewEventResult(status: status);
    }
    final save = File(savePath);
    final bytes = await save.readAsBytes();
    final backupPath = await _backupPath(savePath);
    await save.copy(backupPath);
    _appendMew(bytes);
    bytes[0x3523] = (0xFF - _sum(bytes, 0x2598, 0x3523)) & 0xFF;
    try {
      await save.writeAsBytes(bytes, flush: true);
    } catch (_) {
      await File(backupPath).copy(savePath);
      rethrow;
    }
    return Gen1MewEventResult(
      status: Gen1MewEventStatus.delivered,
      backupPath: backupPath,
    );
  }

  void _appendMew(Uint8List bytes) {
    final count = bytes[_partyOffset];
    bytes[_partyOffset] = count + 1;
    bytes[_partyOffset + 1 + count] = _mewInternalId;
    bytes[_partyOffset + 2 + count] = 0xFF;

    final recordOffset = _partyOffset + 8 + count * _recordLength;
    bytes.setRange(recordOffset, recordOffset + _recordLength, _mewRecord());
    final otOffset = _partyOffset + 8 + _partyCapacity * _recordLength;
    final nicknameOffset = otOffset + _partyCapacity * _nameLength;
    bytes.setRange(
      otOffset + count * _nameLength,
      otOffset + (count + 1) * _nameLength,
      _encodeName('GF'),
    );
    bytes.setRange(
      nicknameOffset + count * _nameLength,
      nicknameOffset + (count + 1) * _nameLength,
      _encodeName('MEW'),
    );

    const dexByte = (151 - 1) >> 3;
    const dexMask = 1 << ((151 - 1) & 7);
    bytes[0x25A3 + dexByte] |= dexMask;
    bytes[0x25B6 + dexByte] |= dexMask;
  }

  Uint8List _mewRecord() {
    final data = Uint8List(_recordLength);
    const level = 5;
    const hp = 26;
    const otherStat = 16;
    data[0] = _mewInternalId;
    _write16(data, 1, hp);
    data[3] = level;
    data[5] = 21; // Psychic.
    data[6] = 21;
    data[7] = 45;
    data[8] = 1; // Pound.
    _write16(data, 12, 22796);
    _write24(data, 14, 135);
    data[27] = 0xAA;
    data[28] = 0xAA;
    data[29] = 35;
    data[33] = level;
    _write16(data, 34, hp);
    for (final offset in const <int>[36, 38, 40, 42]) {
      _write16(data, offset, otherStat);
    }
    return data;
  }

  List<int> _encodeName(String value) {
    final result = List<int>.filled(_nameLength, 0x50);
    for (var index = 0; index < value.length && index < 10; index++) {
      result[index] = 0x80 + value.codeUnitAt(index) - 65;
    }
    return result;
  }

  int _sum(List<int> bytes, int start, int end) {
    var sum = 0;
    for (var index = start; index < end; index++) {
      sum = (sum + bytes[index]) & 0xFF;
    }
    return sum;
  }

  void _write16(Uint8List bytes, int offset, int value) {
    bytes[offset] = (value >> 8) & 0xFF;
    bytes[offset + 1] = value & 0xFF;
  }

  void _write24(Uint8List bytes, int offset, int value) {
    bytes[offset] = (value >> 16) & 0xFF;
    bytes[offset + 1] = (value >> 8) & 0xFF;
    bytes[offset + 2] = value & 0xFF;
  }

  bool _supports(PokemonGameVersion version) =>
      version == PokemonGameVersion.redBlue ||
      version == PokemonGameVersion.yellow;

  Future<String> _backupPath(String savePath) async {
    final base = '$savePath.before-gen1-mew-event.bak';
    if (!await File(base).exists()) return base;
    var suffix = 2;
    while (await File('$base.$suffix').exists()) suffix++;
    return '$base.$suffix';
  }
}
