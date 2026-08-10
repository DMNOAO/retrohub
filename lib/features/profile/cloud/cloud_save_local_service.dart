import 'dart:io';

import '../../../core/emulation/core_loader.dart';
import 'cloud_save_manifest.dart';

class LocalCloudSaveBackup {
  final Directory directory;
  final CloudSaveManifest manifest;

  const LocalCloudSaveBackup({
    required this.directory,
    required this.manifest,
  });

  File get manifestFile => File(
        '${directory.path}${Platform.pathSeparator}manifest.json',
      );

  File get sramFile => File(
        '${directory.path}${Platform.pathSeparator}game.srm',
      );

  File get rtcFile => File(
        '${directory.path}${Platform.pathSeparator}game.rtc',
      );
}

class CloudSaveRestoreResult {
  final CloudSaveManifest manifest;
  final Directory? previousSaveBackup;

  const CloudSaveRestoreResult({
    required this.manifest,
    required this.previousSaveBackup,
  });
}

class CloudSaveLocalService {
  static const String _manifestFileName = 'manifest.json';
  static const String _sramFileName = 'game.srm';
  static const String _rtcFileName = 'game.rtc';

  Future<LocalCloudSaveBackup> createBackup({
    required String gameId,
    required String romPath,
    required String gameTitle,
    String? romHash,
    Directory? destinationRoot,
  }) async {
    final String normalizedGameId = gameId.trim();
    if (normalizedGameId.isEmpty) {
      throw ArgumentError.value(gameId, 'gameId', 'No puede estar vacío.');
    }

    final String normalizedHash =
        (romHash == null || romHash.trim().isEmpty)
            ? normalizedGameId
            : romHash.trim();

    final GamePersistencePaths paths = CoreLoader.persistencePaths(
      gameId: normalizedGameId,
      romPath: romPath,
    );

    final File localSram = File(paths.sramFile);
    if (!await localSram.exists()) {
      throw StateError(
        'No existe una SRAM para respaldar: ${localSram.path}',
      );
    }

    final int sramSize = await localSram.length();
    if (sramSize <= 0) {
      throw StateError('La SRAM local está vacía.');
    }

    final File localRtc = File(_rtcPathFromSram(paths.sramFile));
    final bool hasRtc = await localRtc.exists();
    final int? rtcSize = hasRtc ? await localRtc.length() : null;

    if (hasRtc && (rtcSize == null || rtcSize <= 0)) {
      throw StateError('El archivo RTC local está vacío.');
    }

    final DateTime now = DateTime.now().toUtc();
    final CloudSaveManifest manifest = CloudSaveManifest(
      formatVersion: CloudSaveManifest.currentFormatVersion,
      gameId: normalizedGameId,
      gameTitle: gameTitle.trim().isEmpty ? normalizedGameId : gameTitle.trim(),
      romHash: normalizedHash,
      createdAtUtc: now,
      sourcePlatform: _platformName(),
      sramSize: sramSize,
      rtcSize: rtcSize,
    );

    final Directory root = destinationRoot ?? _defaultBackupRoot();
    await root.create(recursive: true);

    final Directory backupDirectory = Directory(
      '${root.path}${Platform.pathSeparator}'
      '${_safeDirectoryName(normalizedGameId)}_${_timestampForPath(now)}',
    );

    if (await backupDirectory.exists()) {
      await backupDirectory.delete(recursive: true);
    }
    await backupDirectory.create(recursive: true);

    try {
      await localSram.copy(
        '${backupDirectory.path}${Platform.pathSeparator}$_sramFileName',
      );

      if (hasRtc) {
        await localRtc.copy(
          '${backupDirectory.path}${Platform.pathSeparator}$_rtcFileName',
        );
      }

      final File manifestFile = File(
        '${backupDirectory.path}${Platform.pathSeparator}$_manifestFileName',
      );
      await manifestFile.writeAsString(
        manifest.toJsonString(),
        flush: true,
      );

      final LocalCloudSaveBackup backup = LocalCloudSaveBackup(
        directory: backupDirectory,
        manifest: manifest,
      );
      await validateBackup(
        backupDirectory,
        expectedGameId: normalizedGameId,
        expectedRomHash: normalizedHash,
      );
      return backup;
    } catch (_) {
      if (await backupDirectory.exists()) {
        await backupDirectory.delete(recursive: true);
      }
      rethrow;
    }
  }

