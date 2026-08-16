import 'dart:io';
import 'dart:typed_data';

import '../../pokemon/models/pokemon_game_profile.dart';

enum Gen3SpecialEvent {
  eonTicket,
  mysticTicket,
  auroraTicket,
  oldSeaMap,
}

enum Gen3SpecialEventStatus {
  noSave,
  incompatibleSave,
  leagueRequired,
  available,
  activated,
  unsupported,
}

class Gen3SpecialEventActivationResult {
  final Gen3SpecialEventStatus status;
  final String? backupPath;

  const Gen3SpecialEventActivationResult({
    required this.status,
    this.backupPath,
  });

  bool get succeeded => status == Gen3SpecialEventStatus.activated;
}

class Gen3SpecialEventService {
  static const int minimumSaveLength = 0x20000;
  static const int sectorSize = 0x1000;
  static const int sectorsPerSlot = 14;
  static const int sectorDataSize = 0xF80;
  static const int sectorIdOffset = 0xFF4;
  static const int sectorChecksumOffset = 0xFF6;
  static const int sectorSignatureOffset = 0xFF8;
  static const int sectorCounterOffset = 0xFFC;
  static const int sectorSignature = 0x08012025;

  const Gen3SpecialEventService();

  List<Gen3SpecialEvent> eventsFor(PokemonGameVersion version) {
    return switch (version) {
      PokemonGameVersion.ruby || PokemonGameVersion.sapphire =>
        const <Gen3SpecialEvent>[Gen3SpecialEvent.eonTicket],
      PokemonGameVersion.emerald => const <Gen3SpecialEvent>[
          Gen3SpecialEvent.eonTicket,
          Gen3SpecialEvent.oldSeaMap,
          Gen3SpecialEvent.auroraTicket,
          Gen3SpecialEvent.mysticTicket,
        ],
      PokemonGameVersion.fireRed || PokemonGameVersion.leafGreen =>
        const <Gen3SpecialEvent>[
          Gen3SpecialEvent.auroraTicket,
          Gen3SpecialEvent.mysticTicket,
        ],
      _ => const <Gen3SpecialEvent>[],
    };
  }

  Future<Gen3SpecialEventStatus> inspect({
    required String savePath,
    required PokemonGameVersion version,
    required Gen3SpecialEvent event,
  }) async {
    final config = _configFor(version, event);
    if (config == null) return Gen3SpecialEventStatus.unsupported;

    final save = File(savePath);
    if (!await save.exists()) return Gen3SpecialEventStatus.noSave;
    return inspectBytes(
      await save.readAsBytes(),
      version: version,
      event: event,
    );
  }

  Gen3SpecialEventStatus inspectBytes(
    List<int> source, {
    required PokemonGameVersion version,
    required Gen3SpecialEvent event,
  }) {
    final config = _configFor(version, event);
    final layout = _layoutFor(version);
    if (config == null || layout == null) {
      return Gen3SpecialEventStatus.unsupported;
    }
    if (source.length < minimumSaveLength) {
      return Gen3SpecialEventStatus.incompatibleSave;
    }

    final bytes = Uint8List.fromList(source);
    final slot = _activeSlot(bytes);
    if (slot == null) return Gen3SpecialEventStatus.incompatibleSave;

    final gameClear = _readFlag(
      bytes,
      slot,
      saveBlock1Offset: layout.flagsOffset,
      flagId: layout.gameClearFlag,
    );
    final enabled = _readFlag(
      bytes,
      slot,
      saveBlock1Offset: layout.flagsOffset,
      flagId: config.enableFlag,
    );
    final hasItem = _hasKeyItem(
      bytes,
      slot,
      layout: layout,
      itemId: config.itemId,
    );

    if (enabled && hasItem) return Gen3SpecialEventStatus.activated;
    if (!gameClear) return Gen3SpecialEventStatus.leagueRequired;
    return Gen3SpecialEventStatus.available;
  }

  Future<Gen3SpecialEventActivationResult> activate({
    required String savePath,
    required PokemonGameVersion version,
    required Gen3SpecialEvent event,
  }) async {
    final status = await inspect(
      savePath: savePath,
      version: version,
      event: event,
    );
    if (status != Gen3SpecialEventStatus.available) {
      return Gen3SpecialEventActivationResult(status: status);
    }

    final config = _configFor(version, event)!;
    final layout = _layoutFor(version)!;
    final save = File(savePath);
    final bytes = await save.readAsBytes();
    final slot = _activeSlot(bytes)!;
    final backupPath = await _availableBackupPath(savePath, event.name);
    await save.copy(backupPath);

    try {
      _addKeyItem(
        bytes,
        slot,
        layout: layout,
        itemId: config.itemId,
      );
      _writeFlag(
        bytes,
        slot,
        saveBlock1Offset: layout.flagsOffset,
        flagId: config.enableFlag,
      );
      _refreshChangedChecksums(bytes, slot, layout);
      await save.writeAsBytes(bytes, flush: true);
    } catch (_) {
      await File(backupPath).copy(savePath);
      rethrow;
    }

    return Gen3SpecialEventActivationResult(
      status: Gen3SpecialEventStatus.activated,
      backupPath: backupPath,
    );
  }

