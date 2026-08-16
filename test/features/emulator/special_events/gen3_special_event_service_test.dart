import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/features/emulator/special_events/gen3_special_event_service.dart';
import 'package:retrohub/features/pokemon/models/pokemon_game_profile.dart';

void main() {
  const service = Gen3SpecialEventService();

  test('expone solo los eventos compatibles con cada edición', () {
    expect(
      service.eventsFor(PokemonGameVersion.ruby),
      [Gen3SpecialEvent.eonTicket],
    );
    expect(
      service.eventsFor(PokemonGameVersion.emerald),
      [
        Gen3SpecialEvent.eonTicket,
        Gen3SpecialEvent.oldSeaMap,
        Gen3SpecialEvent.auroraTicket,
        Gen3SpecialEvent.mysticTicket,
      ],
    );
    expect(
      service.eventsFor(PokemonGameVersion.fireRed),
      [
        Gen3SpecialEvent.auroraTicket,
        Gen3SpecialEvent.mysticTicket,
      ],
    );
    expect(service.eventsFor(PokemonGameVersion.crystal), isEmpty);
  });

  test('mantiene bloqueado un evento de Esmeralda antes de la Liga', () {
    final save = _gen3Save();
    expect(
      service.inspectBytes(
        save,
        version: PokemonGameVersion.emerald,
        event: Gen3SpecialEvent.oldSeaMap,
      ),
      Gen3SpecialEventStatus.leagueRequired,
    );
  });

  test('activa Mapa Viejo, crea respaldo y conserva el evento', () async {
    final directory = await Directory.systemTemp.createTemp(
      'retrohub-gen3-event-',
    );
    addTearDown(() => directory.delete(recursive: true));

    final save = _gen3Save();
    _writeFlag(save, flagsOffset: 0x1270, flagId: 0x864);
    _setU32(save, 0xAC, 0x12345678);

    final saveFile = File('${directory.path}/emerald.srm');
    await saveFile.writeAsBytes(save);

    expect(
      await service.inspect(
        savePath: saveFile.path,
        version: PokemonGameVersion.emerald,
        event: Gen3SpecialEvent.oldSeaMap,
      ),
      Gen3SpecialEventStatus.available,
    );

    final result = await service.activate(
      savePath: saveFile.path,
      version: PokemonGameVersion.emerald,
      event: Gen3SpecialEvent.oldSeaMap,
    );

    expect(result.status, Gen3SpecialEventStatus.activated);
    expect(result.backupPath, isNotNull);
    expect(await File(result.backupPath!).exists(), isTrue);
    expect(
      await service.inspect(
        savePath: saveFile.path,
        version: PokemonGameVersion.emerald,
        event: Gen3SpecialEvent.oldSeaMap,
      ),
      Gen3SpecialEventStatus.activated,
    );

    final activated = await saveFile.readAsBytes();
    final keyItem = _block1Offset(0x5D8);
    expect(_u16(activated, keyItem), 376);
    expect(_u16(activated, keyItem + 2), 1 ^ 0x5678);
  });
}

Uint8List _gen3Save() {
  final bytes = Uint8List(Gen3SpecialEventService.minimumSaveLength);
  for (var sectionId = 0; sectionId < 14; sectionId++) {
    final base = sectionId * Gen3SpecialEventService.sectorSize;
    _setU16(bytes, base + 0xFF4, sectionId);
    _setU32(bytes, base + 0xFF8, 0x08012025);
    _setU32(bytes, base + 0xFFC, 1);
  }
  return bytes;
}

void _writeFlag(
  Uint8List bytes, {
  required int flagsOffset,
  required int flagId,
}) {
  final location = _block1Offset(flagsOffset + (flagId >> 3));
  bytes[location] |= 1 << (flagId & 7);
}

int _block1Offset(int offset) {
  final chunk = offset ~/ Gen3SpecialEventService.sectorDataSize;
  final sectionId = 1 + chunk;
  return sectionId * Gen3SpecialEventService.sectorSize +
      offset % Gen3SpecialEventService.sectorDataSize;
}

int _u16(List<int> bytes, int offset) =>
    bytes[offset] | (bytes[offset + 1] << 8);

void _setU16(Uint8List bytes, int offset, int value) {
  bytes[offset] = value & 0xFF;
  bytes[offset + 1] = (value >> 8) & 0xFF;
}

void _setU32(Uint8List bytes, int offset, int value) {
  _setU16(bytes, offset, value);
  _setU16(bytes, offset + 2, value >> 16);
}
