import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import '../../pokemon/models/pokemon_game_profile.dart';

enum Gen4MysteryGift {
  manaphyEgg,
  darkrai,
  shaymin,
  arceus,
}

enum Gen4MysteryGiftStatus {
  noSave,
  incompatibleSave,
  unsupported,
  slotsFull,
  available,
  activated,
}

class Gen4MysteryGiftResult {
  final Gen4MysteryGiftStatus status;
  final String? backupPath;

  const Gen4MysteryGiftResult({required this.status, this.backupPath});

  bool get succeeded => status == Gen4MysteryGiftStatus.activated;
}

typedef Gen4GiftAssetLoader = Future<Uint8List> Function(String path);

/// Installs preserved Gen IV Wonder Cards into the active save block.
/// The game then performs the original delivery through its Poké Mart NPC.
class Gen4MysteryGiftService {
  static const int _saveSize = 0x80000;
  static const int _partitionSize = 0x40000;
  static const int _pgtSize = 0x104;
  static const int _pcdSize = 0x358;
  static const int _pgtCount = 8;
  static const int _pcdCount = 3;
  static const int _flagRegionSize = 0x100;
  static const int _dpSentinelBytes = 11 * 4;
  static const int _deliveryManFlag = 2047;
  static const int _dpSlotSentinel = 0xEDB88320;

  final Gen4GiftAssetLoader _loadAsset;

  Gen4MysteryGiftService({Gen4GiftAssetLoader? loadAsset})
      : _loadAsset = loadAsset ?? _rootBundleLoader;

