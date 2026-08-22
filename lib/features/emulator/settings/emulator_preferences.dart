import 'package:shared_preferences/shared_preferences.dart';

enum GameBoyControlLayout { classic, compact }

enum GameBoyControlSize { small, normal, large }

enum DirectionalControlType { dPad, joystick }

enum EmulatorScreenScale { aspectRatio, fitWidth, stretch }

enum EmulatorScreenFilter { pixel, smooth }

enum EmulatorOrientation { automatic, portrait, landscape }

enum SnesButtonColorStyle { violet, multicolor, monochrome, custom }

class EmulatorPreferences {
  static const _layoutKey = 'emulator_gb_control_layout';
  static const _sizeKey = 'emulator_gb_control_size';
  static const _opacityKey = 'emulator_gb_control_opacity';
  static const _vibrationKey = 'emulator_gb_control_vibration';
  static const _swapButtonsKey = 'emulator_gb_swap_ab';
  static const _directionalControlKey = 'emulator_directional_control';
  static const _screenScaleKey = 'emulator_gb_screen_scale';
  static const _screenFilterKey = 'emulator_gb_screen_filter';
  static const _showIdentityKey = 'emulator_gb_show_identity';
  static const _orientationKey = 'emulator_gb_orientation';
  static const _keepAwakeKey = 'emulator_gb_keep_awake';
  static const _pauseInBackgroundKey = 'emulator_gb_pause_in_background';
  static const _autoSaveOnExitKey = 'emulator_gb_auto_save_on_exit';
  static const _autoLoadOnStartKey = 'emulator_gb_auto_load_on_start';
  static const _confirmOverwriteKey = 'emulator_gb_confirm_overwrite';
  static const _snesFullscreenKey = 'emulator_snes_fullscreen';
  static const _gbaFullscreenKey = 'emulator_gba_fullscreen';
  static const _snesButtonColorStyleKey = 'emulator_snes_button_color_style';
  static const _snesButtonAColorKey = 'emulator_snes_button_a_color';
  static const _snesButtonBColorKey = 'emulator_snes_button_b_color';
  static const _snesButtonXColorKey = 'emulator_snes_button_x_color';
  static const _snesButtonYColorKey = 'emulator_snes_button_y_color';

  final GameBoyControlLayout layout;
  final GameBoyControlSize controlSize;
  final double controlOpacity;
  final bool vibrationEnabled;
  final bool swapAB;
  final DirectionalControlType directionalControl;
  final EmulatorScreenScale screenScale;
  final EmulatorScreenFilter screenFilter;
  final bool showConsoleIdentity;
  final EmulatorOrientation orientation;
  final bool keepScreenAwake;
  final bool pauseInBackground;
  final bool autoSaveOnExit;
  final bool autoLoadOnStart;
  final bool confirmBeforeOverwrite;
  final bool snesFullscreen;
  final bool gbaFullscreen;
  final SnesButtonColorStyle snesButtonColorStyle;
  final int snesButtonAColor;
  final int snesButtonBColor;
  final int snesButtonXColor;
  final int snesButtonYColor;

