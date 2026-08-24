import 'package:flutter/material.dart';

import '../../core/assets/game_asset_profile.dart';
import '../../core/assets/sprite_image.dart';
import '../../core/assets/sprite_resolver.dart';
import '../pokemon/decoder/machine_move_resolver.dart';
import '../pokemon/decoder/move_name_resolver.dart';
import '../pokemon/decoder/move_type_resolver.dart';
import '../pokemon/decoder/pokemon_type_resolver.dart';
import '../pokemon/decoder/pokemon_ability_resolver.dart';
import '../pokemon/decoder/pokemon_decoder.dart';
import '../pokemon/decoder/pokemon_learnset_resolver.dart';
import 'data/pokedex_detail_data.dart';
import 'data/pokedex_evolution_data.dart';
import 'widgets/move_type_tile.dart';

class PokedexDetailPage extends StatefulWidget {
  final GameAssetProfile profile;
  final int pokemonId;
  final int displayNumber;
  final bool caught;
  final List<int> availableIds;
  final Set<int> caughtIds;
  final List<int> dexOrder;

  const PokedexDetailPage({super.key, required this.profile, required this.pokemonId, required this.displayNumber, required this.caught, this.availableIds = const <int>[], this.caughtIds = const <int>{}, this.dexOrder = const <int>[]});

  @override
  State<PokedexDetailPage> createState() => _PokedexDetailPageState();
}

class _PokedexDetailPageState extends State<PokedexDetailPage> {
  late int _pokemonId;
  bool _showShiny = false;
  bool get _supportsShiny => widget.profile.game != PokemonAssetGame.redBlue && widget.profile.game != PokemonAssetGame.yellow;

  @override
  void initState() { super.initState(); _pokemonId = widget.pokemonId; }

  int get _displayNumber {
    if (widget.dexOrder.isEmpty) return _pokemonId == widget.pokemonId ? widget.displayNumber : _pokemonId;
    final index = widget.dexOrder.indexOf(_pokemonId);
    return index >= 0 ? index + 1 : _pokemonId;
  }

  bool get _caught => _pokemonId == widget.pokemonId ? widget.caught : widget.caughtIds.contains(_pokemonId);

  void _move(int direction) {
    if (widget.availableIds.isEmpty) return;
    final index = widget.availableIds.indexOf(_pokemonId);
    if (index < 0) return;
    final next = index + direction;
    if (next < 0 || next >= widget.availableIds.length) return;
    setState(() { _pokemonId = widget.availableIds[next]; _showShiny = false; });
  }