  _Gen3Slot? _activeSlot(Uint8List bytes) {
    final slots = <_Gen3Slot>[];
    for (var slotIndex = 0; slotIndex < 2; slotIndex++) {
      final sections = <int, int>{};
      int? counter;
      var valid = true;
      for (var physical = 0; physical < sectorsPerSlot; physical++) {
        final base = (slotIndex * sectorsPerSlot + physical) * sectorSize;
        if (_u32(bytes, base + sectorSignatureOffset) != sectorSignature) {
          valid = false;
          break;
        }
        final id = _u16(bytes, base + sectorIdOffset);
        final currentCounter = _u32(bytes, base + sectorCounterOffset);
        if (id >= sectorsPerSlot ||
            sections.containsKey(id) ||
            (counter != null && counter != currentCounter)) {
          valid = false;
          break;
        }
        sections[id] = base;
        counter ??= currentCounter;
      }
      if (valid && sections.length == sectorsPerSlot && counter != null) {
        slots.add(_Gen3Slot(sections: sections, counter: counter));
      }
    }
    if (slots.isEmpty) return null;
    if (slots.length == 1) return slots.first;
    return slots[1].counter > slots[0].counter ? slots[1] : slots[0];
  }

  bool _readFlag(
    Uint8List bytes,
    _Gen3Slot slot, {
    required int saveBlock1Offset,
    required int flagId,
  }) {
    final location = _block1Location(
      slot,
      saveBlock1Offset + (flagId >> 3),
    );
    return (bytes[location] & (1 << (flagId & 7))) != 0;
  }

  void _writeFlag(
    Uint8List bytes,
    _Gen3Slot slot, {
    required int saveBlock1Offset,
    required int flagId,
  }) {
    final location = _block1Location(
      slot,
      saveBlock1Offset + (flagId >> 3),
    );
    bytes[location] |= 1 << (flagId & 7);
  }

  bool _hasKeyItem(
    Uint8List bytes,
    _Gen3Slot slot, {
    required _Gen3Layout layout,
    required int itemId,
  }) {
    for (var index = 0; index < layout.keyItemSlots; index++) {
      final offset = layout.keyItemsOffset + index * 4;
      if (_readBlock1U16(bytes, slot, offset) == itemId) return true;
    }
    return false;
  }

  void _addKeyItem(
    Uint8List bytes,
    _Gen3Slot slot, {
    required _Gen3Layout layout,
    required int itemId,
  }) {
    int? emptyOffset;
    for (var index = 0; index < layout.keyItemSlots; index++) {
      final offset = layout.keyItemsOffset + index * 4;
      final existing = _readBlock1U16(bytes, slot, offset);
      if (existing == itemId) return;
      if (existing == 0 && emptyOffset == null) emptyOffset = offset;
    }
    if (emptyOffset == null) {
      throw StateError('No queda espacio en el bolsillo de objetos clave.');
    }

    _writeBlock1U16(bytes, slot, emptyOffset, itemId);
    var quantity = 1;
    if (layout.encryptionKeyOffset != null) {
      final saveBlock2 = slot.sections[0]!;
      quantity ^= _u16(bytes, saveBlock2 + layout.encryptionKeyOffset!);
    }
    _writeBlock1U16(bytes, slot, emptyOffset + 2, quantity);
  }

  int _block1Location(_Gen3Slot slot, int offset) {
    final chunk = offset ~/ sectorDataSize;
    final sectionId = 1 + chunk;
    final section = slot.sections[sectionId];
    if (section == null) throw StateError('Sección de guardado incompleta.');
    return section + (offset % sectorDataSize);
  }

  int _readBlock1U16(Uint8List bytes, _Gen3Slot slot, int offset) {
    return _u16(bytes, _block1Location(slot, offset));
  }

  void _writeBlock1U16(
    Uint8List bytes,
    _Gen3Slot slot,
    int offset,
    int value,
  ) {
    _setU16(bytes, _block1Location(slot, offset), value);
  }

  void _refreshChangedChecksums(
    Uint8List bytes,
    _Gen3Slot slot,
    _Gen3Layout layout,
  ) {
    final changedIds = <int>{
      1 + layout.keyItemsOffset ~/ sectorDataSize,
      1 + layout.flagsOffset ~/ sectorDataSize,
    };
    for (final id in changedIds) {
      final base = slot.sections[id]!;
      _setU16(
        bytes,
        base + sectorChecksumOffset,
        _checksum(bytes, base, sectorDataSize),
      );
    }
  }

