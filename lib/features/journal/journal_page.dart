import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/assets/badge_asset_resolver.dart';
import '../../core/assets/game_asset_profile.dart';
import '../../core/assets/sprite_image.dart';
import '../../core/assets/sprite_resolver.dart';
import '../../data/database/app_database.dart';
import '../../data/database/database_provider.dart';
import '../../shared/theme/app_appearance.dart';
import '../pokemon/decoder/move_name_resolver.dart';
import '../pokemon/decoder/move_type_resolver.dart';
import 'journal_history_page.dart';

class JournalPage extends ConsumerStatefulWidget {
  final Game game;

  const JournalPage({super.key, required this.game});

  @override
  ConsumerState<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends ConsumerState<JournalPage> {
  late final AppDatabase _database;
  GameProgressSnapshot? _snapshot;
  Game? _game;
  bool _isLoading = true;
  bool _showKantoReveal = false;

  @override
  void initState() {
    super.initState();
    _database = ref.read(databaseProvider);
    _game = widget.game;
    _loadSnapshot();
  }

  Future<void> _loadSnapshot() async {
    final currentGame =
        await _database.getGameById(widget.game.id) ?? widget.game;
    final snapshot = await _database.getLatestProgressSnapshot(widget.game.id);
    final events = await _database.getProgressEventsByGame(widget.game.id);
    final now = DateTime.now();
    final hasRecentKantoUnlock = events.any(
      (event) =>
          event.eventType == 'kanto_unlocked' &&
          now.difference(event.createdAt).abs() <= const Duration(minutes: 20),
    );
    if (!mounted) return;
    setState(() {
      _game = currentGame;
      _snapshot = snapshot;
      _showKantoReveal = hasRecentKantoUnlock;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _decodeList(String? jsonText) {
    if (jsonText == null || jsonText.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final game = _game ?? widget.game;
    final journalAppearance = AppAppearance.forGameTitle(game.title);
    final journal = Scaffold(
      appBar: AppBar(
        title: const Text('Bitácora'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () {
              setState(() => _isLoading = true);
              _loadSnapshot();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _snapshot == null
          ? _EmptyJournal(gameTitle: game.title)
          : _ProgressJournal(
              game: game,
              snapshot: _snapshot!,
              decodeList: _decodeList,
              showKantoReveal: _showKantoReveal,
            ),
    );
    if (journalAppearance == null) return journal;
    return Theme(data: journalAppearance.theme, child: journal);
  }
}

class _EmptyJournal extends StatelessWidget {
  final String gameTitle;
  const _EmptyJournal({required this.gameTitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.menu_book_outlined, size: 64),
              const SizedBox(height: 16),
              Text(gameTitle, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text(
                'Aún no hay progreso detectado. Abre la partida durante unos segundos para que RetroHub cree el primer registro.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressJournal extends StatelessWidget {
  final Game game;
  final GameProgressSnapshot snapshot;
  final List<Map<String, dynamic>> Function(String?) decodeList;
  final bool showKantoReveal;

  const _ProgressJournal({
    required this.game,
    required this.snapshot,
    required this.decodeList,
    required this.showKantoReveal,
  });

  int? _intValue(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  bool _boolValue(dynamic value) =>
      value == true || value?.toString() == 'true';

  String? _pokemonSprite(
    GameAssetProfile profile,
    Map<String, dynamic>? pokemon,
  ) {
    if (_boolValue(pokemon?['isEgg'])) {
      return SpriteResolver.eggForGame(profile: profile);
    }
    final id = _intValue(pokemon?['id']);
    if (id == null || id <= 0) return null;
    return SpriteResolver.pokemonForGame(
      profile: profile,
      pokemonId: id,
      isShiny: _boolValue(pokemon?['isShiny']),
    );
  }

  static const List<int> _kantoGen2BadgeIndices = <int>[
    13, // Roca
    12, // Cascada
    8, // Trueno
    10, // Arcoíris
    11, // Alma
    9, // Pantano
    14, // Volcán
    15, // Tierra
  ];

  bool _badgeObtained(List<Map<String, dynamic>> badges, int fullIndex) {
    for (final badge in badges) {
      final index = _intValue(badge['index']);
      if (index == fullIndex) return badge['obtained'] == true;
    }
    return false;
  }

  int _countBadges(List<Map<String, dynamic>> badges, Iterable<int> indices) {
    return indices.where((index) => _badgeObtained(badges, index)).length;
  }

  @override
  Widget build(BuildContext context) {
    final profile = GameAssetProfile.fromGame(game);
    final party = decodeList(snapshot.partyJson);
    final badges = decodeList(snapshot.badgesJson);
    final isGen2 = profile.region == PokemonAssetRegion.johto;
    final johtoIndices = List<int>.generate(8, (index) => index);
    final johtoCount = _countBadges(badges, johtoIndices);
    final kantoCount = isGen2
        ? _countBadges(badges, _kantoGen2BadgeIndices)
        : 0;
    final kantoUnlocked =
        isGen2 &&
        (johtoCount == 8 || kantoCount > 0 || snapshot.leagueWins > 0);
    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.orientationOf(context) == Orientation.landscape
            ? 32
            : 24,
        vertical: 24,
      ),
      children: [
        _AdventureHeader(
          game: game,
          snapshot: snapshot,
          profile: profile,
          leadPokemon: party.isEmpty ? null : party.first,
          leadPokemonPath: party.isEmpty
              ? null
              : _pokemonSprite(profile, party.first),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => JournalHistoryPage(game: game)),
            );
          },
          icon: const Icon(Icons.auto_stories_outlined),
          label: const Text('Ver historia completa'),
        ),
        const _SectionTitle(title: 'Equipo actual'),
        if (party.isEmpty)
          const _EmptySection(
            icon: Icons.catching_pokemon,
            label: 'Sin equipo detectado.',
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth >= 900
                  ? (constraints.maxWidth - 24) / 3
                  : constraints.maxWidth >= 560
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: party.map((pokemon) {
                  final int? currentHp = _intValue(pokemon['currentHp']);
                  final int? maximumHp = _intValue(pokemon['maximumHp']);
                  final String hp = currentHp != null && maximumHp != null
                      ? ' · PS $currentHp/$maximumHp'
                      : '';
                  final bool isEgg = _boolValue(pokemon['isEgg']);
                  final int? friendship = _intValue(pokemon['friendship']);
                  final String friendshipDetail = friendship == null
                      ? ''
                      : ' · ♥ $friendship/255';
                  final int? eggStepsCurrent = _intValue(pokemon['eggStepsCurrent']);
                  final int? eggStepsTotal = _intValue(pokemon['eggStepsTotal']);
                  final String eggDetail =
                      eggStepsCurrent != null && eggStepsTotal != null
                      ? '🥚 $eggStepsCurrent/$eggStepsTotal pasos'
                      : 'Pokémon por eclosionar';
                  return SizedBox(
                    width: width,
                    child: _PokemonTile(
                      name: isEgg
                          ? 'Huevo'
                          : (pokemon['name']?.toString() ?? 'Pokémon'),
                      detail: isEgg
                          ? eggDetail
                          : 'Nivel ${pokemon['level'] ?? '—'}$hp$friendshipDetail',
                      spritePath: _pokemonSprite(profile, pokemon),
                      shiny: _boolValue(pokemon['isShiny']),
                      onTap: () => _showPokemonDetails(
                        context,
                        pokemon: pokemon,
                        spritePath: _pokemonSprite(profile, pokemon),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        if (isGen2) ...[
          _SectionTitle(title: 'Medallas de Johto $johtoCount/8'),
          _BadgeGrid(
            region: PokemonAssetRegion.johto,
            badges: badges,
            badgeIndices: johtoIndices,
          ),
          if (kantoUnlocked)
            _KantoUnlockSection(
              badges: badges,
              badgeIndices: _kantoGen2BadgeIndices,
              kantoCount: kantoCount,
              celebrate: showKantoReveal,
            ),
        ] else ...[
          _SectionTitle(title: 'Medallas ${snapshot.badgesCount}/8'),
          _BadgeGrid(
            region: profile.region,
            badges: badges,
            badgeIndices: List<int>.generate(8, (index) => index),
          ),
        ],
        const SizedBox(height: 28),
      ],
    );
  }

  void _showPokemonDetails(
    BuildContext context, {
    required Map<String, dynamic> pokemon,
    required String? spritePath,
  }) {
    final bool isEgg = _boolValue(pokemon['isEgg']);
    final List<int> moves = (pokemon['moveIds'] as List<dynamic>? ?? const [])
        .map(_intValue)
        .whereType<int>()
        .where((move) => move > 0)
        .toList();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: _ThemedSpriteFrame(
                  spritePath: spritePath,
                  size: 104,
                  fallbackIcon: isEgg ? Icons.egg_outlined : Icons.catching_pokemon,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isEgg ? 'Huevo' : (pokemon['name']?.toString() ?? 'Pokémon'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              if (!isEgg) ...[
                _PokemonDetailRow(label: 'Nivel', value: '${pokemon['level'] ?? '—'}'),
                _PokemonDetailRow(
                  label: 'Experiencia',
                  value: '${pokemon['experience'] ?? 'No disponible'}',
                ),
                _PokemonDetailRow(
                  label: 'Amistad',
                  value: pokemon['friendship'] == null
                      ? 'No disponible'
                      : '${pokemon['friendship']}/255',
                ),
                _PokemonDetailRow(
                  label: 'Puntos de salud',
                  value: pokemon['currentHp'] == null || pokemon['maximumHp'] == null
                      ? 'No disponible'
                      : '${pokemon['currentHp']}/${pokemon['maximumHp']}',
                ),
                if (_boolValue(pokemon['isShiny']))
                  const _PokemonDetailRow(label: 'Variocolor', value: 'Sí ✨'),
                if (pokemon['nickname']?.toString().trim().isNotEmpty == true)
                  _PokemonDetailRow(
                    label: 'Apodo',
                    value: pokemon['nickname'].toString(),
                  ),
                const SizedBox(height: 16),
                Text('Movimientos', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (moves.isEmpty)
                  const Text('Se mostrarán después de volver a abrir la partida.')
                else
                  ...moves.map(
                    (move) => _MoveTile(
                      name: MoveNameResolver.resolve(move),
                      type: MoveTypeResolver.resolve(move),
                    ),
                  ),
              ] else
                _PokemonDetailRow(
                  label: 'Eclosión',
                  value: pokemon['eggStepsCurrent'] == null || pokemon['eggStepsTotal'] == null
                      ? 'Progreso no disponible'
                      : '${pokemon['eggStepsCurrent']}/${pokemon['eggStepsTotal']} pasos',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdventureHeader extends StatelessWidget {
  final Game game;
  final GameProgressSnapshot snapshot;
  final GameAssetProfile profile;
  final Map<String, dynamic>? leadPokemon;
  final String? leadPokemonPath;

  const _AdventureHeader({
    required this.game,
    required this.snapshot,
    required this.profile,
    required this.leadPokemon,
    required this.leadPokemonPath,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 84,
            height: 84,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SpriteImage(
              path: profile.protagonistAsset,
              size: 68,
              fallbackIcon: Icons.person_outline,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 5),
                Text(snapshot.currentLocation ?? 'Aventura en progreso'),
                const SizedBox(height: 8),
                Text('${snapshot.pokedexCaught} capturados'),
              ],
            ),
          ),
          if (leadPokemon != null)
            Column(
              children: [
                SpriteImage(
                  path: leadPokemonPath,
                  size: 70,
                  fallbackIcon: Icons.catching_pokemon,
                ),
                Text(
                  'Nv. ${leadPokemon!['level'] ?? '—'}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _KantoUnlockSection extends StatefulWidget {
  final List<Map<String, dynamic>> badges;
  final List<int> badgeIndices;
  final int kantoCount;
  final bool celebrate;

  const _KantoUnlockSection({
    required this.badges,
    required this.badgeIndices,
    required this.kantoCount,
    required this.celebrate,
  });

  @override
  State<_KantoUnlockSection> createState() => _KantoUnlockSectionState();
}

class _KantoUnlockSectionState extends State<_KantoUnlockSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  bool _showBadges = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(
      begin: .92,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (widget.celebrate) {
        await _controller.forward();
        await Future<void>.delayed(const Duration(milliseconds: 950));
      }
      if (mounted) setState(() => _showBadges = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.celebrate && !_showBadges)
          FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Container(
                margin: const EdgeInsets.only(top: 24),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      scheme.primaryContainer,
                      scheme.surfaceContainerHighest,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: .55),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: .18),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(Icons.public, size: 54, color: scheme.primary),
                    const SizedBox(height: 14),
                    Text(
                      'Nueva región desbloqueada',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'KANTO',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            color: scheme.primary,
                          ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'La aventura continúa. Ocho nuevas medallas te esperan.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 650),
          switchInCurve: Curves.easeOutCubic,
          child: _showBadges
              ? Column(
                  key: const ValueKey<String>('kanto-badges'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionTitle(
                      title: 'Medallas de Kanto ${widget.kantoCount}/8',
                    ),
                    _BadgeGrid(
                      region: PokemonAssetRegion.kanto,
                      badges: widget.badges,
                      badgeIndices: widget.badgeIndices,
                    ),
                  ],
                )
              : const SizedBox.shrink(key: ValueKey<String>('kanto-hidden')),
        ),
      ],
    );
  }
}

class _BadgeGrid extends StatelessWidget {
  final PokemonAssetRegion region;
  final List<Map<String, dynamic>> badges;
  final List<int> badgeIndices;

  const _BadgeGrid({
    required this.region,
    required this.badges,
    required this.badgeIndices,
  });

  bool _isObtained(int fullIndex) {
    for (final badge in badges) {
      final rawIndex = badge['index'];
      final index = rawIndex is int ? rawIndex : int.tryParse('$rawIndex');
      if (index == fullIndex) return badge['obtained'] == true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final columns = compact ? 4 : 8;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: badgeIndices.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: compact ? 6 : 10,
            crossAxisSpacing: compact ? 6 : 10,
            childAspectRatio: compact ? .82 : .95,
          ),
          itemBuilder: (context, visualIndex) {
            final fullIndex = badgeIndices[visualIndex];
            final obtained = _isObtained(fullIndex);
            final asset = BadgeAssetResolver.resolveForRegion(
              region,
              visualIndex,
            );
            return AnimatedOpacity(
              duration: const Duration(milliseconds: 280),
              opacity: obtained ? 1 : .34,
              child: Card(
                child: Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(compact ? 5 : 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SpriteImage(
                            path: asset.path,
                            size: compact ? 38 : 54,
                            fallbackIcon: Icons.workspace_premium_outlined,
                          ),
                          SizedBox(height: compact ? 4 : 7),
                          Text(
                            asset.displayName,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: compact
                                ? Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(fontSize: 10.5, height: 1.05)
                                : null,
                          ),
                        ],
                      ),
                    ),
                    if (obtained)
                      Positioned(
                        top: compact ? 3 : 6,
                        right: compact ? 3 : 6,
                        child: Icon(
                          Icons.check_circle,
                          size: compact ? 14 : 17,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PokemonTile extends StatelessWidget {
  final String name;
  final String detail;
  final String? spritePath;
  final bool shiny;
  final VoidCallback? onTap;
  const _PokemonTile({
    required this.name,
    required this.detail,
    required this.spritePath,
    required this.shiny,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: _ThemedSpriteFrame(
          spritePath: spritePath,
          size: 62,
          fallbackIcon: Icons.catching_pokemon,
        ),
        title: Row(
          children: [
            Expanded(child: Text(name)),
            if (shiny) const Text('✨', semanticsLabel: 'Shiny'),
          ],
        ),
        subtitle: Text(detail),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _ThemedSpriteFrame extends StatelessWidget {
  final String? spritePath;
  final double size;
  final IconData fallbackIcon;

  const _ThemedSpriteFrame({
    required this.spritePath,
    required this.size,
    required this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: .22),
            blurRadius: 8,
          ),
        ],
      ),
      child: SpriteImage(
        path: spritePath,
        size: size - 10,
        fallbackIcon: fallbackIcon,
      ),
    );
  }
}

class _PokemonDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _PokemonDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

class _MoveTile extends StatelessWidget {
  final String name;
  final PokemonMoveType type;

  const _MoveTile({required this.name, required this.type});

  @override
  Widget build(BuildContext context) {
    final visual = _MoveTypeVisual.forType(type);
    return Container(
      height: 64,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: visual.color, width: 2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 14,
            child: _MoveTypeBadge(visual: visual),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 62),
            child: Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoveTypeBadge extends StatelessWidget {
  final _MoveTypeVisual visual;

  const _MoveTypeBadge({required this.visual});

  @override
  Widget build(BuildContext context) {
    final foreground = visual.color.computeLuminance() > .55
        ? Colors.black87
        : Colors.white;
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(color: visual.color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: visual.emoji != null
          ? Text(visual.emoji!, style: const TextStyle(fontSize: 21))
          : Icon(visual.icon, size: 22, color: foreground),
    );
  }
}

class _MoveTypeVisual {
  final Color color;
  final IconData icon;
  final String? emoji;

  const _MoveTypeVisual(this.color, this.icon, {this.emoji});

  static _MoveTypeVisual forType(PokemonMoveType type) => switch (type) {
    PokemonMoveType.normal =>
      const _MoveTypeVisual(Color(0xFFA8A878), Icons.circle_outlined),
    PokemonMoveType.fire => const _MoveTypeVisual(
      Color(0xFFF08030),
      Icons.local_fire_department,
    ),
    PokemonMoveType.water =>
      const _MoveTypeVisual(Color(0xFF6890F0), Icons.water_drop),
    PokemonMoveType.electric =>
      const _MoveTypeVisual(Color(0xFFF8D030), Icons.bolt),
    PokemonMoveType.grass =>
      const _MoveTypeVisual(Color(0xFF78C850), Icons.eco),
    PokemonMoveType.ice =>
      const _MoveTypeVisual(Color(0xFF98D8D8), Icons.ac_unit),
    PokemonMoveType.fighting =>
      const _MoveTypeVisual(Color(0xFFC03028), Icons.sports_mma),
    PokemonMoveType.poison =>
      const _MoveTypeVisual(Color(0xFFA040A0), Icons.science),
    PokemonMoveType.ground =>
      const _MoveTypeVisual(Color(0xFFE0C068), Icons.landscape),
    PokemonMoveType.flying =>
      const _MoveTypeVisual(Color(0xFFA890F0), Icons.air),
    PokemonMoveType.psychic =>
      const _MoveTypeVisual(Color(0xFFF85888), Icons.visibility),
    PokemonMoveType.bug =>
      const _MoveTypeVisual(Color(0xFFA8B820), Icons.pest_control),
    PokemonMoveType.rock =>
      const _MoveTypeVisual(Color(0xFFB8A038), Icons.terrain),
    PokemonMoveType.ghost =>
      const _MoveTypeVisual(Color(0xFF705898), Icons.blur_on),
    PokemonMoveType.dragon => const _MoveTypeVisual(
      Color(0xFF7038F8),
      Icons.pets,
      emoji: '🐉',
    ),
    PokemonMoveType.dark =>
      const _MoveTypeVisual(Color(0xFF705848), Icons.dark_mode),
    PokemonMoveType.steel =>
      const _MoveTypeVisual(Color(0xFFB8B8D0), Icons.settings),
    PokemonMoveType.unknown =>
      const _MoveTypeVisual(Color(0xFF686868), Icons.question_mark),
  };
}

class _EmptySection extends StatelessWidget {
  final IconData icon;
  final String label;
  const _EmptySection({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(leading: Icon(icon), title: Text(label)),
  );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}