  static Future<Uint8List> _rootBundleLoader(String path) async {
    final data = await rootBundle.load(path);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  List<Gen4MysteryGift> eventsFor(PokemonGameVersion version) => switch (version) {
        PokemonGameVersion.diamond ||
        PokemonGameVersion.pearl ||
        PokemonGameVersion.platinum => Gen4MysteryGift.values,
        _ => const <Gen4MysteryGift>[],
      };

  Future<Gen4MysteryGiftStatus> inspect({
    required String savePath,
    required PokemonGameVersion version,
    required Gen4MysteryGift event,
  }) async {
    final config = _config(version, event);
    if (config == null) return Gen4MysteryGiftStatus.unsupported;
    final file = File(savePath);
    if (!await file.exists()) return Gen4MysteryGiftStatus.noSave;
    final bytes = await file.readAsBytes();
    if (bytes.length < _saveSize) {
      return Gen4MysteryGiftStatus.incompatibleSave;
    }
    final block = _activeBlock(bytes, config.generalSize);
    if (!_validGeneral(bytes, block, config.generalSize)) {
      return Gen4MysteryGiftStatus.incompatibleSave;
    }
    final gift = await _loadAsset(config.assetPath);
    final expectedSize = config.isPcd ? _pcdSize : _pgtSize;
    if (gift.length != expectedSize) {
      return Gen4MysteryGiftStatus.incompatibleSave;
    }
    final pgtStart = block + config.mysteryOffset + config.cardStart;
    final searchStart = config.isPcd
        ? pgtStart + _pgtCount * _pgtSize
        : pgtStart;
    final searchSize = config.isPcd ? _pcdSize : _pgtSize;
    final searchCount = config.isPcd ? _pcdCount : _pgtCount;
    for (var slot = 0; slot < searchCount; slot++) {
      final offset = searchStart + slot * searchSize;
      if (_sameGift(bytes, offset, gift)) {
        return Gen4MysteryGiftStatus.activated;
      }
    }
    final pgtSlot = _emptySlot(
      bytes,
      pgtStart,
      _pgtSize,
      _pgtCount,
    );
    if (pgtSlot < 0) return Gen4MysteryGiftStatus.slotsFull;
    if (config.isPcd) {
      final pcdStart = block + config.mysteryOffset + config.cardStart +
          _pgtCount * _pgtSize;
      if (_emptySlot(bytes, pcdStart, _pcdSize, _pcdCount) < 0) {
        return Gen4MysteryGiftStatus.slotsFull;
      }
    }
    return Gen4MysteryGiftStatus.available;
  }

  bool _sameGift(List<int> save, int offset, List<int> gift) {
    for (var index = 0; index < gift.length; index++) {
      // The embedded PGT's PCD slot reference is assigned during insertion.
      if (index == 2) continue;
      if (save[offset + index] != gift[index]) return false;
    }
    return true;
  }

  Future<Gen4MysteryGiftResult> activate({
    required String savePath,
    required PokemonGameVersion version,
    required Gen4MysteryGift event,
  }) async {
    final config = _config(version, event);
    if (config == null) {
      return const Gen4MysteryGiftResult(
        status: Gen4MysteryGiftStatus.unsupported,
      );
    }
    final status = await inspect(
      savePath: savePath,
      version: version,
      event: event,
    );
    if (status != Gen4MysteryGiftStatus.available) {
      return Gen4MysteryGiftResult(status: status);
    }

    final file = File(savePath);
    final bytes = await file.readAsBytes();
    final gift = await _loadAsset(config.assetPath);
    final expectedSize = config.isPcd ? _pcdSize : _pgtSize;
    if (gift.length != expectedSize) {
      return const Gen4MysteryGiftResult(
        status: Gen4MysteryGiftStatus.incompatibleSave,
      );
    }
    final backupPath = await _backupPath(savePath, event);
    await file.copy(backupPath);

    final block = _activeBlock(bytes, config.generalSize);
    final mystery = block + config.mysteryOffset;
    final pgtStart = mystery + config.cardStart;
    final pgtSlot = _emptySlot(bytes, pgtStart, _pgtSize, _pgtCount);
    final pgt = Uint8List.fromList(gift.sublist(0, _pgtSize));
    if (config.isPcd) {
      final pcdStart = pgtStart + _pgtCount * _pgtSize;
      final pcdSlot = _emptySlot(bytes, pcdStart, _pcdSize, _pcdCount);
      pgt[2] = pcdSlot + 1; // D/P/Pt use one-based PCD references.
      bytes.setRange(
        pcdStart + pcdSlot * _pcdSize,
        pcdStart + (pcdSlot + 1) * _pcdSize,
        gift,
      );
      _setDpSentinel(bytes, config, mystery, _pgtCount + pcdSlot);
    } else {
      pgt[2] = 4; // No corresponding PCD in D/P/Pt.
    }
    bytes.setRange(
      pgtStart + pgtSlot * _pgtSize,
      pgtStart + (pgtSlot + 1) * _pgtSize,
      pgt,
    );
    _setDpSentinel(bytes, config, mystery, pgtSlot);
    bytes[block + 72] |= 1; // Unlock Mystery Gift in the title menu.
    bytes[mystery + (_deliveryManFlag >> 3)] |=
        1 << (_deliveryManFlag & 7);

    final checksum = _crc16Ccitt(
      bytes,
      block,
      block + config.generalSize - 0x14,
    );
    _write16(bytes, block + config.generalSize - 2, checksum);

    try {
      await file.writeAsBytes(bytes, flush: true);
    } catch (_) {
      await File(backupPath).copy(savePath);
      rethrow;
    }
    return Gen4MysteryGiftResult(
      status: Gen4MysteryGiftStatus.activated,
      backupPath: backupPath,
    );
  }

  void _setDpSentinel(
    Uint8List bytes,
    _Gen4GiftConfig config,
    int mystery,
    int slot,
  ) {
    if (!config.hasSentinels) return;
    _write32(bytes, mystery + _flagRegionSize + slot * 4, _dpSlotSentinel);
  }

  int _emptySlot(List<int> bytes, int start, int size, int count) {
    for (var index = 0; index < count; index++) {
      if (_read16(bytes, start + index * size) == 0) return index;
    }
    return -1;
  }

  int _activeBlock(List<int> bytes, int generalSize) {
    final footer = generalSize - 0x14;
    final firstMajor = _read32(bytes, footer);
    final secondMajor = _read32(bytes, _partitionSize + footer);
    if (firstMajor != secondMajor) {
      return firstMajor > secondMajor ? 0 : _partitionSize;
    }
    final firstMinor = _read32(bytes, footer + 4);
    final secondMinor = _read32(bytes, _partitionSize + footer + 4);
    return firstMinor >= secondMinor ? 0 : _partitionSize;
  }

  bool _validGeneral(List<int> bytes, int block, int size) {
    final magic = _read32(bytes, block + size - 8);
    return magic == 0x20060623 || magic == 0x20070903;
  }

  int _crc16Ccitt(List<int> bytes, int start, int end) {
    var top = 0xFF;
    var bottom = 0xFF;
    for (var index = start; index < end; index++) {
      var value = bytes[index] ^ top;
      value ^= value >> 4;
      top = (bottom ^ (value >> 3) ^ (value << 4)) & 0xFF;
      bottom = (value ^ (value << 5)) & 0xFF;
    }
    return (top << 8) | bottom;
  }

  int _read16(List<int> bytes, int offset) =>
      bytes[offset] | (bytes[offset + 1] << 8);

  int _read32(List<int> bytes, int offset) =>
      _read16(bytes, offset) | (_read16(bytes, offset + 2) << 16);

  void _write16(Uint8List bytes, int offset, int value) {
    bytes[offset] = value & 0xFF;
    bytes[offset + 1] = (value >> 8) & 0xFF;
  }

  void _write32(Uint8List bytes, int offset, int value) {
    _write16(bytes, offset, value);
    _write16(bytes, offset + 2, value >> 16);
  }

  _Gen4GiftConfig? _config(
    PokemonGameVersion version,
    Gen4MysteryGift event,
  ) {
    final isDp = version == PokemonGameVersion.diamond ||
        version == PokemonGameVersion.pearl;
    if (!isDp && version != PokemonGameVersion.platinum) return null;
    final asset = switch ((version, event)) {
      (_, Gen4MysteryGift.manaphyEgg) =>
        'assets/events/gen4/manaphy_egg.pgt',
      (PokemonGameVersion.platinum, Gen4MysteryGift.darkrai) =>
        'assets/events/gen4/pt_member_card_spa.wc4',
      (PokemonGameVersion.platinum, Gen4MysteryGift.shaymin) =>
        'assets/events/gen4/pt_oaks_letter_spa.wc4',
      (_, Gen4MysteryGift.darkrai) =>
        'assets/events/gen4/dp_movie_darkrai_spa.wc4',
      (_, Gen4MysteryGift.shaymin) =>
        'assets/events/gen4/dp_movie_shaymin_spa.wc4',
      (_, Gen4MysteryGift.arceus) =>
        'assets/events/gen4/dppt_movie_arceus_spa.wc4',
    };
    return _Gen4GiftConfig(
      generalSize: isDp ? 0xC100 : 0xCF2C,
      mysteryOffset: isDp ? 0xA6D0 : 0xB4C0,
      cardStart: _flagRegionSize + (isDp ? _dpSentinelBytes : 0),
      hasSentinels: isDp,
      assetPath: asset,
      isPcd: event != Gen4MysteryGift.manaphyEgg,
    );
  }

  Future<String> _backupPath(
    String savePath,
    Gen4MysteryGift event,
  ) async {
    final base = '$savePath.before-gen4-${event.name}.bak';
    if (!await File(base).exists()) return base;
    var suffix = 2;
    while (await File('$base.$suffix').exists()) suffix++;
    return '$base.$suffix';
  }
}

class _Gen4GiftConfig {
  final int generalSize;
  final int mysteryOffset;
  final int cardStart;
  final bool hasSentinels;
  final String assetPath;
  final bool isPcd;

  const _Gen4GiftConfig({
    required this.generalSize,
    required this.mysteryOffset,
    required this.cardStart,
    required this.hasSentinels,
    required this.assetPath,
    required this.isPcd,
  });
}
