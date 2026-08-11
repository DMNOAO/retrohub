import 'dart:ffi';
import 'dart:io';

class GamePersistencePaths {
  final String gameDirectory;
  final String sramDirectory;
  final String statesDirectory;
  final String screenshotsDirectory;
  final String sramFile;
  final String stateFile;

  const GamePersistencePaths({
    required this.gameDirectory,
    required this.sramDirectory,
    required this.statesDirectory,
    required this.screenshotsDirectory,
    required this.sramFile,
    required this.stateFile,
  });
}

class EmulationCore {
  final String id;
  final String displayName;
  final String androidLibraryName;
  final String windowsRelativePath;

  const EmulationCore({
    required this.id,
    required this.displayName,
    required this.androidLibraryName,
    required this.windowsRelativePath,
  });
}

class CoreLoader {
  static const EmulationCore sameBoy = EmulationCore(
    id: 'sameboy',
    displayName: 'SameBoy',
    androidLibraryName: 'libsameboy_libretro.so',
    windowsRelativePath: 'cores/sameboy/sameboy_libretro.dll',
  );

  static const EmulationCore mGba = EmulationCore(
    id: 'mgba',
    displayName: 'mGBA',
    androidLibraryName: 'libmgba_libretro.so',
    windowsRelativePath: 'cores/mgba/mgba_libretro.dll',
  );

  static const EmulationCore snes = EmulationCore(
    id: 'snes',
    displayName: 'SNES (Supafaust / Snes9x)',
    androidLibraryName: 'libsupafaust_libretro.so',
    windowsRelativePath: 'cores/snes9x/snes9x_libretro.dll',
  );

  static const String _windowsBridgeFileName = 'libretro_bridge.dll';
  static const String _androidBridgeName = 'libretro_bridge.so';

  static bool isGbaRom(String romPath) {
    final String normalized = romPath.trim().toLowerCase();
    return normalized.endsWith('.gba');
  }

  static bool isSnesRom(String romPath) {
    final String normalized = romPath.trim().toLowerCase();
    return normalized.endsWith('.smc') || normalized.endsWith('.sfc');
  }

  static bool isGameBoyRom(String romPath) {
    final String normalized = romPath.trim().toLowerCase();
    return normalized.endsWith('.gb') || normalized.endsWith('.gbc');
  }

  static EmulationCore coreForRom(String romPath) {
    if (isSnesRom(romPath)) return snes;
    if (isGbaRom(romPath)) return mGba;
    return sameBoy;
  }

  static List<String> _coreCandidatePaths(EmulationCore core) {
    if (Platform.isAndroid) {
      return <String>[core.androidLibraryName];
    }

    final String current = Directory.current.path;
    final String relativePath = core.windowsRelativePath;
    return <String>[
      relativePath,
      '$current/$relativePath',
      '$current/../$relativePath',
      '$current/../../$relativePath',
      '$current/../../../$relativePath',
    ];
  }

  static List<String> get _bridgeCandidatePaths {
    if (Platform.isAndroid) {
      return const <String>[_androidBridgeName];
    }

    final String current = Directory.current.path;
    return <String>[
      _windowsBridgeFileName,
      '$current/$_windowsBridgeFileName',
      '$current/build/windows/x64/runner/Debug/$_windowsBridgeFileName',
      '$current/build/windows/x64/runner/Release/$_windowsBridgeFileName',
      '$current/../$_windowsBridgeFileName',
      '$current/../../$_windowsBridgeFileName',
      '$current/../../../$_windowsBridgeFileName',
    ];
  }

  static String? findCorePath(String romPath) {
    final EmulationCore core = coreForRom(romPath);
    if (Platform.isAndroid) {
      return core.androidLibraryName;
    }
    return _findExistingFile(_coreCandidatePaths(core));
  }

  // Se conserva para los puntos antiguos que todavía consultan SameBoy.
  static String? findSameBoyPath() {
    if (Platform.isAndroid) {
      return sameBoy.androidLibraryName;
    }
    return _findExistingFile(_coreCandidatePaths(sameBoy));
  }

  static String? findBridgePath() {
    if (Platform.isAndroid) {
      return _androidBridgeName;
    }
    return _findExistingFile(_bridgeCandidatePaths);
  }

  static String? _findExistingFile(List<String> candidates) {
    for (final String path in candidates) {
      final File file = File(path);
      if (file.existsSync()) {
        return file.absolute.path;
      }
    }
    return null;
  }

  static String debugCoreSearchPathsForRom(String romPath) {
    return _coreCandidatePaths(coreForRom(romPath)).join('\n');
  }

