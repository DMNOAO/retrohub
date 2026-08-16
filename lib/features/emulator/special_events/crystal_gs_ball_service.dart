import 'dart:io';
import 'dart:typed_data';

enum CrystalGsBallStatus {
  noSave,
  incompatibleSave,
  leagueRequired,
  available,
  activated,
}

class CrystalGsBallActivationResult {
  final CrystalGsBallStatus status;
  final String? backupPath;

  const CrystalGsBallActivationResult({
    required this.status,
    this.backupPath,
  });

  bool get succeeded => status == CrystalGsBallStatus.activated;
}

/// Restores the official GS Ball availability flag used by international
/// Pokémon Crystal saves. This deliberately does not grant an item or alter
/// event progression: Crystal's own Goldenrod, Kurt and Ilex Forest scripts
/// remain responsible for the complete event.
class CrystalGsBallService {
  static const int minimumSaveLength = 0x8000;
  static const int hallOfFameCountOffset = 0x32C0;
  static const int gsBallFlagOffset = 0x3E3C;
  static const int gsBallFlagBackupOffset = 0x3E44;
  static const int gsBallAvailableValue = 0x0B;

  const CrystalGsBallService();

  Future<CrystalGsBallStatus> inspect(String savePath) async {
    final File save = File(savePath);
    if (!await save.exists()) return CrystalGsBallStatus.noSave;

    final Uint8List bytes = await save.readAsBytes();
    return inspectBytes(bytes);
  }

  CrystalGsBallStatus inspectBytes(List<int> bytes) {
    if (bytes.length < minimumSaveLength) {
      return CrystalGsBallStatus.incompatibleSave;
    }

    if (_isActivated(bytes)) return CrystalGsBallStatus.activated;

    final int hallOfFameCount = bytes[hallOfFameCountOffset];
    if (hallOfFameCount == 0 || hallOfFameCount == 0xFF) {
      return CrystalGsBallStatus.leagueRequired;
    }

    return CrystalGsBallStatus.available;
  }

  Future<CrystalGsBallActivationResult> activate(String savePath) async {
    final File save = File(savePath);
    final CrystalGsBallStatus status = await inspect(savePath);
    if (status != CrystalGsBallStatus.available) {
      return CrystalGsBallActivationResult(status: status);
    }

    final Uint8List bytes = await save.readAsBytes();
    final String backupPath = await _availableBackupPath(savePath);
    await save.copy(backupPath);

    bytes[gsBallFlagOffset] = gsBallAvailableValue;
    bytes[gsBallFlagBackupOffset] = gsBallAvailableValue;

    try {
      await save.writeAsBytes(bytes, flush: true);
    } catch (_) {
      await File(backupPath).copy(savePath);
      rethrow;
    }

    return CrystalGsBallActivationResult(
      status: CrystalGsBallStatus.activated,
      backupPath: backupPath,
    );
  }

  bool _isActivated(List<int> bytes) {
    return bytes[gsBallFlagOffset] == gsBallAvailableValue &&
        bytes[gsBallFlagBackupOffset] == gsBallAvailableValue;
  }

  Future<String> _availableBackupPath(String savePath) async {
    final String base = '$savePath.before-gs-ball.bak';
    if (!await File(base).exists()) return base;

    var suffix = 2;
    while (await File('$base.$suffix').exists()) {
      suffix++;
    }
    return '$base.$suffix';
  }
}