  int _checksum(Uint8List bytes, int offset, int length) {
    var sum = 0;
    for (var index = 0; index < length; index += 4) {
      sum = (sum + _u32(bytes, offset + index)) & 0xFFFFFFFF;
    }
    return ((sum >> 16) + (sum & 0xFFFF)) & 0xFFFF;
  }

  int _u16(Uint8List bytes, int offset) {
    return bytes[offset] | (bytes[offset + 1] << 8);
  }

  int _u32(Uint8List bytes, int offset) {
    return _u16(bytes, offset) | (_u16(bytes, offset + 2) << 16);
  }

  void _setU16(Uint8List bytes, int offset, int value) {
    bytes[offset] = value & 0xFF;
    bytes[offset + 1] = (value >> 8) & 0xFF;
  }

  _Gen3Layout? _layoutFor(PokemonGameVersion version) {
    return switch (version) {
      PokemonGameVersion.ruby || PokemonGameVersion.sapphire =>
        const _Gen3Layout(
          keyItemsOffset: 0x5B0,
          keyItemSlots: 20,
          flagsOffset: 0x1220,
          gameClearFlag: 0x804,
        ),
      PokemonGameVersion.emerald => const _Gen3Layout(
          keyItemsOffset: 0x5D8,
          keyItemSlots: 30,
          flagsOffset: 0x1270,
          gameClearFlag: 0x864,
          encryptionKeyOffset: 0xAC,
        ),
      PokemonGameVersion.fireRed || PokemonGameVersion.leafGreen =>
        const _Gen3Layout(
          keyItemsOffset: 0x3B8,
          keyItemSlots: 30,
          flagsOffset: 0x0EE0,
          gameClearFlag: 0x82C,
          encryptionKeyOffset: 0xF20,
        ),
      _ => null,
    };
  }

  _Gen3EventConfig? _configFor(
    PokemonGameVersion version,
    Gen3SpecialEvent event,
  ) {
    if (!eventsFor(version).contains(event)) return null;
    return switch ((version, event)) {
      (
        PokemonGameVersion.ruby || PokemonGameVersion.sapphire,
        Gen3SpecialEvent.eonTicket,
      ) =>
        const _Gen3EventConfig(itemId: 275, enableFlag: 0x853),
      (PokemonGameVersion.emerald, Gen3SpecialEvent.eonTicket) =>
        const _Gen3EventConfig(itemId: 275, enableFlag: 0x8B3),
      (PokemonGameVersion.emerald, Gen3SpecialEvent.auroraTicket) =>
        const _Gen3EventConfig(itemId: 371, enableFlag: 0x8D5),
      (PokemonGameVersion.emerald, Gen3SpecialEvent.oldSeaMap) =>
        const _Gen3EventConfig(itemId: 376, enableFlag: 0x8D6),
      (PokemonGameVersion.emerald, Gen3SpecialEvent.mysticTicket) =>
        const _Gen3EventConfig(itemId: 370, enableFlag: 0x8E0),
      (
        PokemonGameVersion.fireRed || PokemonGameVersion.leafGreen,
        Gen3SpecialEvent.auroraTicket,
      ) =>
        const _Gen3EventConfig(itemId: 371, enableFlag: 0x84B),
      (
        PokemonGameVersion.fireRed || PokemonGameVersion.leafGreen,
        Gen3SpecialEvent.mysticTicket,
      ) =>
        const _Gen3EventConfig(itemId: 370, enableFlag: 0x84A),
      _ => null,
    };
  }

  Future<String> _availableBackupPath(
    String savePath,
    String eventName,
  ) async {
    final base = '$savePath.before-$eventName.bak';
    if (!await File(base).exists()) return base;
    var suffix = 2;
    while (await File('$base.$suffix').exists()) {
      suffix++;
    }
    return '$base.$suffix';
  }
}

class _Gen3Slot {
  final Map<int, int> sections;
  final int counter;

  const _Gen3Slot({required this.sections, required this.counter});
}

class _Gen3Layout {
  final int keyItemsOffset;
  final int keyItemSlots;
  final int flagsOffset;
  final int gameClearFlag;
  final int? encryptionKeyOffset;

  const _Gen3Layout({
    required this.keyItemsOffset,
    required this.keyItemSlots,
    required this.flagsOffset,
    required this.gameClearFlag,
    this.encryptionKeyOffset,
  });
}

class _Gen3EventConfig {
  final int itemId;
  final int enableFlag;

  const _Gen3EventConfig({
    required this.itemId,
    required this.enableFlag,
  });
}