  Future<CloudSaveManifest> validateBackup(
    Directory backupDirectory, {
    String? expectedGameId,
    String? expectedRomHash,
  }) async {
    if (!await backupDirectory.exists()) {
      throw StateError(
        'No existe el directorio de respaldo: ${backupDirectory.path}',
      );
    }

    final File manifestFile = File(
      '${backupDirectory.path}${Platform.pathSeparator}$_manifestFileName',
    );
    final File sramFile = File(
      '${backupDirectory.path}${Platform.pathSeparator}$_sramFileName',
    );
    final File rtcFile = File(
      '${backupDirectory.path}${Platform.pathSeparator}$_rtcFileName',
    );

    if (!await manifestFile.exists()) {
      throw StateError('El respaldo no contiene $_manifestFileName.');
    }
    if (!await sramFile.exists()) {
      throw StateError('El respaldo no contiene $_sramFileName.');
    }

    final CloudSaveManifest manifest = CloudSaveManifest.fromJsonString(
      await manifestFile.readAsString(),
    );

    if (expectedGameId != null &&
        expectedGameId.trim().isNotEmpty &&
        manifest.gameId != expectedGameId.trim()) {
      throw StateError(
        'El respaldo pertenece a otro juego '
        '(${manifest.gameId} != ${expectedGameId.trim()}).',
      );
    }

    if (expectedRomHash != null &&
        expectedRomHash.trim().isNotEmpty &&
        manifest.romHash != expectedRomHash.trim()) {
      throw StateError(
        'El respaldo pertenece a otra ROM '
        '(${manifest.romHash} != ${expectedRomHash.trim()}).',
      );
    }

    final int actualSramSize = await sramFile.length();
    if (actualSramSize != manifest.sramSize || actualSramSize <= 0) {
      throw StateError(
        'La SRAM del respaldo no coincide con el manifest.',
      );
    }

    if (manifest.hasRtc) {
      if (!await rtcFile.exists()) {
        throw StateError(
          'El manifest declara RTC pero $_rtcFileName no existe.',
        );
      }
      final int actualRtcSize = await rtcFile.length();
      if (actualRtcSize != manifest.rtcSize || actualRtcSize <= 0) {
        throw StateError(
          'El RTC del respaldo no coincide con el manifest.',
        );
      }
    } else if (await rtcFile.exists()) {
      throw StateError(
        'El respaldo contiene RTC pero el manifest no lo declara.',
      );
    }

    return manifest;
  }

