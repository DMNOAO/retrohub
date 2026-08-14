import 'package:shared_preferences/shared_preferences.dart';

enum GameBoyControlLayout { classic, compact }

enum GameBoyControlSize { small, normal, large }

class EmulatorPreferences {
  static const _layoutKey = 'emulator_gb_control_layout';
  static const _sizeKey = 'emulator_gb_control_size';
  static const _opacityKey = 'emulator_gb_control_opacity';
  static const _vibrationKey = 'emulator_gb_control_vibration';
  static const _swapButtonsKey = 'emulator_gb_swap_ab';

  final GameBoyControlLayout layout;
  final GameBoyControlSize controlSize;
  final double controlOpacity;
  final bool vibrationEnabled;
  final bool swapAB;

  const EmulatorPreferences({
    this.layout = GameBoyControlLayout.classic,
    this.controlSize = GameBoyControlSize.normal,
    this.controlOpacity = 1,
    this.vibrationEnabled = true,
    this.swapAB = false,
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
  }) {
    return EmulatorPreferences(
      layout: layout ?? this.layout,
      controlSize: controlSize ?? this.controlSize,
      controlOpacity: controlOpacity ?? this.controlOpacity,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      swapAB: swapAB ?? this.swapAB,
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
    ]);
  }

  static Future<void> reset() => const EmulatorPreferences().save();
}
