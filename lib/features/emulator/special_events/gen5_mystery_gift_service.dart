import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import '../../pokemon/models/pokemon_game_profile.dart';

enum Gen5MysteryGift {
  libertyPass,
  victini,
  keldeo,
  meloetta,
  genesect,
  shinyDialga,
  shinyPalkia,
  shinyGiratina,
  darkrai,
  zoroark,
  versionLegend,
  mewtwo,
  deoxys,
}

enum Gen5MysteryGiftStatus {
  noSave,
  incompatibleSave,
  unsupported,
  slotsFull,
  available,
  activated,
}

class Gen5MysteryGiftResult {
  final Gen5MysteryGiftStatus status;
  final String? backupPath;

  const Gen5MysteryGiftResult({required this.status, this.backupPath});

  bool get succeeded => status == Gen5MysteryGiftStatus.activated;
}

typedef Gen5GiftAssetLoader = Future<Uint8List> Function(String path);

class Gen5MysteryGiftService {
  static const int _saveSize = 0x80000;
  static const int _blockOffset = 0x1C800;
  static const int _blockLength = 0xA94;
  static const int _encryptedLength = 0xA90;
  static const int _seedOffset = _blockOffset + _encryptedLength;
  static const int _cardStart = 0x100;
  static const int _cardSize = 0xCC;
  static const int _cardCount = 12;

  final Gen5GiftAssetLoader _loadAsset;

  Gen5MysteryGiftService({Gen5GiftAssetLoader? loadAsset})
      : _loadAsset = loadAsset ?? _rootBundleLoader;

