import 'package:shared_preferences/shared_preferences.dart';

enum GameBoyControlLayout { classic, compact }

enum GameBoyControlSize { small, normal, large }

enum DirectionalControlType { dPad, joystick }

enum EmulatorScreenScale { aspectRatio, fitWidth, stretch }

enum EmulatorScreenFilter { pixel, smooth }

enum EmulatorOrientation { automatic, portrait, landscape }

enum SnesButtonColorStyle { violet, multicolor, monochrome, custom }

enum NdsScreenEmphasis { equal, top, bottom }

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
  static const _ndsDirectionalControlKey = 'emulator_nds_directional_control';
  static const _ndsOpacityKey = 'emulator_nds_control_opacity';
  static const _ndsSwapButtonsKey = 'emulator_nds_swap_ab';
  static const _ndsVibrationKey = 'emulator_nds_control_vibration';
  static const _ndsDpadScaleKey = 'emulator_nds_dpad_scale';
  static const _ndsActionScaleKey = 'emulator_nds_action_scale';
  static const _ndsShoulderScaleKey = 'emulator_nds_shoulder_scale';
  static const _ndsSystemScaleKey = 'emulator_nds_system_scale';
  static const _ndsDpadXKey = 'emulator_nds_dpad_x';
  static const _ndsDpadYKey = 'emulator_nds_dpad_y';
  static const _ndsActionXKey = 'emulator_nds_action_x';
  static const _ndsActionYKey = 'emulator_nds_action_y';
  static const _ndsScreensScaleKey = 'emulator_nds_screens_scale';
  static const _ndsScreenEmphasisKey = 'emulator_nds_screen_emphasis';
  static const _ndsSwapScreensKey = 'emulator_nds_swap_screens';

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
  final DirectionalControlType ndsDirectionalControl;
  final double ndsControlOpacity;
  final bool ndsSwapAB;
  final bool ndsVibrationEnabled;
  final double ndsDpadScale;
  final double ndsActionScale;
  final double ndsShoulderScale;
  final double ndsSystemScale;
  final double ndsDpadX;
  final double ndsDpadY;
  final double ndsActionX;
  final double ndsActionY;
  final double ndsScreensScale;
  final NdsScreenEmphasis ndsScreenEmphasis;
  final bool ndsSwapScreens;

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
    this.ndsDirectionalControl = DirectionalControlType.dPad,
    this.ndsControlOpacity = .72,
    this.ndsSwapAB = false,
    this.ndsVibrationEnabled = true,
    this.ndsDpadScale = 1.15,
    this.ndsActionScale = 1.15,
    this.ndsShoulderScale = 1,
    this.ndsSystemScale = 1,
    this.ndsDpadX = 0,
    this.ndsDpadY = 0,
    this.ndsActionX = 0,
    this.ndsActionY = 0,
    this.ndsScreensScale = 1,
    this.ndsScreenEmphasis = NdsScreenEmphasis.equal,
    this.ndsSwapScreens = false,
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
    DirectionalControlType? ndsDirectionalControl,
    double? ndsControlOpacity,
    bool? ndsSwapAB,
    bool? ndsVibrationEnabled,
    double? ndsDpadScale,
    double? ndsActionScale,
    double? ndsShoulderScale,
    double? ndsSystemScale,
    double? ndsDpadX,
    double? ndsDpadY,
    double? ndsActionX,
    double? ndsActionY,
    double? ndsScreensScale,
    NdsScreenEmphasis? ndsScreenEmphasis,
    bool? ndsSwapScreens,
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
      ndsDirectionalControl: ndsDirectionalControl ?? this.ndsDirectionalControl,
      ndsControlOpacity: ndsControlOpacity ?? this.ndsControlOpacity,
      ndsSwapAB: ndsSwapAB ?? this.ndsSwapAB,
      ndsVibrationEnabled: ndsVibrationEnabled ?? this.ndsVibrationEnabled,
      ndsDpadScale: ndsDpadScale ?? this.ndsDpadScale,
      ndsActionScale: ndsActionScale ?? this.ndsActionScale,
      ndsShoulderScale: ndsShoulderScale ?? this.ndsShoulderScale,
      ndsSystemScale: ndsSystemScale ?? this.ndsSystemScale,
      ndsDpadX: ndsDpadX ?? this.ndsDpadX,
      ndsDpadY: ndsDpadY ?? this.ndsDpadY,
      ndsActionX: ndsActionX ?? this.ndsActionX,
      ndsActionY: ndsActionY ?? this.ndsActionY,
      ndsScreensScale: ndsScreensScale ?? this.ndsScreensScale,
      ndsScreenEmphasis: ndsScreenEmphasis ?? this.ndsScreenEmphasis,
      ndsSwapScreens: ndsSwapScreens ?? this.ndsSwapScreens,
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
      ndsDirectionalControl: DirectionalControlType.values.firstWhere(
        (value) => value.name == storage.getString(_ndsDirectionalControlKey),
        orElse: () => DirectionalControlType.dPad,
      ),
      ndsControlOpacity: (storage.getDouble(_ndsOpacityKey) ?? .72).clamp(.35, 1),
      ndsSwapAB: storage.getBool(_ndsSwapButtonsKey) ?? false,
      ndsVibrationEnabled: storage.getBool(_ndsVibrationKey) ?? true,
      ndsDpadScale: (storage.getDouble(_ndsDpadScaleKey) ?? 1.15).clamp(.75, 1.5),
      ndsActionScale: (storage.getDouble(_ndsActionScaleKey) ?? 1.15).clamp(.75, 1.5),
      ndsShoulderScale: (storage.getDouble(_ndsShoulderScaleKey) ?? 1).clamp(.75, 1.5),
      ndsSystemScale: (storage.getDouble(_ndsSystemScaleKey) ?? 1).clamp(.75, 1.5),
      ndsDpadX: (storage.getDouble(_ndsDpadXKey) ?? 0).clamp(-1, 1),
      ndsDpadY: (storage.getDouble(_ndsDpadYKey) ?? 0).clamp(-1, 1),
      ndsActionX: (storage.getDouble(_ndsActionXKey) ?? 0).clamp(-1, 1),
      ndsActionY: (storage.getDouble(_ndsActionYKey) ?? 0).clamp(-1, 1),
      ndsScreensScale: (storage.getDouble(_ndsScreensScaleKey) ?? 1).clamp(.7, 1),
      ndsScreenEmphasis: NdsScreenEmphasis.values.firstWhere(
        (value) => value.name == storage.getString(_ndsScreenEmphasisKey),
        orElse: () => NdsScreenEmphasis.equal,
      ),
      ndsSwapScreens: storage.getBool(_ndsSwapScreensKey) ?? false,
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
      storage.setString(_ndsDirectionalControlKey, ndsDirectionalControl.name),
      storage.setDouble(_ndsOpacityKey, ndsControlOpacity),
      storage.setBool(_ndsSwapButtonsKey, ndsSwapAB),
      storage.setBool(_ndsVibrationKey, ndsVibrationEnabled),
      storage.setDouble(_ndsDpadScaleKey, ndsDpadScale),
      storage.setDouble(_ndsActionScaleKey, ndsActionScale),
      storage.setDouble(_ndsShoulderScaleKey, ndsShoulderScale),
      storage.setDouble(_ndsSystemScaleKey, ndsSystemScale),
      storage.setDouble(_ndsDpadXKey, ndsDpadX),
      storage.setDouble(_ndsDpadYKey, ndsDpadY),
      storage.setDouble(_ndsActionXKey, ndsActionX),
      storage.setDouble(_ndsActionYKey, ndsActionY),
      storage.setDouble(_ndsScreensScaleKey, ndsScreensScale),
      storage.setString(_ndsScreenEmphasisKey, ndsScreenEmphasis.name),
      storage.setBool(_ndsSwapScreensKey, ndsSwapScreens),
    ]);
  }

  static Future<void> reset() => const EmulatorPreferences().save();
}
