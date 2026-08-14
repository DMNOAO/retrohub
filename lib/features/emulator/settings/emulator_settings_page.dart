import 'package:flutter/material.dart';

import '../data/save_state_service.dart';
import '../save_states/save_states_page.dart';
import 'emulator_preferences.dart';

class EmulatorSettingsPage extends StatefulWidget {
  final String gameTitle;
  final EmulatorPreferences initialPreferences;
  final Future<void> Function() onRestart;
  final Future<bool> Function(int slot, String title) onSaveState;
  final Future<bool> Function(int slot) onLoadState;
  final SaveStateService saveStateService;

  const EmulatorSettingsPage({
    super.key,
    required this.gameTitle,
    required this.initialPreferences,
    required this.onRestart,
    required this.onSaveState,
    required this.onLoadState,
    required this.saveStateService,
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
        ),
      ),
    );
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
                ],
              ),
            ),
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
                        await EmulatorPreferences.reset();
                        if (mounted) {
                          setState(() => _preferences = const EmulatorPreferences());
                        }
                      },
                      icon: const Icon(Icons.restore),
                      label: const Text('Restablecer controles'),
                    ),
                  ],
                ),
              ),
            ),
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