  @override
  Widget build(BuildContext context) {
    final data = PokedexDetailData.forGame(widget.profile, _pokemonId);
    final evolution = PokedexEvolutionData.forGame(widget.profile, _pokemonId);
    final evolutionOptions = evolution.split('\n');
    final abilities = PokemonAbilityResolver.possible(
      widget.profile,
      _pokemonId,
    );
    final tutorMoves = PokemonLearnsetResolver.tutorMoves(
      widget.profile,
      _pokemonId,
    );
    final eggMoves = PokemonLearnsetResolver.eggMoves(
      widget.profile,
      _pokemonId,
    );
    final eggBaseId = PokemonLearnsetResolver.baseSpeciesId(
      widget.profile,
      _pokemonId,
    );
    final machineMoves = data.machineMoves.where((move) {
      final moveId = MoveNameResolver.idForName(move.name);
      return moveId == null ||
          MachineMoveResolver.label(widget.profile, moveId) != 'Tutor';
    }).toList(growable: false);
    final name = PokemonDecoder.pokemonName(_pokemonId);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: (details) { final velocity = details.primaryVelocity ?? 0; if (velocity < -250) { _move(1); } else if (velocity > 250) { _move(-1); } },
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
            Text('#${_displayNumber.toString().padLeft(3, '0')}', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: scheme.primary, width: 3)), child: SpriteImage(path: SpriteResolver.pokemonForGame(profile: widget.profile, pokemonId: _pokemonId, isShiny: _supportsShiny && _showShiny), size: 112, fallbackIcon: Icons.catching_pokemon)),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(name, style: Theme.of(context).textTheme.headlineSmall),
              PokemonTypeIcons(
                types: PokemonTypeResolver.resolve(widget.profile, _pokemonId),
                size: 27,
              ),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 8, alignment: WrapAlignment.center, children: [Chip(avatar: Icon(_caught ? Icons.catching_pokemon : Icons.visibility_outlined, size: 18), label: Text(_caught ? 'Capturado' : 'Visto')), if (_caught && _supportsShiny) FilterChip(selected: _showShiny, avatar: const Icon(Icons.auto_awesome, size: 18), label: const Text('Shiny'), onSelected: (value) => setState(() => _showShiny = value))]),
          ]))),
          const SizedBox(height: 12),
          _ExpandableSection(
            storageKey: 'pokedex-entry',
            icon: Icons.menu_book_outlined,
            title: 'Entrada de la Pokédex',
            unlocked: _caught,
            child: data.entry.isEmpty
                ? const Text('Entrada aún no cargada para esta especie.')
                : Text(data.entry),
          ),
          _ExpandableSection(
            storageKey: 'pokedex-evolution',
            icon: Icons.change_circle_outlined,
            title: 'Evolución',
            child: evolution.isEmpty
                ? const Text('Este Pokémon no tiene una evolución registrada.')
                : evolutionOptions.length == 1
                ? Text(evolution)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: evolutionOptions
                        .map(
                          (option) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('• $option'),
                          ),
                        )
                        .toList(),
                  ),
          ),
          if (PokemonAbilityResolver.supports(widget.profile))
            _ExpandableSection(
              storageKey: 'pokedex-abilities',
              icon: Icons.auto_awesome_outlined,
              title: 'Habilidades posibles',
              unlocked: _caught,
              child: abilities.isEmpty
                  ? const Text('No hay habilidades cargadas para esta especie.')
                  : Column(
                      children: abilities
                          .map(
                            (ability) => _AbilityCard(ability: ability),
                          )
                          .toList(),
                    ),
            ),
          _ExpandableSection(
            storageKey: 'pokedex-encounters',
            icon: Icons.location_on_outlined,
            title: 'Dónde encontrarlo',
            child: data.encounters.isEmpty
                ? const Text(
                    'Datos de encuentro aún no cargados para esta especie.',
                  )
                : Column(
                    children: data.encounters
                        .map(
                          (e) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.place_outlined),
                            title: Text(e.location),
                            subtitle: Text('${e.method} · ${e.time}'),
                          ),
                        )
                        .toList(),
                  ),
          ),
          _ExpandableSection(icon: Icons.trending_up, storageKey: 'pokedex-level', title: 'Movimientos por nivel', unlocked: _caught, child: data.levelMoves.isEmpty ? const Text('Movimientos aún no cargados para esta especie.') : Column(children: data.levelMoves.map((m) {
            final moveId = MoveNameResolver.idForName(m.name);
            return MoveTypeTile(
              profile: widget.profile,
              moveId: moveId,
              leadingLabel: 'Nv. ${m.level}',
              name: m.name,
              type: moveId == null
                  ? PokemonMoveType.unknown
                  : MoveTypeResolver.resolve(moveId),
            );
          }).toList())),
          _ExpandableSection(icon: Icons.album_outlined, storageKey: 'pokedex-machines', title: 'MT / MO', unlocked: _caught, child: machineMoves.isEmpty ? const Text('MT/MO aún no cargadas para esta especie.') : Column(children: machineMoves.map((m) {
            final moveId = MoveNameResolver.idForName(m.name);
            final machine = moveId == null
                ? m.machine
                : MachineMoveResolver.label(widget.profile, moveId) ?? m.machine;
            return MoveTypeTile(
              profile: widget.profile,
              moveId: moveId,
              leadingLabel: machine,
              name: m.name,
              type: moveId == null
                  ? PokemonMoveType.unknown
                  : MoveTypeResolver.resolve(moveId),
            );
          }).toList())),
          if (tutorMoves.isNotEmpty)
            _ExpandableSection(
              icon: Icons.school_outlined,
              storageKey: 'pokedex-tutor',
              title: 'Movimientos de tutor',
              unlocked: _caught,
              child: Column(
                children: tutorMoves
                    .map(
                      (moveId) => MoveTypeTile(
                        profile: widget.profile,
                        moveId: moveId,
                        leadingLabel: 'Tutor',
                        name: MoveNameResolver.resolve(moveId),
                        type: MoveTypeResolver.resolve(moveId),
                      ),
                    )
                    .toList(),
              ),
            ),
          if (eggMoves.isNotEmpty)
            _ExpandableSection(
              icon: Icons.egg_outlined,
              storageKey: 'pokedex-egg-moves',
              title: eggBaseId == _pokemonId
                  ? 'Movimientos huevo'
                  : 'Movimientos huevo de ${PokemonDecoder.pokemonName(eggBaseId)}',
              unlocked: _caught,
              child: Column(
                children: eggMoves
                    .map(
                      (moveId) => _EggMoveTile(
                        profile: widget.profile,
                        pokemonId: eggBaseId,
                        moveId: moveId,
                      ),
                    )
                    .toList(),
              ),
            ),
        ]),
      ),
    );
  }
}

class _ExpandableSection extends StatelessWidget {
  final String storageKey;
  final IconData icon;
  final String title;
  final bool unlocked;
  final Widget child;

  const _ExpandableSection({
    required this.storageKey,
    required this.icon,
    required this.title,
    this.unlocked = true,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    clipBehavior: Clip.antiAlias,
    child: ExpansionTile(
      key: PageStorageKey<String>(storageKey),
      leading: Icon(unlocked ? icon : Icons.lock_outline),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        unlocked
            ? child
            : const Text(
                'Captura este Pokémon para desbloquear esta información.',
              ),
      ],
    ),
  );
}

class _AbilityCard extends StatelessWidget {
  final PokemonAbilityInfo ability;
  const _AbilityCard({required this.ability});

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(top: 8),
    child: ExpansionTile(
      leading: const Icon(Icons.auto_awesome),
      title: Text(ability.name),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [Text(ability.description)],
    ),
  );
}

class _EggMoveTile extends StatefulWidget {
  final GameAssetProfile profile;
  final int pokemonId;
  final int moveId;

  const _EggMoveTile({
    required this.profile,
    required this.pokemonId,
    required this.moveId,
  });

  @override
  State<_EggMoveTile> createState() => _EggMoveTileState();
}

class _EggMoveTileState extends State<_EggMoveTile> {
  bool _showParents = false;

  @override
  Widget build(BuildContext context) {
    final parents = PokemonLearnsetResolver.eggMoveParents(
      widget.profile,
      widget.pokemonId,
      widget.moveId,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          MoveTypeTile(
            profile: widget.profile,
            moveId: widget.moveId,
            leadingLabel: 'Huevo',
            name: MoveNameResolver.resolve(widget.moveId),
            type: MoveTypeResolver.resolve(widget.moveId),
          ),
          if (parents.isNotEmpty) ...[
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _showParents = !_showParents),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.family_restroom, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Padres compatibles (${parents.length})',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _showParents ? Icons.expand_less : Icons.expand_more,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 180),
              crossFadeState: _showParents
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: parents
                      .map(
                        (pokemonId) => Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text(PokemonDecoder.pokemonName(pokemonId)),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
