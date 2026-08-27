import 'package:flutter/material.dart';

import '../data/save_state_service.dart';
import '../save_states/save_states_page.dart';
import 'emulator_preferences.dart';

class EmulatorSettingsPage extends StatefulWidget {
  final String gameTitle;
  final bool supportsGameBoyOptions;
  final bool supportsSnesOptions;
  final bool supportsGbaFullscreen;
  final bool supportsNdsOptions;
  final EmulatorPreferences initialPreferences;
  final Future<void> Function() onRestart;
  final Future<bool> Function(int slot, String title) onSaveState;
  final Future<bool> Function(int slot) onLoadState;
  final SaveStateService saveStateService;
  final Future<void> Function()? onOpenSpecialEvents;
  final String specialEventsSubtitle;

  const EmulatorSettingsPage({
    super.key,
    required this.gameTitle,
    required this.supportsGameBoyOptions,
    this.supportsSnesOptions = false,
    this.supportsGbaFullscreen = false,
    this.supportsNdsOptions = false,
    required this.initialPreferences,
    required this.onRestart,
    required this.onSaveState,
    required this.onLoadState,
    required this.saveStateService,
    this.onOpenSpecialEvents,
    this.specialEventsSubtitle = 'Eventos oficiales',
  });

  @override
  State<EmulatorSettingsPage> createState() => _EmulatorSettingsPageState();
}

class _EmulatorSettingsPageState extends State<EmulatorSettingsPage> {
  late EmulatorPreferences _preferences = widget.initialPreferences;

  Future<void> _update(EmulatorPreferences value) async {
    setState(() => _preferences = value);
    await value.save();
  }

  Future<void> _restart() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reiniciar juego'),
        content: const Text(
          'El juego volverá a iniciarse. El progreso que no hayas guardado dentro del juego se perderá.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await widget.onRestart();
    if (mounted) Navigator.pop(context, _preferences);
  }

