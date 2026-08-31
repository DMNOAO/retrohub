import 'package:flutter/material.dart';

import '../../../core/assets/sprite_image.dart';
import '../../pokemon/models/pokemon_game_profile.dart';
import 'crystal_gs_ball_service.dart';
import 'gen1_mew_event_service.dart';
import 'gen2_red_reward.dart';
import 'gen2_red_reward_service.dart';
import 'gen3_special_event_service.dart';

class SpecialEventsPage extends StatefulWidget {
  final PokemonGameVersion version;
  final Future<CrystalGsBallStatus> Function() inspectGsBall;
  final Future<CrystalGsBallActivationResult> Function() activateGsBall;
  final Future<Gen3SpecialEventStatus> Function(Gen3SpecialEvent event)
      inspectGen3Event;
  final Future<Gen3SpecialEventActivationResult> Function(
    Gen3SpecialEvent event,
  )
  activateGen3Event;
  final int redVictories;
  final Set<String> claimedRedRewards;
  final bool redChallengeUnlocked;
  final Future<Gen2RedRewardStatus> Function() inspectGen2RedReward;
  final Future<Gen2RedRewardResult> Function(Gen2RedReward reward)
      claimGen2RedReward;
  final bool gen1MewClaimed;
  final Future<Gen1MewEventStatus> Function() inspectGen1MewEvent;
  final Future<Gen1MewEventResult> Function() claimGen1MewEvent;

  const SpecialEventsPage({
    super.key,
    required this.version,
    required this.inspectGsBall,
    required this.activateGsBall,
    required this.inspectGen3Event,
    required this.activateGen3Event,
    this.redVictories = 0,
    this.claimedRedRewards = const {},
    this.redChallengeUnlocked = false,
    required this.inspectGen2RedReward,
    required this.claimGen2RedReward,
    this.gen1MewClaimed = false,
    required this.inspectGen1MewEvent,
    required this.claimGen1MewEvent,
  });

  @override
  State<SpecialEventsPage> createState() => _SpecialEventsPageState();
}

