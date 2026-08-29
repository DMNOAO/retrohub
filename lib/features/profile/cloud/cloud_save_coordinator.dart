import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;

import '../auth/google_auth_service.dart';
import 'cloud_save_local_service.dart';
import 'google_drive_save_service.dart';

/// Creates the same RetroHub Cloud backup used by Perfil and uploads it.
///
/// Keeping this outside the UI ensures that manual backups and “Guardar y
/// salir” always use the same ROM identity, manifest and SRAM/RTC files.
class CloudSaveCoordinator {
  final GoogleAuthService authService;
  final CloudSaveLocalService localService;

  CloudSaveCoordinator({
    required this.authService,
    CloudSaveLocalService? localService,
  }) : localService = localService ?? CloudSaveLocalService();

  Future<LocalCloudSaveBackup> uploadGame({
    required String gameId,
    required String gameTitle,
    required String romPath,
    bool requestAuthorizationIfNeeded = true,
  }) async {
    final romFile = File(romPath);
    if (!await romFile.exists()) {
      throw StateError('No se encontró la ROM local de $gameTitle.');
    }

    final digest = await crypto.sha1.bind(romFile.openRead()).first;
    final cloudGameId = digest.toString();
    final backup = await localService.createBackup(
      gameId: gameId,
      romPath: romPath,
      gameTitle: gameTitle,
      romHash: cloudGameId,
    );
    final drive = GoogleDriveSaveService(authService: authService);
    await drive.uploadBackup(
      backup,
      cloudGameId: cloudGameId,
      requestAuthorizationIfNeeded: requestAuthorizationIfNeeded,
    );
    return backup;
  }
}
