import 'package:flutter/material.dart';

import '../../core/assets/game_asset_profile.dart';
import '../../core/assets/sprite_image.dart';
import '../../core/assets/sprite_resolver.dart';
import '../pokemon/decoder/pokemon_decoder.dart';
import 'data/pokedex_detail_data.dart';

class PokedexDetailPage extends StatefulWidget {
  final GameAssetProfile profile;
  final int pokemonId;
  final int displayNumber;
  final bool caught;

  const PokedexDetailPage({super.key, required this.profile, required this.pokemonId, required this.displayNumber, required this.caught});

  @override
  State<PokedexDetailPage> createState() => _PokedexDetailPageState();
}

class _PokedexDetailPageState extends State<PokedexDetailPage> {
  bool _showShiny = false;

  @override
  Widget build(BuildContext context) {
    final data = PokedexDetailData.forGame(widget.profile, widget.pokemonId);
    final name = PokemonDecoder.pokemonName(widget.pokemonId);
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
          Text('#${widget.displayNumber.toString().padLeft(3, '0')}', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SpriteImage(path: SpriteResolver.pokemonForGame(profile: widget.profile, pokemonId: widget.pokemonId, isShiny: _showShiny), size: 112, fallbackIcon: Icons.catching_pokemon, removeWhiteBackground: widget.profile.region == PokemonAssetRegion.johto),
          const SizedBox(height: 12),
          Text(name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Wrap(spacing: 8, alignment: WrapAlignment.center, children: [
            Chip(avatar: Icon(widget.caught ? Icons.catching_pokemon : Icons.visibility_outlined, size: 18), label: Text(widget.caught ? 'Capturado' : 'Visto')),
            if (widget.caught) FilterChip(selected: _showShiny, avatar: const Icon(Icons.auto_awesome, size: 18), label: const Text('Shiny'), onSelected: (value) => setState(() => _showShiny = value)),
          ]),
        ]))),
        const SizedBox(height: 12),
        _Section(icon: Icons.location_on_outlined, title: 'Dónde encontrarlo', child: data.encounters.isEmpty
            ? const Text('Sin datos de encuentro registrados para esta versión.')
            : Column(children: data.encounters.map((e) => ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.place_outlined), title: Text(e.location), subtitle: Text('${e.method} · ${e.time}'))).toList())),
        const SizedBox(height: 12),
        _LockedSection(icon: Icons.menu_book_outlined, title: 'Entrada de la Pokédex', unlocked: widget.caught, child: data.entry.isEmpty ? const Text('Entrada aún no registrada en los datos locales de esta versión.') : Text(data.entry)),
        const SizedBox(height: 12),
        _LockedSection(icon: Icons.trending_up, title: 'Movimientos por nivel', unlocked: widget.caught, child: data.levelMoves.isEmpty ? const Text('Learnset aún no registrado en los datos locales de esta versión.') : Column(children: data.levelMoves.map((m) => ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: Text('Nv. ${m.level}'), title: Text(m.name))).toList())),
        const SizedBox(height: 12),
        _LockedSection(icon: Icons.album_outlined, title: 'MT / MO', unlocked: widget.caught, child: data.machineMoves.isEmpty ? const Text('MT/MO aún no registradas en los datos locales de esta versión.') : Column(children: data.machineMoves.map((m) => ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: Text(m.machine), title: Text(m.name))).toList())),
      ]),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _Section({required this.icon, required this.title, required this.child});
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon), const SizedBox(width: 10), Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium))]), const SizedBox(height: 12), child])));
}

class _LockedSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool unlocked;
  final Widget child;
  const _LockedSection({required this.icon, required this.title, required this.unlocked, required this.child});
  @override
  Widget build(BuildContext context) => _Section(icon: unlocked ? icon : Icons.lock_outline, title: title, child: unlocked ? child : const Text('Captura este Pokémon para desbloquear esta información.'));
}
