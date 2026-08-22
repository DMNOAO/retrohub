import 'package:flutter/material.dart';

import '../../core/assets/game_asset_profile.dart';
import '../../core/assets/sprite_image.dart';
import '../../core/assets/sprite_resolver.dart';
import '../pokemon/decoder/pokemon_decoder.dart';
import 'data/pokedex_detail_data.dart';
import 'data/pokedex_evolution_data.dart';

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
            const SizedBox(height: 12), Text(name, style: Theme.of(context).textTheme.headlineSmall), const SizedBox(height: 8),
            Wrap(spacing: 8, alignment: WrapAlignment.center, children: [Chip(avatar: Icon(_caught ? Icons.catching_pokemon : Icons.visibility_outlined, size: 18), label: Text(_caught ? 'Capturado' : 'Visto')), if (_caught && _supportsShiny) FilterChip(selected: _showShiny, avatar: const Icon(Icons.auto_awesome, size: 18), label: const Text('Shiny'), onSelected: (value) => setState(() => _showShiny = value))]),
          ]))),
          const SizedBox(height: 12),
          _Section(icon: Icons.location_on_outlined, title: 'Dónde encontrarlo', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (data.encounters.isEmpty) const Text('Datos de encuentro aún no cargados para esta especie.') else ...data.encounters.map((e) => ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.place_outlined), title: Text(e.location), subtitle: Text('${e.method} · ${e.time}'))),
            if (evolution.isNotEmpty) ...[const Divider(height: 24), ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.change_circle_outlined), title: const Text('Evolución'), subtitle: Text(evolution))],
          ])),
          const SizedBox(height: 12),
          _LockedSection(icon: Icons.menu_book_outlined, title: 'Entrada de la Pokédex', unlocked: _caught, child: data.entry.isEmpty ? const Text('Entrada aún no cargada para esta especie.') : Text(data.entry)),
          const SizedBox(height: 12),
          _LockedSection(icon: Icons.trending_up, title: 'Movimientos por nivel', unlocked: _caught, child: data.levelMoves.isEmpty ? const Text('Movimientos aún no cargados para esta especie.') : Column(children: data.levelMoves.map((m) => ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: Text('Nv. ${m.level}'), title: Text(m.name))).toList())),
          const SizedBox(height: 12),
          _LockedSection(icon: Icons.album_outlined, title: 'MT / MO', unlocked: _caught, child: data.machineMoves.isEmpty ? const Text('MT/MO aún no cargadas para esta especie.') : Column(children: data.machineMoves.map((m) => ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: Text(m.machine), title: Text(m.name))).toList())),
        ]),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon; final String title; final Widget child;
  const _Section({required this.icon, required this.title, required this.child});
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon), const SizedBox(width: 10), Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium))]), const SizedBox(height: 12), child])));
}

class _LockedSection extends StatelessWidget {
  final IconData icon; final String title; final bool unlocked; final Widget child;
  const _LockedSection({required this.icon, required this.title, required this.unlocked, required this.child});
  @override
  Widget build(BuildContext context) => _Section(icon: unlocked ? icon : Icons.lock_outline, title: title, child: unlocked ? child : const Text('Captura este Pokémon para desbloquear esta información.'));
}
