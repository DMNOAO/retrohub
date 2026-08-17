import 'package:flutter/material.dart';

import '../../core/assets/game_asset_profile.dart';
import '../../core/assets/sprite_image.dart';
import '../../core/assets/sprite_resolver.dart';
import '../pokemon/decoder/pokemon_decoder.dart';

class PokedexDetailPage extends StatelessWidget {
  final GameAssetProfile profile;
  final int pokemonId;
  final int displayNumber;
  final bool caught;

  const PokedexDetailPage({
    super.key,
    required this.profile,
    required this.pokemonId,
    required this.displayNumber,
    required this.caught,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = PokemonDecoder.pokemonName(pokemonId);

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('#${displayNumber.toString().padLeft(3, '0')}', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  SpriteImage(
                    path: SpriteResolver.pokemonForGame(profile: profile, pokemonId: pokemonId),
                    size: 112,
                    fallbackIcon: Icons.catching_pokemon,
                  ),
                  const SizedBox(height: 12),
                  Text(name, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Chip(
                    avatar: Icon(caught ? Icons.catching_pokemon : Icons.visibility_outlined, size: 18),
                    label: Text(caught ? 'Capturado' : 'Visto'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _Section(
            icon: Icons.location_on_outlined,
            title: 'Dónde encontrarlo',
            child: const Text('Los lugares, método de encuentro y horario (mañana, día o noche) se mostrarán aquí según la versión del juego.'),
          ),
          const SizedBox(height: 12),
          _LockedSection(
            icon: Icons.menu_book_outlined,
            title: 'Entrada de la Pokédex',
            unlocked: caught,
            unlockedText: 'Entrada desbloqueada. Los textos específicos de cada versión se incorporarán al catálogo de datos de RetroHub.',
          ),
          const SizedBox(height: 12),
          _LockedSection(
            icon: Icons.auto_awesome_outlined,
            title: 'Sprite shiny',
            unlocked: caught,
            unlockedText: 'Vista shiny desbloqueada. El sprite correspondiente a esta generación se mostrará aquí.',
          ),
          const SizedBox(height: 12),
          _LockedSection(
            icon: Icons.trending_up,
            title: 'Movimientos por nivel',
            unlocked: caught,
            unlockedText: 'Los movimientos aprendidos por nivel se mostrarán aquí según la versión del juego.',
          ),
          const SizedBox(height: 12),
          _LockedSection(
            icon: Icons.album_outlined,
            title: 'MT / MO',
            unlocked: caught,
            unlockedText: 'Las MT y MO compatibles se mostrarán aquí según la generación.',
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _Section({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon), const SizedBox(width: 10), Text(title, style: Theme.of(context).textTheme.titleMedium)]),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _LockedSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool unlocked;
  final String unlockedText;

  const _LockedSection({required this.icon, required this.title, required this.unlocked, required this.unlockedText});

  @override
  Widget build(BuildContext context) {
    return _Section(
      icon: unlocked ? icon : Icons.lock_outline,
      title: title,
      child: Text(unlocked ? unlockedText : 'Captura este Pokémon para desbloquear esta información.'),
    );
  }
}
