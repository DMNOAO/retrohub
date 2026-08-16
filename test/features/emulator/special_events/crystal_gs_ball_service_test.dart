import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:retrohub/features/emulator/special_events/crystal_gs_ball_service.dart';

void main() {
  const service = CrystalGsBallService();

  test('keeps the event locked before the Hall of Fame', () {
    final bytes = Uint8List(CrystalGsBallService.minimumSaveLength);
    expect(
      service.inspectBytes(bytes),
      CrystalGsBallStatus.leagueRequired,
    );
  });

  test('makes the event available after the Hall of Fame', () {
    final bytes = Uint8List(CrystalGsBallService.minimumSaveLength);
    bytes[CrystalGsBallService.hallOfFameCountOffset] = 1;
    expect(service.inspectBytes(bytes), CrystalGsBallStatus.available);
  });

  test('allows a debug activation before the Hall of Fame', () async {
    final directory = await Directory.systemTemp.createTemp(
      'retrohub_gs_ball_debug_',
    );
    addTearDown(() => directory.delete(recursive: true));

    final save = File('${directory.path}/crystal.srm');
    await save.writeAsBytes(
      Uint8List(CrystalGsBallService.minimumSaveLength),
    );

    final result = await service.activate(
      save.path,
      allowBeforeLeague: true,
    );

    expect(result.succeeded, isTrue);
    expect(await service.inspect(save.path), CrystalGsBallStatus.activated);
  });

  test('activates both GS Ball flags and creates a backup', () async {
    final directory = await Directory.systemTemp.createTemp('retrohub_gs_ball_');
    addTearDown(() => directory.delete(recursive: true));

    final save = File('${directory.path}/crystal.srm');
    final bytes = Uint8List(CrystalGsBallService.minimumSaveLength);
    bytes[CrystalGsBallService.hallOfFameCountOffset] = 1;
    await save.writeAsBytes(bytes);

    final result = await service.activate(save.path);
    final updated = await save.readAsBytes();

    expect(result.succeeded, isTrue);
    expect(File(result.backupPath!).existsSync(), isTrue);
    expect(
      updated[CrystalGsBallService.gsBallFlagOffset],
      CrystalGsBallService.gsBallAvailableValue,
    );
    expect(
      updated[CrystalGsBallService.gsBallFlagBackupOffset],
      CrystalGsBallService.gsBallAvailableValue,
    );
  });
}