class _SpecialEventsPageState extends State<SpecialEventsPage> {
  final Gen3SpecialEventService _gen3Service =
      const Gen3SpecialEventService();
  CrystalGsBallStatus? _gsStatus;
  final Map<Gen3SpecialEvent, Gen3SpecialEventStatus> _gen3Statuses = {};
  Gen3SpecialEvent? _workingEvent;
  bool _workingGs = false;
  Gen2RedRewardStatus? _gen2Status;
  late final Set<String> _claimedRedRewards = {...widget.claimedRedRewards};
  Gen2RedReward? _workingReward;
  Gen1MewEventStatus? _gen1MewStatus;
  late bool _gen1MewClaimed = widget.gen1MewClaimed;
  bool _workingMew = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (_isGen1) {
      final status = await widget.inspectGen1MewEvent();
      if (mounted) setState(() => _gen1MewStatus = status);
      return;
    }
    if (_isGen2) {
      if (!widget.redChallengeUnlocked &&
          widget.version != PokemonGameVersion.crystal) {
        return;
      }
      final rewardStatus = await widget.inspectGen2RedReward();
      final gsStatus = widget.version == PokemonGameVersion.crystal
          ? await widget.inspectGsBall()
          : null;
      if (mounted) setState(() {
        _gen2Status = rewardStatus;
        _gsStatus = gsStatus;
      });
      return;
    }
    final events = _gen3Service.eventsFor(widget.version);
    final statuses = <Gen3SpecialEvent, Gen3SpecialEventStatus>{};
    for (final event in events) {
      statuses[event] = await widget.inspectGen3Event(event);
    }
    if (mounted) setState(() => _gen3Statuses.addAll(statuses));
  }

  bool get _isGen2 => widget.version == PokemonGameVersion.gold ||
      widget.version == PokemonGameVersion.silver ||
      widget.version == PokemonGameVersion.crystal;

  bool get _isGen1 => widget.version == PokemonGameVersion.redBlue ||
      widget.version == PokemonGameVersion.yellow;

  Future<void> _claimReward(Gen2RedReward reward) async {
    if (!await _confirm('premio ${reward.name} variocolor') || !mounted) return;
    setState(() => _workingReward = reward);
    try {
      final result = await widget.claimGen2RedReward(reward);
      if (!mounted) return;
      if (result.succeeded) _claimedRedRewards.add(reward.eventKey);
      final nextStatus = result.succeeded
          ? await widget.inspectGen2RedReward()
          : result.status;
      if (!mounted) return;
      setState(() => _gen2Status = nextStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.succeeded
              ? '${reward.name} variocolor fue añadido a tu equipo.'
              : _gen2Message(result.status)),
        ),
      );
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _workingReward = null);
    }
  }

  Future<void> _claimMew() async {
    if (!await _confirm('Mew de evento') || !mounted) return;
    setState(() => _workingMew = true);
    try {
      final result = await widget.claimGen1MewEvent();
      if (!mounted) return;
      if (result.succeeded) _gen1MewClaimed = true;
      final status = result.succeeded
          ? await widget.inspectGen1MewEvent()
          : result.status;
      if (!mounted) return;
      setState(() => _gen1MewStatus = status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.succeeded
            ? 'Mew fue añadido a tu equipo.'
            : _gen1MewMessage(result.status))),
      );
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _workingMew = false);
    }
  }

  Future<bool> _confirm(String title) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Activar $title'),
            content: const Text(
              'RetroHub guardará la partida y creará una copia de seguridad antes de habilitar este evento original.',
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
        ) ??
        false;
  }

  Future<void> _activateGsBall() async {
    if (!await _confirm('evento GS Ball') || !mounted) return;
    setState(() => _workingGs = true);
    try {
      final result = await widget.activateGsBall();
      if (!mounted) return;
      setState(() => _gsStatus = result.status);
      _showResult(result.succeeded, _gsMessage(result.status));
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _workingGs = false);
    }
  }

  Future<void> _activateGen3(_EventPresentation presentation) async {
    if (!await _confirm(presentation.title) || !mounted) return;
    setState(() => _workingEvent = presentation.event);
    try {
      final result = await widget.activateGen3Event(presentation.event);
      if (!mounted) return;
      setState(() => _gen3Statuses[presentation.event] = result.status);
      _showResult(result.succeeded, _gen3Message(result.status));
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _workingEvent = null);
    }
  }

  void _showResult(bool succeeded, String fallback) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          succeeded
              ? 'Evento activado. Reinicia el juego y sigue las instrucciones.'
              : fallback,
        ),
      ),
    );
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No se pudo activar el evento: $error')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cards = _isGen1
        ? <Widget>[_buildGen1MewCard()]
        : _isGen2
        ? <Widget>[
            if (widget.version == PokemonGameVersion.crystal) _buildGsCard(),
            widget.redChallengeUnlocked
                ? _buildRedRewardsCard()
                : _buildLockedRedChallengeCard(),
          ]
        : _presentations(widget.version)
              .map((presentation) => _buildGen3Card(presentation))
              .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Eventos especiales')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: cards,
      ),
    );
  }

  Widget _buildGen1MewCard() {
    final canClaim = !_gen1MewClaimed &&
        _gen1MewStatus == Gen1MewEventStatus.available;
    return _EventCard(
      title: 'Mew de evento',
      game: widget.version == PokemonGameVersion.yellow
          ? 'Pokémon Amarillo'
          : 'Pokémon Rojo y Azul',
      statusLabel: _gen1MewClaimed ? 'Entregado' : 'Regalo especial',
      statusMessage: _gen1MewClaimed
          ? 'Mew ya fue recibido en este guardado.'
          : _gen1MewMessage(_gen1MewStatus),
      canActivate: canClaim,
      working: _workingMew,
      onActivate: _claimMew,
      instructions: [
        'Deja un espacio libre en tu equipo y guarda dentro del juego.',
        'Recibe a Mew de nivel 5 mediante RetroHub.',
        'Se creará una copia de seguridad antes de modificar el guardado.',
        'El regalo solo puede recibirse una vez.',
      ],
    );
  }

  String _gen1MewMessage(Gen1MewEventStatus? status) => switch (status) {
        null => 'Comprobando guardado…',
        Gen1MewEventStatus.noSave => 'Guarda dentro del juego antes de continuar.',
        Gen1MewEventStatus.incompatibleSave => 'El guardado de Gen I no es compatible.',
        Gen1MewEventStatus.unsupported => 'Este evento no está disponible en esta edición.',
        Gen1MewEventStatus.partyFull => 'Deja un espacio libre en el equipo y guarda.',
        Gen1MewEventStatus.available => 'Mew está disponible para recibir.',
        Gen1MewEventStatus.delivered => 'Mew fue entregado.',
      };

  Widget _buildLockedRedChallengeCard() {
    return const Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(Icons.lock_outline),
        title: Text('Desafío contra Rojo'),
        subtitle: Text('Bloqueado'),
      ),
    );
  }

  Widget _buildRedRewardsCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Desafío contra Rojo', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('${widget.redVictories} victorias registradas · premios PCNY variocolor'),
            const SizedBox(height: 12),
            ...Gen2RedReward.values.map((reward) {
              final claimed = _claimedRedRewards.contains(reward.eventKey);
              final unlocked = widget.redVictories >= reward.requiredVictories;
              final canClaim = unlocked && !claimed &&
                  _gen2Status == Gen2RedRewardStatus.available;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: SpriteImage(
                  path: _rewardSprite(reward),
                  size: 48,
                  fallbackIcon: Icons.catching_pokemon,
                ),
                title: Text('${reward.name} variocolor · Nv. ${reward.level}'),
                subtitle: Text(claimed
                    ? 'Entregado'
                    : unlocked
                    ? _gen2Message(_gen2Status)
                    : 'Se desbloquea con ${reward.requiredVictories} victorias'),
                trailing: claimed
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : _workingReward == reward
                    ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator())
                    : FilledButton(
                        onPressed: canClaim ? () => _claimReward(reward) : null,
                        child: const Text('Recibir'),
                      ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _rewardSprite(Gen2RedReward reward) {
    final folder = switch (widget.version) {
      PokemonGameVersion.gold => 'gold',
      PokemonGameVersion.silver => 'silver',
      _ => 'crystal',
    };
    final extension = folder == 'crystal' ? 'gif' : 'png';
    return 'assets/sprites/pokemon/gbc/$folder/shiny/'
        '${reward.speciesId.toString().padLeft(4, '0')}.$extension';
  }

  String _gen2Message(Gen2RedRewardStatus? status) => switch (status) {
        null => 'Comprobando guardado…',
        Gen2RedRewardStatus.noSave => 'Guarda dentro del juego antes de recibirlo.',
        Gen2RedRewardStatus.incompatibleSave => 'El guardado de Gen II no es compatible.',
        Gen2RedRewardStatus.unsupported => 'Esta edición no admite estos premios.',
        Gen2RedRewardStatus.partyFull => 'Deja un espacio libre en el equipo y guarda.',
        Gen2RedRewardStatus.available => 'Disponible para recibir.',
        Gen2RedRewardStatus.delivered => 'Entregado correctamente.',
      };

  Widget _buildGsCard() {
    return _EventCard(
      title: 'GS Ball · Celebi',
      game: 'Pokémon Cristal',
      statusLabel: _gsStatusLabel(_gsStatus),
      statusMessage: _gsStatus == null ? null : _gsMessage(_gsStatus!),
      canActivate: _gsStatus == CrystalGsBallStatus.available,
      working: _workingGs,
      onActivate: _activateGsBall,
      instructions: const [
        'Reinicia el juego y entra al Centro Pokémon de Ciudad Trigal.',
        'Al intentar salir, la recepcionista te entregará la GS Ball mediante la escena original.',
        'Lleva la GS Ball a César en Pueblo Azalea.',
        'Espera un día y vuelve a hablar con César.',
        'Lleva la GS Ball al santuario del Encinar para encontrar a Celebi.',
      ],
    );
  }

  Widget _buildGen3Card(_EventPresentation presentation) {
    final status = _gen3Statuses[presentation.event];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _EventCard(
        title: presentation.title,
        game: presentation.game,
        statusLabel: _gen3StatusLabel(status),
        statusMessage: status == null ? null : _gen3Message(status),
        canActivate: status == Gen3SpecialEventStatus.available,
        working: _workingEvent == presentation.event,
        onActivate: () => _activateGen3(presentation),
        instructions: presentation.instructions,
      ),
    );
  }

  List<_EventPresentation> _presentations(PokemonGameVersion version) {
    final game = _gameName(version);
    final port = version == PokemonGameVersion.fireRed ||
            version == PokemonGameVersion.leafGreen
        ? 'el puerto de Ciudad Carmín'
        : 'el ferry de Ciudad Calagua';
    return _gen3Service.eventsFor(version).map((event) {
      return switch (event) {
        Gen3SpecialEvent.eonTicket => _EventPresentation(
            event: event,
            title: 'Ticket Eón · Latias/Latios',
            game: game,
            instructions: [
              'Reinicia el juego y ve al ferry de Ciudad Calagua.',
              'Presenta el Ticket Eón para viajar a Isla del Sur.',
              'Entra al santuario e interactúa con la piedra central.',
              version == PokemonGameVersion.ruby
                  ? 'Encontrarás a Latias; Latios es el Pokémon errante de esta edición.'
                  : version == PokemonGameVersion.sapphire
                  ? 'Encontrarás a Latios; Latias es el Pokémon errante de esta edición.'
                  : 'Encontrarás al Pokémon Eón opuesto al que elegiste después de la Liga.',
            ],
          ),
        Gen3SpecialEvent.oldSeaMap => _EventPresentation(
            event: event,
            title: 'Mapa Viejo · Mew',
            game: game,
            instructions: const [
              'Reinicia el juego y ve al ferry de Ciudad Calagua.',
              'Presenta el Mapa Viejo para viajar a Isla Suprema.',
              'Sigue a Mew entre la hierba alta hasta alcanzarlo.',
              'Interactúa con Mew para iniciar el encuentro.',
            ],
          ),
        Gen3SpecialEvent.auroraTicket => _EventPresentation(
            event: event,
            title: 'Ticket Aurora · Deoxys',
            game: game,
            instructions: [
              'Reinicia el juego y ve a $port.',
              'Presenta el Ticket Aurora para viajar a Isla Origen.',
              'Resuelve el recorrido del triángulo sin dar pasos de más.',
              'Cuando el triángulo se vuelva rojo, interactúa con él para encontrar a Deoxys.',
            ],
          ),
        Gen3SpecialEvent.mysticTicket => _EventPresentation(
            event: event,
            title: 'Ticket Místico · Lugia y Ho-Oh',
            game: game,
            instructions: [
              'Reinicia el juego y ve a $port.',
              'Presenta el Ticket Místico para viajar a Roca Ombligo.',
              'Desciende hasta el fondo para encontrar a Lugia.',
              'Sube hasta la cima para encontrar a Ho-Oh.',
            ],
          ),
      };
    }).toList();
  }

  String _gameName(PokemonGameVersion version) => switch (version) {
        PokemonGameVersion.ruby => 'Pokémon Rubí',
        PokemonGameVersion.sapphire => 'Pokémon Zafiro',
        PokemonGameVersion.emerald => 'Pokémon Esmeralda',
        PokemonGameVersion.fireRed => 'Pokémon Rojo Fuego',
        PokemonGameVersion.leafGreen => 'Pokémon Verde Hoja',
        _ => 'Pokémon',
      };

  String _gsMessage(CrystalGsBallStatus status) => switch (status) {
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

  String _gen3Message(Gen3SpecialEventStatus status) => switch (status) {
        Gen3SpecialEventStatus.noSave =>
          'Guarda la partida dentro del juego antes de continuar.',
        Gen3SpecialEventStatus.incompatibleSave =>
          'El guardado no tiene un formato compatible con este juego.',
        Gen3SpecialEventStatus.leagueRequired =>
          'Evento bloqueado: primero debes vencer a la Liga Pokémon y guardar la partida.',
        Gen3SpecialEventStatus.available => 'El evento está disponible.',
        Gen3SpecialEventStatus.activated =>
          'Evento activado. Las instrucciones seguirán disponibles aquí.',
        Gen3SpecialEventStatus.unsupported =>
          'Este evento no está disponible en esta edición.',
      };

  String _gsStatusLabel(CrystalGsBallStatus? status) => switch (status) {
        null => 'Comprobando',
        CrystalGsBallStatus.noSave => 'Sin guardado',
        CrystalGsBallStatus.incompatibleSave => 'No compatible',
        CrystalGsBallStatus.leagueRequired => 'Bloqueado',
        CrystalGsBallStatus.available => 'Disponible',
        CrystalGsBallStatus.activated => 'Activado',
      };

  String _gen3StatusLabel(Gen3SpecialEventStatus? status) => switch (status) {
        null => 'Comprobando',
        Gen3SpecialEventStatus.noSave => 'Sin guardado',
        Gen3SpecialEventStatus.incompatibleSave => 'No compatible',
        Gen3SpecialEventStatus.leagueRequired => 'Bloqueado',
        Gen3SpecialEventStatus.available => 'Disponible',
        Gen3SpecialEventStatus.activated => 'Activado',
        Gen3SpecialEventStatus.unsupported => 'No disponible',
      };
}

class _EventPresentation {
  final Gen3SpecialEvent event;
  final String title;
  final String game;
  final List<String> instructions;

  const _EventPresentation({
    required this.event,
    required this.title,
    required this.game,
    required this.instructions,
  });
}

class _EventCard extends StatelessWidget {
  final String title;
  final String game;
  final String statusLabel;
  final String? statusMessage;
  final bool canActivate;
  final bool working;
  final VoidCallback onActivate;
  final List<String> instructions;

  const _EventCard({
    required this.title,
    required this.game,
    required this.statusLabel,
    required this.statusMessage,
    required this.canActivate,
    required this.working,
    required this.onActivate,
    required this.instructions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.auto_awesome)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      Text(game),
                    ],
                  ),
                ),
                Chip(label: Text(statusLabel)),
              ],
            ),
            const SizedBox(height: 18),
            const Text('Requisito', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Haber vencido a la Liga Pokémon.'),
            const SizedBox(height: 18),
            const Text(
              'Después de activar el evento',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            for (var index = 0; index < instructions.length; index++)
              _Instruction(number: index + 1, text: instructions[index]),
            const SizedBox(height: 8),
            if (statusMessage == null)
              const Center(child: CircularProgressIndicator())
            else ...[
              Text(
                statusMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (canActivate) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: working ? null : onActivate,
                    icon: working
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.lock_open),
                    label: const Text('Activar evento'),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
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