  const EmulatorPreferences({
    this.layout = GameBoyControlLayout.classic,
    this.controlSize = GameBoyControlSize.normal,
    this.controlOpacity = 1,
    this.vibrationEnabled = true,
    this.swapAB = false,
    this.directionalControl = DirectionalControlType.dPad,
    this.screenScale = EmulatorScreenScale.aspectRatio,
    this.screenFilter = EmulatorScreenFilter.pixel,
    this.showConsoleIdentity = true,
    this.orientation = EmulatorOrientation.automatic,
    this.keepScreenAwake = true,
    this.pauseInBackground = true,
    this.autoSaveOnExit = true,
    this.autoLoadOnStart = false,
    this.confirmBeforeOverwrite = true,
    this.snesFullscreen = false,
    this.gbaFullscreen = false,
    this.snesButtonColorStyle = SnesButtonColorStyle.violet,
    this.snesButtonAColor = 0xFF5E4B8B,
    this.snesButtonBColor = 0xFF8173AE,
    this.snesButtonXColor = 0xFF8173AE,
    this.snesButtonYColor = 0xFF5E4B8B,
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
    DirectionalControlType? directionalControl,
    EmulatorScreenScale? screenScale,
    EmulatorScreenFilter? screenFilter,
    bool? showConsoleIdentity,
    EmulatorOrientation? orientation,
    bool? keepScreenAwake,
    bool? pauseInBackground,
    bool? autoSaveOnExit,
    bool? autoLoadOnStart,
    bool? confirmBeforeOverwrite,
    bool? snesFullscreen,
    bool? gbaFullscreen,
    SnesButtonColorStyle? snesButtonColorStyle,
    int? snesButtonAColor,
    int? snesButtonBColor,
    int? snesButtonXColor,
    int? snesButtonYColor,
  }) {
    return EmulatorPreferences(
      layout: layout ?? this.layout,
      controlSize: controlSize ?? this.controlSize,
      controlOpacity: controlOpacity ?? this.controlOpacity,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      swapAB: swapAB ?? this.swapAB,
      directionalControl: directionalControl ?? this.directionalControl,
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
      snesFullscreen: snesFullscreen ?? this.snesFullscreen,
      gbaFullscreen: gbaFullscreen ?? this.gbaFullscreen,
      snesButtonColorStyle:
          snesButtonColorStyle ?? this.snesButtonColorStyle,
      snesButtonAColor: snesButtonAColor ?? this.snesButtonAColor,
      snesButtonBColor: snesButtonBColor ?? this.snesButtonBColor,
      snesButtonXColor: snesButtonXColor ?? this.snesButtonXColor,
      snesButtonYColor: snesButtonYColor ?? this.snesButtonYColor,
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
      directionalControl: DirectionalControlType.values.firstWhere(
        (value) => value.name == storage.getString(_directionalControlKey),
        orElse: () => DirectionalControlType.dPad,
      ),
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
      snesFullscreen: storage.getBool(_snesFullscreenKey) ?? false,
      gbaFullscreen: storage.getBool(_gbaFullscreenKey) ?? false,
      snesButtonColorStyle: SnesButtonColorStyle.values.firstWhere(
        (value) =>
            value.name == storage.getString(_snesButtonColorStyleKey),
        orElse: () => SnesButtonColorStyle.violet,
      ),
      snesButtonAColor:
          storage.getInt(_snesButtonAColorKey) ?? 0xFF5E4B8B,
      snesButtonBColor:
          storage.getInt(_snesButtonBColorKey) ?? 0xFF8173AE,
      snesButtonXColor:
          storage.getInt(_snesButtonXColorKey) ?? 0xFF8173AE,
      snesButtonYColor:
          storage.getInt(_snesButtonYColorKey) ?? 0xFF5E4B8B,
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
      storage.setString(_directionalControlKey, directionalControl.name),
      storage.setString(_screenScaleKey, screenScale.name),
      storage.setString(_screenFilterKey, screenFilter.name),
      storage.setBool(_showIdentityKey, showConsoleIdentity),
      storage.setString(_orientationKey, orientation.name),
      storage.setBool(_keepAwakeKey, keepScreenAwake),
      storage.setBool(_pauseInBackgroundKey, pauseInBackground),
      storage.setBool(_autoSaveOnExitKey, autoSaveOnExit),
      storage.setBool(_autoLoadOnStartKey, autoLoadOnStart),
      storage.setBool(_confirmOverwriteKey, confirmBeforeOverwrite),
      storage.setBool(_snesFullscreenKey, snesFullscreen),
      storage.setBool(_gbaFullscreenKey, gbaFullscreen),
      storage.setString(
        _snesButtonColorStyleKey,
        snesButtonColorStyle.name,
      ),
      storage.setInt(_snesButtonAColorKey, snesButtonAColor),
      storage.setInt(_snesButtonBColorKey, snesButtonBColor),
      storage.setInt(_snesButtonXColorKey, snesButtonXColor),
      storage.setInt(_snesButtonYColorKey, snesButtonYColor),
    ]);
  }

  static Future<void> reset() => const EmulatorPreferences().save();
}