  static Future<Uint8List> _rootBundleLoader(String path) async {
    final data = await rootBundle.load(path);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  List<Gen5MysteryGift> eventsFor(PokemonGameVersion version) =>
      switch (version) {
        PokemonGameVersion.black || PokemonGameVersion.white => const [
          Gen5MysteryGift.libertyPass,
          Gen5MysteryGift.victini,
          Gen5MysteryGift.keldeo,
          Gen5MysteryGift.meloetta,
          Gen5MysteryGift.shinyDialga,
          Gen5MysteryGift.shinyPalkia,
          Gen5MysteryGift.shinyGiratina,
          Gen5MysteryGift.darkrai,
          Gen5MysteryGift.zoroark,
          Gen5MysteryGift.versionLegend,
          Gen5MysteryGift.mewtwo,
        ],
        PokemonGameVersion.black2 || PokemonGameVersion.white2 => const [
          Gen5MysteryGift.keldeo,
          Gen5MysteryGift.meloetta,
          Gen5MysteryGift.genesect,
          Gen5MysteryGift.shinyDialga,
          Gen5MysteryGift.shinyPalkia,
          Gen5MysteryGift.shinyGiratina,
          Gen5MysteryGift.deoxys,
        ],
        _ => const [],
      };

  Future<Gen5MysteryGiftStatus> inspect({
    required String savePath,
    required PokemonGameVersion version,
    required Gen5MysteryGift event,
  }) async {
    final assetPath = _assetPath(version, event);
    if (assetPath == null) return Gen5MysteryGiftStatus.unsupported;
    final file = File(savePath);
    if (!await file.exists()) return Gen5MysteryGiftStatus.noSave;
    final bytes = await file.readAsBytes();
    if (bytes.length < _saveSize) {
      return Gen5MysteryGiftStatus.incompatibleSave;
    }
    final gift = await _loadAsset(assetPath);
    if (gift.length != _cardSize) {
      return Gen5MysteryGiftStatus.incompatibleSave;
    }
    final album = _decryptedAlbum(bytes);
    for (var slot = 0; slot < _cardCount; slot++) {
      final offset = _cardStart + slot * _cardSize;
      if (_same(album, offset, gift)) return Gen5MysteryGiftStatus.activated;
    }
    return _emptySlot(album) < 0
        ? Gen5MysteryGiftStatus.slotsFull
        : Gen5MysteryGiftStatus.available;
  }

  Future<Gen5MysteryGiftResult> activate({
    required String savePath,
    required PokemonGameVersion version,
    required Gen5MysteryGift event,
  }) async {
    final assetPath = _assetPath(version, event);
    if (assetPath == null) {
      return const Gen5MysteryGiftResult(
        status: Gen5MysteryGiftStatus.unsupported,
      );
    }
    final status = await inspect(
      savePath: savePath,
      version: version,
      event: event,
    );
    if (status != Gen5MysteryGiftStatus.available) {
      return Gen5MysteryGiftResult(status: status);
    }
    final file = File(savePath);
    final bytes = await file.readAsBytes();
    final gift = await _loadAsset(assetPath);
    final album = _decryptedAlbum(bytes);
    final slot = _emptySlot(album);
    album.setRange(
      _cardStart + slot * _cardSize,
      _cardStart + (slot + 1) * _cardSize,
      gift,
    );
    final seed = _read32(bytes, _seedOffset);
    _crypt(album, seed);
    bytes.setRange(_blockOffset, _blockOffset + _encryptedLength, album);

    final checksum = _crc16Ccitt(
      bytes,
      _blockOffset,
      _blockOffset + _blockLength,
    );
    final checksumOffset = _blockOffset + _blockLength + 2;
    _write16(bytes, checksumOffset, checksum);
    final isBw = version == PokemonGameVersion.black ||
        version == PokemonGameVersion.white;
    _write16(bytes, isBw ? 0x23F44 : 0x25F44, checksum);
    final tableOffset = isBw ? 0x23F00 : 0x25F00;
    final tableLength = isBw ? 0x8C : 0x94;
    final tableChecksum = _crc16Ccitt(
      bytes,
      tableOffset,
      tableOffset + tableLength,
    );
    _write16(bytes, tableOffset + tableLength + 0x0E, tableChecksum);

    final backupPath = await _backupPath(savePath, event);
    await file.copy(backupPath);
    try {
      await file.writeAsBytes(bytes, flush: true);
    } catch (_) {
      await File(backupPath).copy(savePath);
      rethrow;
    }
    return Gen5MysteryGiftResult(
      status: Gen5MysteryGiftStatus.activated,
      backupPath: backupPath,
    );
  }

  Uint8List _decryptedAlbum(List<int> bytes) {
    final album = Uint8List.fromList(
      bytes.sublist(_blockOffset, _blockOffset + _encryptedLength),
    );
    _crypt(album, _read32(bytes, _seedOffset));
    return album;
  }

  void _crypt(Uint8List data, int initialSeed) {
    var seed = initialSeed;
    for (var offset = 0; offset < data.length; offset += 2) {
      seed = (0x41C64E6D * seed + 0x6073) & 0xFFFFFFFF;
      final value = (data[offset] | (data[offset + 1] << 8)) ^ (seed >> 16);
      data[offset] = value & 0xFF;
      data[offset + 1] = (value >> 8) & 0xFF;
    }
  }

  int _emptySlot(List<int> album) {
    for (var slot = 0; slot < _cardCount; slot++) {
      final offset = _cardStart + slot * _cardSize;
      if (album[offset] == 0 && album[offset + 1] == 0) return slot;
    }
    return -1;
  }

  bool _same(List<int> album, int offset, List<int> gift) {
    for (var index = 0; index < gift.length; index++) {
      if (album[offset + index] != gift[index]) return false;
    }
    return true;
  }

  String? _assetPath(PokemonGameVersion version, Gen5MysteryGift event) {
    final isBw = version == PokemonGameVersion.black ||
        version == PokemonGameVersion.white;
    final isB2w2 = version == PokemonGameVersion.black2 ||
        version == PokemonGameVersion.white2;
    if (!isBw && !isB2w2) return null;
    return switch (event) {
      Gen5MysteryGift.libertyPass when isBw =>
        'assets/events/gen5/liberty_pass_spa.pgf',
      Gen5MysteryGift.victini when isBw =>
        'assets/events/gen5/victini_spa.pgf',
      Gen5MysteryGift.keldeo => isBw
          ? 'assets/events/gen5/keldeo_bw_spa.pgf'
          : 'assets/events/gen5/keldeo_b2w2_spa.pgf',
      Gen5MysteryGift.meloetta => 'assets/events/gen5/meloetta_spa.pgf',
      Gen5MysteryGift.genesect when isB2w2 =>
        'assets/events/gen5/genesect_spa.pgf',
      Gen5MysteryGift.shinyDialga =>
        'assets/events/gen5/shiny_dialga_spa.pgf',
      Gen5MysteryGift.shinyPalkia =>
        'assets/events/gen5/shiny_palkia_spa.pgf',
      Gen5MysteryGift.shinyGiratina =>
        'assets/events/gen5/shiny_giratina_spa.pgf',
      Gen5MysteryGift.darkrai when isBw =>
        'assets/events/gen5/darkrai_spa.pgf',
      Gen5MysteryGift.zoroark when isBw =>
        'assets/events/gen5/zoroark_spa.pgf',
      Gen5MysteryGift.versionLegend when version == PokemonGameVersion.black =>
        'assets/events/gen5/zekrom_black_spa.pgf',
      Gen5MysteryGift.versionLegend when version == PokemonGameVersion.white =>
        'assets/events/gen5/reshiram_white_spa.pgf',
      Gen5MysteryGift.mewtwo when isBw =>
        'assets/events/gen5/mewtwo_spa.pgf',
      Gen5MysteryGift.deoxys when isB2w2 =>
        'assets/events/gen5/deoxys_spa.pgf',
      _ => null,
    };
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

  int _read32(List<int> bytes, int offset) => bytes[offset] |
      (bytes[offset + 1] << 8) |
      (bytes[offset + 2] << 16) |
      (bytes[offset + 3] << 24);

  void _write16(Uint8List bytes, int offset, int value) {
    bytes[offset] = value & 0xFF;
    bytes[offset + 1] = (value >> 8) & 0xFF;
  }

  Future<String> _backupPath(String savePath, Gen5MysteryGift event) async {
    final base = '$savePath.before-gen5-${event.name}.bak';
    if (!await File(base).exists()) return base;
    var suffix = 2;
    while (await File('$base.$suffix').exists()) suffix++;
    return '$base.$suffix';
  }
}