  Future<void> _openStates(SaveStatesMode mode) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SaveStatesPage(
          gameTitle: widget.gameTitle,
          mode: mode,
          service: widget.saveStateService,
          onSave: widget.onSaveState,
          onLoad: widget.onLoadState,
          confirmBeforeOverwrite: _preferences.confirmBeforeOverwrite,
        ),
      ),
    );
  }

  Future<void> _resetAllSettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restablecer ajustes'),
        content: const Text(
          'Se restaurarán los controles, la pantalla y las opciones de emulación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restablecer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    const defaults = EmulatorPreferences();
    await defaults.save();
    if (mounted) setState(() => _preferences = defaults);
  }

  Future<void> _setSnesColorStyle(SnesButtonColorStyle style) async {
    final colors = switch (style) {
      SnesButtonColorStyle.violet => const <int>[
          0xFF5E4B8B, 0xFF8173AE, 0xFF8173AE, 0xFF5E4B8B,
        ],
      SnesButtonColorStyle.multicolor => const <int>[
          0xFFC84D58, 0xFFD3B84A, 0xFF4D75C8, 0xFF58A66C,
        ],
      SnesButtonColorStyle.monochrome => const <int>[
          0xFF55545B, 0xFF6D6C73, 0xFF6D6C73, 0xFF55545B,
        ],
      SnesButtonColorStyle.custom => <int>[
          _preferences.snesButtonAColor,
          _preferences.snesButtonBColor,
          _preferences.snesButtonXColor,
          _preferences.snesButtonYColor,
        ],
    };
    await _update(_preferences.copyWith(
      snesButtonColorStyle: style,
      snesButtonAColor: colors[0],
      snesButtonBColor: colors[1],
      snesButtonXColor: colors[2],
      snesButtonYColor: colors[3],
    ));
  }

  Future<void> _pickSnesColor(String button) async {
    const palette = <Color>[
      Color(0xFF5E4B8B), Color(0xFF8173AE), Color(0xFF4D75C8),
      Color(0xFF58A66C), Color(0xFFC84D58), Color(0xFFD3B84A),
      Color(0xFFE778B8), Color(0xFF42A5F5), Color(0xFFF5F5F5),
      Color(0xFF55545B),
    ];
    final selected = await showDialog<Color>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Color del botón $button'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final color in palette)
              InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.pop(dialogContext, color),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black54, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    final value = selected.toARGB32();
    await _update(_preferences.copyWith(
      snesButtonColorStyle: SnesButtonColorStyle.custom,
      snesButtonAColor:
          button == 'A' ? value : _preferences.snesButtonAColor,
      snesButtonBColor:
          button == 'B' ? value : _preferences.snesButtonBColor,
      snesButtonXColor:
          button == 'X' ? value : _preferences.snesButtonXColor,
      snesButtonYColor:
          button == 'Y' ? value : _preferences.snesButtonYColor,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _preferences);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Ajustes del emulador')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            const _SectionTitle('Partida'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.restart_alt),
                    title: const Text('Reiniciar juego'),
                    subtitle: const Text('Volver a la pantalla de inicio del juego'),
                    onTap: _restart,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.save_outlined),
                    title: const Text('Guardar estado'),
                    onTap: () => _openStates(SaveStatesMode.save),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Cargar estado'),
                    onTap: () => _openStates(SaveStatesMode.load),
                  ),
                  if (widget.onOpenSpecialEvents != null) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.auto_awesome),
                      title: const Text('Eventos especiales'),
                      subtitle: Text(widget.specialEventsSubtitle),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: widget.onOpenSpecialEvents,
                    ),
                  ],
                ],
              ),
            ),
            if (!widget.supportsNdsOptions) ...[
              const SizedBox(height: 22),
              const _SectionTitle('Controles'),
              Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Control de dirección',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Elige entre la cruceta tradicional o una palanca virtual de ocho direcciones.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<DirectionalControlType>(
                      segments: const [
                        ButtonSegment(
                          value: DirectionalControlType.dPad,
                          label: Text('Cruceta'),
                          icon: Icon(Icons.control_camera_rounded),
                        ),
                        ButtonSegment(
                          value: DirectionalControlType.joystick,
                          label: Text('Palanca'),
                          icon: Icon(Icons.sports_esports_rounded),
                        ),
                      ],
                      selected: {_preferences.directionalControl},
                      onSelectionChanged: (selection) => _update(
                        _preferences.copyWith(
                          directionalControl: selection.first,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ),
            ],
            if (widget.supportsGameBoyOptions) ...[
            const SizedBox(height: 22),
            const _SectionTitle('Controles GB · GBC · GBA'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Distribución', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    SegmentedButton<GameBoyControlLayout>(
                      segments: const [
                        ButtonSegment(
                          value: GameBoyControlLayout.classic,
                          label: Text('Clásica GBA'),
                          icon: Icon(Icons.sports_esports),
                        ),
                        ButtonSegment(
                          value: GameBoyControlLayout.compact,
                          label: Text('Compacta'),
                          icon: Icon(Icons.compress),
                        ),
                      ],
                      selected: {_preferences.layout},
                      onSelectionChanged: (selection) => _update(
                        _preferences.copyWith(layout: selection.first),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Tamaño', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    SegmentedButton<GameBoyControlSize>(
                      segments: const [
                        ButtonSegment(value: GameBoyControlSize.small, label: Text('Pequeño')),
                        ButtonSegment(value: GameBoyControlSize.normal, label: Text('Normal')),
                        ButtonSegment(value: GameBoyControlSize.large, label: Text('Grande')),
                      ],
                      selected: {_preferences.controlSize},
                      onSelectionChanged: (selection) => _update(
                        _preferences.copyWith(controlSize: selection.first),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Opacidad · ${(_preferences.controlOpacity * 100).round()}%'),
                    Slider(
                      value: _preferences.controlOpacity,
                      min: .45,
                      max: 1,
                      divisions: 11,
                      onChanged: (value) => _update(
                        _preferences.copyWith(controlOpacity: value),
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Vibración al pulsar'),
                      value: _preferences.vibrationEnabled,
                      onChanged: (value) => _update(
                        _preferences.copyWith(vibrationEnabled: value),
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Intercambiar A/B'),
                      value: _preferences.swapAB,
                      onChanged: (value) => _update(
                        _preferences.copyWith(swapAB: value),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        const defaults = EmulatorPreferences();
                        final updated = _preferences.copyWith(
                          layout: defaults.layout,
                          controlSize: defaults.controlSize,
                          controlOpacity: defaults.controlOpacity,
                          vibrationEnabled: defaults.vibrationEnabled,
                          swapAB: defaults.swapAB,
                          directionalControl: defaults.directionalControl,
                        );
                        await updated.save();
                        if (mounted) {
                          setState(() => _preferences = updated);
                        }
                      },
                      icon: const Icon(Icons.restore),
                      label: const Text('Restablecer controles'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            const _SectionTitle('Pantalla GB · GBC · GBA'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.supportsGbaFullscreen) ...[
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.fullscreen_rounded),
                        title: const Text('Modo pantalla completa GBA'),
                        subtitle: const Text(
                          'Juego 3:2 a toda altura, sin banner y con controles en los paneles laterales',
                        ),
                        value: _preferences.gbaFullscreen,
                        onChanged: (value) => _update(
                          _preferences.copyWith(gbaFullscreen: value),
                        ),
                      ),
                      const Divider(height: 28),
                    ],
                    const Text('Escalado', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<EmulatorScreenScale>(
                      initialValue: _preferences.screenScale,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(
                          value: EmulatorScreenScale.aspectRatio,
                          child: Text('Mantener proporción'),
                        ),
                        DropdownMenuItem(
                          value: EmulatorScreenScale.fitWidth,
                          child: Text('Ajustar al ancho'),
                        ),
                        DropdownMenuItem(
                          value: EmulatorScreenScale.stretch,
                          child: Text('Ocupar espacio disponible'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          _update(_preferences.copyWith(screenScale: value));
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text('Filtro de imagen', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    SegmentedButton<EmulatorScreenFilter>(
                      segments: const [
                        ButtonSegment(
                          value: EmulatorScreenFilter.pixel,
                          label: Text('Píxel nítido'),
                        ),
                        ButtonSegment(
                          value: EmulatorScreenFilter.smooth,
                          label: Text('Suavizado'),
                        ),
                      ],
                      selected: {_preferences.screenFilter},
                      onSelectionChanged: (selection) => _update(
                        _preferences.copyWith(screenFilter: selection.first),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Mostrar identidad de consola'),
                      subtitle: const Text('Logotipo RetroHub bajo la pantalla'),
                      value: _preferences.showConsoleIdentity,
                      onChanged: (value) => _update(
                        _preferences.copyWith(showConsoleIdentity: value),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Orientación', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<EmulatorOrientation>(
                      initialValue: _preferences.orientation,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(
                          value: EmulatorOrientation.automatic,
                          child: Text('Automática'),
                        ),
                        DropdownMenuItem(
                          value: EmulatorOrientation.portrait,
                          child: Text('Vertical'),
                        ),
                        DropdownMenuItem(
                          value: EmulatorOrientation.landscape,
                          child: Text('Horizontal'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          _update(_preferences.copyWith(orientation: value));
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Mantener pantalla encendida'),
                      subtitle: const Text('Evita que el dispositivo se bloquee al jugar'),
                      value: _preferences.keepScreenAwake,
                      onChanged: (value) => _update(
                        _preferences.copyWith(keepScreenAwake: value),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            const _SectionTitle('Emulación GB · GBC · GBA'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Pausar al minimizar'),
                    subtitle: const Text(
                      'Detiene la emulación cuando RetroHub queda en segundo plano',
                    ),
                    value: _preferences.pauseInBackground,
                    onChanged: (value) => _update(
                      _preferences.copyWith(pauseInBackground: value),
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Guardado automático al salir'),
                    subtitle: const Text(
                      'Usa un estado separado de los cinco slots manuales',
                    ),
                    value: _preferences.autoSaveOnExit,
                    onChanged: (value) => _update(
                      _preferences.copyWith(autoSaveOnExit: value),
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Cargar guardado automático al iniciar'),
                    subtitle: const Text(
                      'Continúa desde el último cierre con autoguardado disponible',
                    ),
                    value: _preferences.autoLoadOnStart,
                    onChanged: (value) => _update(
                      _preferences.copyWith(autoLoadOnStart: value),
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Confirmar antes de sobrescribir'),
                    subtitle: const Text('Protege los estados guardados manualmente'),
                    value: _preferences.confirmBeforeOverwrite,
                    onChanged: (value) => _update(
                      _preferences.copyWith(confirmBeforeOverwrite: value),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.restore),
                    title: const Text('Restablecer todos los ajustes'),
                    subtitle: const Text('Controles, pantalla y emulación'),
                    onTap: _resetAllSettings,
                  ),
                ],
              ),
            ),
            ],
            if (widget.supportsSnesOptions) ...[
              const SizedBox(height: 22),
              const _SectionTitle('RetroHub Super'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.fullscreen_rounded),
                        title: const Text('Modo pantalla completa'),
                        subtitle: const Text(
                          'Juego 4:3 a toda altura, sin banner y con controles en los paneles laterales',
                        ),
                        value: _preferences.snesFullscreen,
                        onChanged: (value) => _update(
                          _preferences.copyWith(snesFullscreen: value),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Opacidad de controles · '
                        '${(_preferences.controlOpacity * 100).round()}%',
                      ),
                      Slider(
                        value: _preferences.controlOpacity,
                        min: .45,
                        max: 1,
                        divisions: 11,
                        onChanged: (value) => _update(
                          _preferences.copyWith(controlOpacity: value),
                        ),
                      ),
                      const Divider(height: 28),
                      const Text(
                        'Colores A/B/X/Y',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<SnesButtonColorStyle>(
                        initialValue: _preferences.snesButtonColorStyle,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: SnesButtonColorStyle.violet,
                            child: Text('Violeta clásico'),
                          ),
                          DropdownMenuItem(
                            value: SnesButtonColorStyle.multicolor,
                            child: Text('Multicolor'),
                          ),
                          DropdownMenuItem(
                            value: SnesButtonColorStyle.monochrome,
                            child: Text('Monocromático'),
                          ),
                          DropdownMenuItem(
                            value: SnesButtonColorStyle.custom,
                            child: Text('Personalizado'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) _setSnesColorStyle(value);
                        },
                      ),
                      if (_preferences.snesButtonColorStyle ==
                          SnesButtonColorStyle.custom) ...[
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          children: [
                            _SnesColorButton(
                              label: 'A',
                              color: Color(_preferences.snesButtonAColor),
                              onTap: () => _pickSnesColor('A'),
                            ),
                            _SnesColorButton(
                              label: 'B',
                              color: Color(_preferences.snesButtonBColor),
                              onTap: () => _pickSnesColor('B'),
                            ),
                            _SnesColorButton(
                              label: 'X',
                              color: Color(_preferences.snesButtonXColor),
                              onTap: () => _pickSnesColor('X'),
                            ),
                            _SnesColorButton(
                              label: 'Y',
                              color: Color(_preferences.snesButtonYColor),
                              onTap: () => _pickSnesColor('Y'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            if (widget.supportsNdsOptions) ...[
              const SizedBox(height: 22),
              const _SectionTitle('Nintendo DS'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pantallas', style: TextStyle(fontWeight: FontWeight.bold)),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Intercambiar pantallas'),
                        subtitle: const Text('Cambia la posición de la pantalla principal y la táctil'),
                        value: _preferences.ndsSwapScreens,
                        onChanged: (value) => _update(_preferences.copyWith(ndsSwapScreens: value)),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<NdsScreenEmphasis>(
                        segments: const [
                          ButtonSegment(value: NdsScreenEmphasis.equal, label: Text('Iguales')),
                          ButtonSegment(value: NdsScreenEmphasis.top, label: Text('Superior')),
                          ButtonSegment(value: NdsScreenEmphasis.bottom, label: Text('Inferior')),
                        ],
                        selected: {_preferences.ndsScreenEmphasis},
                        onSelectionChanged: (value) => _update(_preferences.copyWith(ndsScreenEmphasis: value.first)),
                      ),
                      _NdsSlider(
                        label: 'Tamaño conjunto de pantallas',
                        value: _preferences.ndsScreensScale,
                        min: .7,
                        max: 1,
                        onChanged: (value) => _update(_preferences.copyWith(ndsScreensScale: value)),
                      ),
                      const Divider(height: 30),
                      const Text('Controles propios', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      SegmentedButton<DirectionalControlType>(
                        segments: const [
                          ButtonSegment(value: DirectionalControlType.dPad, label: Text('Cruceta')),
                          ButtonSegment(value: DirectionalControlType.joystick, label: Text('Palanca')),
                        ],
                        selected: {_preferences.ndsDirectionalControl},
                        onSelectionChanged: (value) => _update(_preferences.copyWith(ndsDirectionalControl: value.first)),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Intercambiar A/B'),
                        value: _preferences.ndsSwapAB,
                        onChanged: (value) => _update(_preferences.copyWith(ndsSwapAB: value)),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Vibración al pulsar'),
                        value: _preferences.ndsVibrationEnabled,
                        onChanged: (value) => _update(_preferences.copyWith(ndsVibrationEnabled: value)),
                      ),
                      _NdsSlider(label: 'Opacidad', value: _preferences.ndsControlOpacity, min: .35, max: 1, onChanged: (value) => _update(_preferences.copyWith(ndsControlOpacity: value))),
                      _NdsSlider(label: 'Tamaño D-pad / palanca', value: _preferences.ndsDpadScale, min: .75, max: 1.5, onChanged: (value) => _update(_preferences.copyWith(ndsDpadScale: value))),
                      _NdsSlider(label: 'Tamaño A/B/X/Y', value: _preferences.ndsActionScale, min: .75, max: 1.5, onChanged: (value) => _update(_preferences.copyWith(ndsActionScale: value))),
                      _NdsSlider(label: 'Tamaño L/R', value: _preferences.ndsShoulderScale, min: .75, max: 1.5, onChanged: (value) => _update(_preferences.copyWith(ndsShoulderScale: value))),
                      _NdsSlider(label: 'Tamaño Start/Select', value: _preferences.ndsSystemScale, min: .75, max: 1.5, onChanged: (value) => _update(_preferences.copyWith(ndsSystemScale: value))),
                      const Divider(height: 30),
                      const Text('Posición', style: TextStyle(fontWeight: FontWeight.bold)),
                      _NdsSlider(label: 'D-pad horizontal', value: _preferences.ndsDpadX, min: -1, max: 1, onChanged: (value) => _update(_preferences.copyWith(ndsDpadX: value))),
                      _NdsSlider(label: 'D-pad vertical', value: _preferences.ndsDpadY, min: -1, max: 1, onChanged: (value) => _update(_preferences.copyWith(ndsDpadY: value))),
                      _NdsSlider(label: 'A/B/X/Y horizontal', value: _preferences.ndsActionX, min: -1, max: 1, onChanged: (value) => _update(_preferences.copyWith(ndsActionX: value))),
                      _NdsSlider(label: 'A/B/X/Y vertical', value: _preferences.ndsActionY, min: -1, max: 1, onChanged: (value) => _update(_preferences.copyWith(ndsActionY: value))),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () async {
                          const defaults = EmulatorPreferences();
                          final updated = _preferences.copyWith(
                            ndsDirectionalControl: defaults.ndsDirectionalControl,
                            ndsControlOpacity: defaults.ndsControlOpacity,
                            ndsSwapAB: defaults.ndsSwapAB,
                            ndsVibrationEnabled: defaults.ndsVibrationEnabled,
                            ndsDpadScale: defaults.ndsDpadScale,
                            ndsActionScale: defaults.ndsActionScale,
                            ndsShoulderScale: defaults.ndsShoulderScale,
                            ndsSystemScale: defaults.ndsSystemScale,
                            ndsDpadX: defaults.ndsDpadX,
                            ndsDpadY: defaults.ndsDpadY,
                            ndsActionX: defaults.ndsActionX,
                            ndsActionY: defaults.ndsActionY,
                            ndsScreensScale: defaults.ndsScreensScale,
                            ndsScreenEmphasis: defaults.ndsScreenEmphasis,
                            ndsSwapScreens: defaults.ndsSwapScreens,
                          );
                          await _update(updated);
                        },
                        icon: const Icon(Icons.restore),
                        label: const Text('Restablecer solamente Nintendo DS'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
      ),
    );
  }
}

class _NdsSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _NdsSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label · ${(value * 100).round()}%'),
          Slider(value: value, min: min, max: max, divisions: 15, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SnesColorButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SnesColorButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black45),
        ),
      ),
      label: Text('Botón $label'),
    );
  }
}
