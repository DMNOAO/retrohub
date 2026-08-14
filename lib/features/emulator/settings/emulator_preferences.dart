import 'package:shared_preferences/shared_preferences.dart';

enum GameBoyControlLayout { classic, compact }

enum GameBoyControlSize { small, normal, large }

enum EmulatorScreenScale { aspectRatio, fitWidth, stretch }

enum EmulatorScreenFilter { pixel, smooth }

enum EmulatorOrientation { automatic, portrait, landscape }

class EmulatorPreferences {
  static const _layoutKey = 'emulator_gb_control_layout';
  static const _sizeKey = 'emulator_gb_control_size';
  static const _opacityKey = 'emulator_gb_control_opacity';
  static const _vibrationKey = 'emulator_gb_control_vibration';
  static const _swapButtonsKey = 'emulator_gb_swap_ab';
  static const _screenScaleKey = 'emulator_gb_screen_scale';
  static const _screenFilterKey = 'emulator_gb_screen_filter';
  static const _showIdentityKey = 'emulator_gb_show_identity';
  static const _orientationKey = 'emulator_gb_orientation';
  static const _keepAwakeKey = 'emulator_gb_keep_awake';
  static const _pauseInBackgroundKey = 'emulator_gb_pause_in_background';
  static const _autoSaveOnExitKey = 'emulator_gb_auto_save_on_exit';
  static const _autoLoadOnStartKey = 'emulator_gb_auto_load_on_start';
  static const _confirmOverwriteKey = 'emulator_gb_confirm_overwrite';

  final GameBoyControlLayout layout;
  final GameBoyControlSize controlSize;
  final double controlOpacity;
  final bool vibrationEnabled;
  final bool swapAB;
  final EmulatorScreenScale screenScale;
  final EmulatorScreenFilter screenFilter;
  final bool showConsoleIdentity;
  final EmulatorOrientation orientation;
  final bool keepScreenAwake;
  final bool pauseInBackground;
  final bool autoSaveOnExit;
  final bool autoLoadOnStart;
  final bool confirmBeforeOverwrite;

  const EmulatorPreferences({
    this.layout = GameBoyControlLayout.classic,
    this.controlSize = GameBoyControlSize.normal,
    this.controlOpacity = 1,
    this.vibrationEnabled = true,
    this.swapAB = false,
    this.screenScale = EmulatorScreenScale.aspectRatio,
    this.screenFilter = EmulatorScreenFilter.pixel,
    this.showConsoleIdentity = true,
    this.orientation = EmulatorOrientation.automatic,
    this.keepScreenAwake = true,
    this.pauseInBackground = true,
    this.autoSaveOnExit = true,
    this.autoLoadOnStart = false,
    this.confirmBeforeOverwrite = true,
  });

  double get sizeScale => switch (controlSize) {
        GameBoyControlSize.small => .86,
        GameBoyControlSize.normal => 1,
        GameBoyControlSize.large => 1.12,
      };

  EmulatorPreferences copyWith({
    GameBoyControlLayout? layout,
    GameBoyControlSize? controlSize,
    double? controlOpacity,
    bool? vibrationEnabled,
    bool? swapAB,
    EmulatorScreenScale? screenScale,
    EmulatorScreenFilter? screenFilter,
    bool? showConsoleIdentity,
    EmulatorOrientation? orientation,
    bool? keepScreenAwake,
    bool? pauseInBackground,
    bool? autoSaveOnExit,
    bool? autoLoadOnStart,
    bool? confirmBeforeOverwrite,
  }) {
    return EmulatorPreferences(
      layout: layout ?? this.layout,
      controlSize: controlSize ?? this.controlSize,
      controlOpacity: controlOpacity ?? this.controlOpacity,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      swapAB: swapAB ?? this.swapAB,
      screenScale: screenScale ?? this.screenScale,
      screenFilter: screenFilter ?? this.screenFilter,
      showConsoleIdentity: showConsoleIdentity ?? this.showConsoleIdentity,
      orientation: orientation ?? this.orientation,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      pauseInBackground: pauseInBackground ?? this.pauseInBackground,
      autoSaveOnExit: autoSaveOnExit ?? this.autoSaveOnExit,
      autoLoadOnStart: autoLoadOnStart ?? this.autoLoadOnStart,
      confirmBeforeOverwrite:
          confirmBeforeOverwrite ?? this.confirmBeforeOverwrite,
    );
  }

  static Future<EmulatorPreferences> load() async {
    final storage = await SharedPreferences.getInstance();
    return EmulatorPreferences(
      layout: GameBoyControlLayout.values.firstWhere(
        (value) => value.name == storage.getString(_layoutKey),
        orElse: () => GameBoyControlLayout.classic,
      ),
      controlSize: GameBoyControlSize.values.firstWhere(
        (value) => value.name == storage.getString(_sizeKey),
        orElse: () => GameBoyControlSize.normal,
      ),
      controlOpacity: (storage.getDouble(_opacityKey) ?? 1).clamp(.45, 1),
      vibrationEnabled: storage.getBool(_vibrationKey) ?? true,
      swapAB: storage.getBool(_swapButtonsKey) ?? false,
      screenScale: EmulatorScreenScale.values.firstWhere(
        (value) => value.name == storage.getString(_screenScaleKey),
        orElse: () => EmulatorScreenScale.aspectRatio,
      ),
      screenFilter: EmulatorScreenFilter.values.firstWhere(
        (value) => value.name == storage.getString(_screenFilterKey),
        orElse: () => EmulatorScreenFilter.pixel,
      ),
      showConsoleIdentity: storage.getBool(_showIdentityKey) ?? true,
      orientation: EmulatorOrientation.values.firstWhere(
        (value) => value.name == storage.getString(_orientationKey),
        orElse: () => EmulatorOrientation.automatic,
      ),
      keepScreenAwake: storage.getBool(_keepAwakeKey) ?? true,
      pauseInBackground: storage.getBool(_pauseInBackgroundKey) ?? true,
      autoSaveOnExit: storage.getBool(_autoSaveOnExitKey) ?? true,
      autoLoadOnStart: storage.getBool(_autoLoadOnStartKey) ?? false,
      confirmBeforeOverwrite: storage.getBool(_confirmOverwriteKey) ?? true,
    );
  }

  Future<void> save() async {
    final storage = await SharedPreferences.getInstance();
    await Future.wait([
      storage.setString(_layoutKey, layout.name),
      storage.setString(_sizeKey, controlSize.name),
      storage.setDouble(_opacityKey, controlOpacity),
      storage.setBool(_vibrationKey, vibrationEnabled),
      storage.setBool(_swapButtonsKey, swapAB),
      storage.setString(_screenScaleKey, screenScale.name),
      storage.setString(_screenFilterKey, screenFilter.name),
      storage.setBool(_showIdentityKey, showConsoleIdentity),
      storage.setString(_orientationKey, orientation.name),
      storage.setBool(_keepAwakeKey, keepScreenAwake),
      storage.setBool(_pauseInBackgroundKey, pauseInBackground),
      storage.setBool(_autoSaveOnExitKey, autoSaveOnExit),
      storage.setBool(_autoLoadOnStartKey, autoLoadOnStart),
      storage.setBool(_confirmOverwriteKey, confirmBeforeOverwrite),
    ]);
  }

  static Future<void> reset() => const EmulatorPreferences().save();
}
