import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/features/emulator/special_events/gen5_mystery_gift_service.dart';
import 'package:retrohub/features/pokemon/models/pokemon_game_profile.dart';

void main() {
  final gift = Uint8List(0xCC)..[0] = 42;
  final service = Gen5MysteryGiftService(loadAsset: (_) async => gift);

  test('expone regalos distintos para BW y B2W2', () {
    expect(
      service.eventsFor(PokemonGameVersion.black),
      contains(Gen5MysteryGift.libertyPass),
    );
    expect(
      service.eventsFor(PokemonGameVersion.black2),
      contains(Gen5MysteryGift.genesect),
    );
    expect(
      service.eventsFor(PokemonGameVersion.black2),
      isNot(contains(Gen5MysteryGift.libertyPass)),
    );
  });

  test('cifra una PGF, actualiza checksums y evita duplicados', () async {
    final directory = await Directory.systemTemp.createTemp('retrohub-gen5-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/black.srm');
    final bytes = Uint8List(0x80000);
    _u32(bytes, 0x1D290, 0x12345678);
    _crypt(bytes, 0x1C800, 0xA90, 0x12345678);
    await file.writeAsBytes(bytes);

    final result = await service.activate(
      savePath: file.path,
      version: PokemonGameVersion.black,
      event: Gen5MysteryGift.libertyPass,
    );
    expect(result.succeeded, isTrue);
    expect(await File(result.backupPath!).exists(), isTrue);
    expect(
      await service.inspect(
        savePath: file.path,
        version: PokemonGameVersion.black,
        event: Gen5MysteryGift.libertyPass,
      ),
      Gen5MysteryGiftStatus.activated,
    );
    final activated = await file.readAsBytes();
    expect(_u16(activated, 0x1D296), _u16(activated, 0x23F44));
    expect(_u16(activated, 0x23F9A), isNot(0));
  });
}

void _crypt(Uint8List bytes, int start, int length, int initialSeed) {
  var seed = initialSeed;
  for (var offset = start; offset < start + length; offset += 2) {
    seed = (0x41C64E6D * seed + 0x6073) & 0xFFFFFFFF;
    final value = _u16(bytes, offset) ^ (seed >> 16);
    bytes[offset] = value & 0xFF;
    bytes[offset + 1] = (value >> 8) & 0xFF;
  }
}

int _u16(List<int> bytes, int offset) =>
    bytes[offset] | (bytes[offset + 1] << 8);

void _u32(Uint8List bytes, int offset, int value) {
  for (var index = 0; index < 4; index++) {
    bytes[offset + index] = (value >> (index * 8)) & 0xFF;
  }
}