  Future<CloudSaveRestoreResult> restoreBackup({
    required Directory backupDirectory,
    required String gameId,
    required String romPath,
    String? romHash,
    bool preserveCurrentSave = true,
  }) async {
    final String normalizedGameId = gameId.trim();
    if (normalizedGameId.isEmpty) {
      throw ArgumentError.value(gameId, 'gameId', 'No puede estar vacío.');
    }

    final String normalizedHash =
        (romHash == null || romHash.trim().isEmpty)
            ? normalizedGameId
            : romHash.trim();

    // En una restauración entre dispositivos, gameId es local y puede
    // ser distinto. La identidad portable del juego es el hash de la ROM.
    final CloudSaveManifest manifest = await validateBackup(
      backupDirectory,
      expectedRomHash: normalizedHash,
    );

    final GamePersistencePaths paths = CoreLoader.ensurePersistenceDirectories(
      gameId: normalizedGameId,
      romPath: romPath,
    );

    final File targetSram = File(paths.sramFile);
    final File targetRtc = File(_rtcPathFromSram(paths.sramFile));

    Directory? previousSaveBackup;
    if (preserveCurrentSave &&
        (await targetSram.exists() || await targetRtc.exists())) {
      previousSaveBackup = await _backupCurrentFiles(
        gameId: normalizedGameId,
        sram: targetSram,
        rtc: targetRtc,
      );
    }

    final File sourceSram = File(
      '${backupDirectory.path}${Platform.pathSeparator}$_sramFileName',
    );
    final File sourceRtc = File(
      '${backupDirectory.path}${Platform.pathSeparator}$_rtcFileName',
    );

    final File stagedSram = File('${targetSram.path}.restore_tmp');
    final File stagedRtc = File('${targetRtc.path}.restore_tmp');

    try {
      if (await stagedSram.exists()) {
        await stagedSram.delete();
      }
      if (await stagedRtc.exists()) {
        await stagedRtc.delete();
      }

      await sourceSram.copy(stagedSram.path);
      if (await stagedSram.length() != manifest.sramSize) {
        throw StateError('La SRAM restaurada no superó la validación.');
      }

      if (manifest.hasRtc) {
        await sourceRtc.copy(stagedRtc.path);
        if (await stagedRtc.length() != manifest.rtcSize) {
          throw StateError('El RTC restaurado no superó la validación.');
        }
      }

      await _replaceFile(stagedSram, targetSram);

      if (manifest.hasRtc) {
        await _replaceFile(stagedRtc, targetRtc);
      } else if (await targetRtc.exists()) {
        // Evita conservar un RTC antiguo que no pertenece al respaldo.
        await targetRtc.delete();
      }

      return CloudSaveRestoreResult(
        manifest: manifest,
        previousSaveBackup: previousSaveBackup,
      );
    } catch (_) {
      if (await stagedSram.exists()) {
        await stagedSram.delete();
      }
      if (await stagedRtc.exists()) {
        await stagedRtc.delete();
      }
      rethrow;
    }
  }

  Directory _defaultBackupRoot() {
    return Directory(
      '${CoreLoader.documentsDirectory.path}${Platform.pathSeparator}'
      'RetroHub${Platform.pathSeparator}cloud_staging',
    );
  }

  Future<Directory> _backupCurrentFiles({
    required String gameId,
    required File sram,
    required File rtc,
  }) async {
    final DateTime now = DateTime.now().toUtc();
    final Directory directory = Directory(
      '${CoreLoader.documentsDirectory.path}${Platform.pathSeparator}'
      'RetroHub${Platform.pathSeparator}restore_backups'
      '${Platform.pathSeparator}${_safeDirectoryName(gameId)}'
      '${Platform.pathSeparator}${_timestampForPath(now)}',
    );
    await directory.create(recursive: true);

    if (await sram.exists()) {
      await sram.copy(
        '${directory.path}${Platform.pathSeparator}$_sramFileName',
      );
    }
    if (await rtc.exists()) {
      await rtc.copy(
        '${directory.path}${Platform.pathSeparator}$_rtcFileName',
      );
    }

    return directory;
  }

  Future<void> _replaceFile(File staged, File target) async {
    if (await target.exists()) {
      await target.delete();
    }
    await staged.rename(target.path);
  }

  String _rtcPathFromSram(String sramPath) {
    if (sramPath.toLowerCase().endsWith('.srm')) {
      return '${sramPath.substring(0, sramPath.length - 4)}.rtc';
    }
    return '$sramPath.rtc';
  }

  String _platformName() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    if (Platform.isMacOS) return 'macos';
    return Platform.operatingSystem;
  }

  String _safeDirectoryName(String value) {
    final String safe = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return safe.isEmpty ? 'game' : safe;
  }

  String _timestampForPath(DateTime value) {
    return value
        .toUtc()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
  }
}
