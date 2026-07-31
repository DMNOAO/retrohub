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

class CoreLoader {
  static const String _windowsRelativeCorePath =
      'cores/sameboy/sameboy_libretro.dll';
  static const String _windowsBridgeFileName = 'libretro_bridge.dll';

  // Android empaqueta ambas bibliotecas dentro de lib/<ABI>/.
  // El cargador dinámico de Android puede resolverlas por su nombre SONAME.
  static const String _androidCoreName = 'libsameboy_libretro.so';
  static const String _androidBridgeName = 'libretro_bridge.so';

  static List<String> get _coreCandidatePaths {
    if (Platform.isAndroid) {
      return const <String>[_androidCoreName];
    }

    final String current = Directory.current.path;
    return <String>[
      _windowsRelativeCorePath,
      '$current/$_windowsRelativeCorePath',
      '$current/../$_windowsRelativeCorePath',
      '$current/../../$_windowsRelativeCorePath',
      '$current/../../../$_windowsRelativeCorePath',
      'C:/Users/dark_/OneDrive/Escritorio/retrohub/'
          '$_windowsRelativeCorePath',
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
      'C:/Users/dark_/OneDrive/Escritorio/retrohub/'
          'build/windows/x64/runner/Debug/$_windowsBridgeFileName',
      'C:/Users/dark_/OneDrive/Escritorio/retrohub/'
          'build/windows/x64/runner/Release/$_windowsBridgeFileName',
    ];
  }

  static String? findSameBoyPath() {
    if (Platform.isAndroid) {
      return _androidCoreName;
    }
    return _findExistingFile(_coreCandidatePaths);
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

  static String get debugCoreSearchPaths => _coreCandidatePaths.join('\n');
  static String get debugBridgeSearchPaths => _bridgeCandidatePaths.join('\n');
  static String get debugSearchPaths => debugCoreSearchPaths;

  static bool sameBoyExists() {
    if (Platform.isAndroid) {
      try {
        final DynamicLibrary library = DynamicLibrary.open(_androidCoreName);
        library.lookup<NativeFunction<Void Function()>>('retro_init');
        return true;
      } on Object catch (error) {
        print('SameBoy Android no disponible: $error');
        return false;
      }
    }

    return findSameBoyPath() != null;
  }

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
