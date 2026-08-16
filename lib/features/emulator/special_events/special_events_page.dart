import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'crystal_gs_ball_service.dart';

class SpecialEventsPage extends StatefulWidget {
  final Future<CrystalGsBallStatus> Function() inspectGsBall;
  final Future<CrystalGsBallActivationResult> Function({
    bool allowBeforeLeague,
  }) activateGsBall;

  const SpecialEventsPage({
    super.key,
    required this.inspectGsBall,
    required this.activateGsBall,
  });

  @override
  State<SpecialEventsPage> createState() => _SpecialEventsPageState();
}

class _SpecialEventsPageState extends State<SpecialEventsPage> {
  CrystalGsBallStatus? _status;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final status = await widget.inspectGsBall();
    if (mounted) setState(() => _status = status);
  }

  Future<void> _activate({bool debugBypass = false}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          debugBypass
              ? 'Activar evento para prueba'
              : 'Activar evento GS Ball',
        ),
        content: Text(
          debugBypass
              ? 'Esta opción de desarrollo omitirá el requisito de la Liga y modificará esta partida. RetroHub creará primero una copia de seguridad.'
              : 'RetroHub guardará la partida y creará una copia de seguridad antes de habilitar el evento oficial de Celebi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Activar evento'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _working = true);
    try {
      final result = await widget.activateGsBall(
        allowBeforeLeague: debugBypass,
      );
      if (!mounted) return;
      setState(() => _status = result.status);
      final message = result.succeeded
          ? 'Evento activado. Reinicia el juego y sigue las instrucciones.'
          : _messageFor(result.status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo activar el evento: $error')),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    return Scaffold(
      appBar: AppBar(title: const Text('Eventos especiales')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        child: Icon(Icons.auto_awesome),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GS Ball · Celebi',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const Text('Pokémon Cristal'),
                          ],
                        ),
                      ),
                      _StatusChip(status: status),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Requisito',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text('Haber vencido a la Liga Pokémon.'),
                  const SizedBox(height: 18),
                  const Text(
                    'Después de activar el evento',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const _Instruction(
                    number: 1,
                    text:
                        'Reinicia el juego y entra al Centro Pokémon de Ciudad Trigal.',
                  ),
                  const _Instruction(
                    number: 2,
                    text:
                        'Al intentar salir, la recepcionista te entregará la GS Ball mediante la escena original.',
                  ),
                  const _Instruction(
                    number: 3,
                    text:
                        'Lleva la GS Ball a César en Pueblo Azalea.',
                  ),
                  const _Instruction(
                    number: 4,
                    text:
                        'Espera un día y vuelve a hablar con César.',
                  ),
                  const _Instruction(
                    number: 5,
                    text:
                        'Lleva la GS Ball al santuario del Encinar para encontrar a Celebi.',
                  ),
                  const SizedBox(height: 18),
                  if (status == null)
                    const Center(child: CircularProgressIndicator())
                  else if (status == CrystalGsBallStatus.available)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _working ? null : _activate,
                        icon: _working
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.lock_open),
                        label: const Text('Activar evento'),
                      ),
                    )
                  else if (kDebugMode &&
                      status == CrystalGsBallStatus.leagueRequired)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _messageFor(status),
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _working
                              ? null
                              : () => _activate(debugBypass: true),
                          icon: const Icon(Icons.science_outlined),
                          label: const Text('Activar solo para prueba'),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Disponible únicamente en modo debug.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  else
                    Text(
                      _messageFor(status),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _messageFor(CrystalGsBallStatus status) {
    return switch (status) {
      CrystalGsBallStatus.noSave =>
        'Guarda la partida dentro del juego antes de continuar.',
      CrystalGsBallStatus.incompatibleSave =>
        'Este guardado no corresponde a una versión internacional compatible de Pokémon Cristal.',
      CrystalGsBallStatus.leagueRequired =>
        'Evento bloqueado: primero debes vencer a la Liga Pokémon y guardar la partida.',
      CrystalGsBallStatus.available => 'El evento está disponible.',
      CrystalGsBallStatus.activated =>
        'Evento activado. Las instrucciones seguirán disponibles aquí.',
    };
  }
}

class _StatusChip extends StatelessWidget {
  final CrystalGsBallStatus? status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      null => 'Comprobando',
      CrystalGsBallStatus.noSave => 'Sin guardado',
      CrystalGsBallStatus.incompatibleSave => 'No compatible',
      CrystalGsBallStatus.leagueRequired => 'Bloqueado',
      CrystalGsBallStatus.available => 'Disponible',
      CrystalGsBallStatus.activated => 'Activado',
    };
    return Chip(label: Text(label));
  }
}

class _Instruction extends StatelessWidget {
  final int number;
  final String text;

  const _Instruction({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            child: Text('$number', style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
