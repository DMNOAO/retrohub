import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/features/emulator/special_events/gen1_mew_event_service.dart';
import 'package:retrohub/features/pokemon/models/pokemon_game_profile.dart';

void main() {
  const service = Gen1MewEventService();

  for (final version in const <PokemonGameVersion>[
    PokemonGameVersion.redBlue,
    PokemonGameVersion.yellow,
  ]) {
    test('delivers Mew and repairs checksum for $version', () async {
      final directory = await Directory.systemTemp.createTemp('retrohub-mew-');
      addTearDown(() => directory.delete(recursive: true));
      final save = File('${directory.path}/game.srm');
      await save.writeAsBytes(Uint8List(0x8000));

      final result = await service.deliver(
        savePath: save.path,
        version: version,
      );
      final bytes = await save.readAsBytes();

      expect(result.status, Gen1MewEventStatus.delivered);
      expect(await File(result.backupPath!).exists(), isTrue);
      expect(bytes[0x2F2C], 1);
      expect(bytes[0x2F2D], 0x15);
      expect(bytes[0x2F34], 0x15);
      expect(_sum(bytes, 0x2598, 0x3524), 0xFF);
    });
  }

  test('does not modify a full party', () async {
    final directory = await Directory.systemTemp.createTemp('retrohub-mew-');
    addTearDown(() => directory.delete(recursive: true));
    final save = File('${directory.path}/game.srm');
    await save.writeAsBytes(Uint8List(0x8000)..[0x2F2C] = 6);

    final result = await service.deliver(
      savePath: save.path,
      version: PokemonGameVersion.yellow,
    );

    expect(result.status, Gen1MewEventStatus.partyFull);
  });
}

int _sum(List<int> bytes, int start, int end) {
  var sum = 0;
  for (var index = start; index < end; index++) {
    sum = (sum + bytes[index]) & 0xFF;
  }
  return sum;
}
