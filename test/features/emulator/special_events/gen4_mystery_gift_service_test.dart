import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/features/emulator/special_events/gen4_mystery_gift_service.dart';
import 'package:retrohub/features/pokemon/models/pokemon_game_profile.dart';

void main() {
  final pcd = Uint8List(0x358)..[0] = 1;
  final pgt = Uint8List(0x104)..[0] = 2;
  final service = Gen4MysteryGiftService(
    loadAsset: (path) async => path.endsWith('.pgt') ? pgt : pcd,
  );

  test('instala una Wonder Card en Diamante y evita duplicarla', () async {
    final directory = await Directory.systemTemp.createTemp('retrohub-gen4-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/diamond.srm');
    await file.writeAsBytes(_save(generalSize: 0xC100, magic: 0x20060623));

    final result = await service.activate(
      savePath: file.path,
      version: PokemonGameVersion.diamond,
      event: Gen4MysteryGift.darkrai,
    );
    expect(result.succeeded, isTrue);
    expect(await File(result.backupPath!).exists(), isTrue);

    final bytes = await file.readAsBytes();
    const mystery = 0xA6D0;
    const cardStart = 0x100 + 11 * 4;
    const pcdStart = mystery + cardStart + 8 * 0x104;
    expect(_u32(bytes, mystery + 0x100), 0xEDB88320);
    expect(_u32(bytes, mystery + 0x100 + 8 * 4), 0xEDB88320);
    expect(bytes[mystery + cardStart + 2], 1);
    expect(bytes[pcdStart], 1);
    expect(bytes[72] & 1, 1);
    expect(bytes[mystery + 255] & 0x80, 0x80);
    expect(
      await service.inspect(
        savePath: file.path,
        version: PokemonGameVersion.diamond,
        event: Gen4MysteryGift.darkrai,
      ),
      Gen4MysteryGiftStatus.activated,
    );
  });

  test('instala el Huevo de Manaphy como PGT sin PCD en Platino', () async {
    final directory = await Directory.systemTemp.createTemp('retrohub-gen4-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/platinum.srm');
    await file.writeAsBytes(_save(generalSize: 0xCF2C, magic: 0x20070903));

    final result = await service.activate(
      savePath: file.path,
      version: PokemonGameVersion.platinum,
      event: Gen4MysteryGift.manaphyEgg,
    );
    expect(result.succeeded, isTrue);
    final bytes = await file.readAsBytes();
    const pgtStart = 0xB4C0 + 0x100;
    expect(bytes[pgtStart], 2);
    expect(bytes[pgtStart + 2], 4);
    expect(
      await service.inspect(
        savePath: file.path,
        version: PokemonGameVersion.platinum,
        event: Gen4MysteryGift.manaphyEgg,
      ),
      Gen4MysteryGiftStatus.activated,
    );
  });

  test('usa el bloque Mystery Gift y footer propios de HGSS', () async {
    final directory = await Directory.systemTemp.createTemp('retrohub-hgss-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/heartgold.srm');
    await file.writeAsBytes(_save(generalSize: 0xF628, magic: 0x20060623));

    final result = await service.activate(
      savePath: file.path,
      version: PokemonGameVersion.heartGold,
      event: Gen4MysteryGift.enigmaStone,
    );
    expect(result.succeeded, isTrue);
    final bytes = await file.readAsBytes();
    const pgtStart = 0x9D3C + 0x100;
    expect(bytes[pgtStart], 1);
    expect(bytes[pgtStart + 2], 1);
    expect(bytes[0x9D3C + 255] & 0x80, 0x80);
  });
}

Uint8List _save({required int generalSize, required int magic}) {
  final bytes = Uint8List(0x80000);
  _u32set(bytes, generalSize - 0x14, 2);
  _u32set(bytes, generalSize - 8, magic);
  _u32set(bytes, 0x40000 + generalSize - 0x14, 1);
  _u32set(bytes, 0x40000 + generalSize - 8, magic);
  return bytes;
}

int _u32(List<int> bytes, int offset) => bytes[offset] |
    (bytes[offset + 1] << 8) |
    (bytes[offset + 2] << 16) |
    (bytes[offset + 3] << 24);

void _u32set(Uint8List bytes, int offset, int value) {
  for (var index = 0; index < 4; index++) {
    bytes[offset + index] = (value >> (index * 8)) & 0xFF;
  }
}