  static String get debugCoreSearchPaths =>
      _coreCandidatePaths(sameBoy).join('\n');
  static String get debugBridgeSearchPaths => _bridgeCandidatePaths.join('\n');
  static String get debugSearchPaths => debugCoreSearchPaths;

  static bool coreExistsForRom(String romPath) {
    final EmulationCore core = coreForRom(romPath);
    if (Platform.isAndroid) {
      try {
        final DynamicLibrary library =
            DynamicLibrary.open(core.androidLibraryName);
        library.lookup<NativeFunction<Void Function()>>('retro_init');
        return true;
      } on Object catch (error) {
        print('${core.displayName} Android no disponible: $error');
        return false;
      }
    }

    return findCorePath(romPath) != null;
  }

  static bool sameBoyExists() => coreExistsForRom('game.gb');

  static bool bridgeExists() {
    try {
      final DynamicLibrary? library = loadBridge();
      return library != null;
    } on Object {
      return false;
    }
  }

  static DynamicLibrary? loadBridge() {
    final String? path = findBridgePath();
    if (path == null) {
      return null;
    }

    try {
      return DynamicLibrary.open(path);
    } on Object catch (error) {
      print('No se pudo abrir el bridge nativo ($path): $error');
      return null;
    }
  }

  static GamePersistencePaths persistencePaths({
    required String gameId,
    required String romPath,
  }) {
    final String safeGameId = _sanitizeGameKey(
      gameId.trim().isNotEmpty ? gameId : _fileNameWithoutExtension(romPath),
    );

    final Directory root = Directory(
      '${_documentsDirectory.path}${Platform.pathSeparator}'
      'RetroHub${Platform.pathSeparator}saves',
    );
    final Directory gameDirectory = Directory(
      '${root.path}${Platform.pathSeparator}$safeGameId',
    );
    final Directory sramDirectory = Directory(
      '${gameDirectory.path}${Platform.pathSeparator}sram',
    );
    final Directory statesDirectory = Directory(
      '${gameDirectory.path}${Platform.pathSeparator}states',
    );
    final Directory screenshotsDirectory = Directory(
      '${gameDirectory.path}${Platform.pathSeparator}screenshots',
    );

    return GamePersistencePaths(
      gameDirectory: gameDirectory.path,
      sramDirectory: sramDirectory.path,
      statesDirectory: statesDirectory.path,
      screenshotsDirectory: screenshotsDirectory.path,
      sramFile: '${sramDirectory.path}${Platform.pathSeparator}game.srm',
      stateFile: '${statesDirectory.path}${Platform.pathSeparator}slot_0.state',
    );
  }

  static GamePersistencePaths ensurePersistenceDirectories({
    required String gameId,
    required String romPath,
  }) {
    final GamePersistencePaths paths = persistencePaths(
      gameId: gameId,
      romPath: romPath,
    );

    Directory(paths.sramDirectory).createSync(recursive: true);
    Directory(paths.statesDirectory).createSync(recursive: true);
    Directory(paths.screenshotsDirectory).createSync(recursive: true);
    return paths;
  }

  /// Carpeta raíz persistente de RetroHub (misma que usan los saves).
  /// Público para que otros servicios (p. ej. importación de ROMs) guarden
  /// sus archivos en la misma ubicación estable entre ejecuciones.
  static Directory get documentsDirectory => _documentsDirectory;

  static Directory get _documentsDirectory {
    if (Platform.isAndroid) {
      // Directory.systemTemp suele ser <sandbox>/cache. Su carpeta hermana
      // "files" es persistente entre ejecuciones y no exige permisos externos.
      final Directory appRoot = Directory.systemTemp.parent;
      return Directory(
        '${appRoot.path}${Platform.pathSeparator}files',
      )..createSync(recursive: true);
    }

    if (Platform.isWindows) {
      final String? userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null && userProfile.trim().isNotEmpty) {
        return Directory(
          '$userProfile${Platform.pathSeparator}Documents',
        );
      }
    }

    final String? home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home != null && home.trim().isNotEmpty) {
      return Directory('$home${Platform.pathSeparator}Documents');
    }
    return Directory.current;
  }

  static String _sanitizeGameKey(String value) {
    final String normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return normalized.isEmpty ? 'game' : normalized;
  }

  static String _fileNameWithoutExtension(String path) {
    final String normalized = path.replaceAll('\\', '/');
    final String fileName = normalized.split('/').last;
    final int dotIndex = fileName.lastIndexOf('.');
    return dotIndex <= 0 ? fileName : fileName.substring(0, dotIndex);
  }
}
