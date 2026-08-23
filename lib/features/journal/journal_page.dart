import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/assets/badge_asset_resolver.dart';
import '../../core/assets/character_asset_resolver.dart';
import '../../core/assets/game_asset_profile.dart';
import '../../core/assets/sprite_image.dart';
import '../../core/assets/sprite_resolver.dart';
import '../../core/utils/play_time_formatter.dart';
import '../../data/database/app_database.dart';
import '../../data/database/database_provider.dart';
import '../../shared/theme/app_appearance.dart';
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

  Map<String, dynamic>? _decodeMap(String? jsonText) {
    if (jsonText == null || jsonText.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
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
              decodeMap: _decodeMap,
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
  final Map<String, dynamic>? Function(String?) decodeMap;
  final bool showKantoReveal;

  const _ProgressJournal({
    required this.game,
    required this.snapshot,
    required this.decodeList,
    required this.decodeMap,
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
    final lastCaptured = decodeMap(snapshot.lastCapturedPokemonJson);
    final isGen2 = profile.region == PokemonAssetRegion.johto;
    final johtoIndices = List<int>.generate(8, (index) => index);
    final johtoCount = _countBadges(badges, johtoIndices);
    final kantoCount = isGen2
        ? _countBadges(badges, _kantoGen2BadgeIndices)
        : 0;
    final kantoUnlocked =
        isGen2 &&
        (johtoCount == 8 || kantoCount > 0 || snapshot.leagueWins > 0);
    final totalBadges = isGen2 ? johtoCount + kantoCount : snapshot.badgesCount;
    final badgeMaximum = kantoUnlocked ? 16 : 8;
    final badgeSummary = '$totalBadges/$badgeMaximum medallas';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _AdventureHeader(
          game: game,
          snapshot: snapshot,
          profile: profile,
          leadPokemon: party.isEmpty ? null : party.first,
          leadPokemonPath: party.isEmpty
              ? null
              : _pokemonSprite(profile, party.first),
          badgeSummary: badgeSummary,
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900
                ? 3
                : constraints.maxWidth >= 560
                ? 2
                : 1;
            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: columns == 1 ? 4.2 : 3.2,
              children: [
                _InfoCard(
                  icon: Icons.place_outlined,
                  title: 'Ubicación actual',
                  value: snapshot.currentLocation ?? 'Sin ubicación detectada',
                ),
                _InfoCard(
                  icon: Icons.schedule,
                  title: 'Tiempo jugado',
                  value: PlayTimeFormatter.fromSeconds(
                    snapshot.playTimeMinutes * 60,
                  ),
                ),
                _InfoCard(
                  icon: Icons.catching_pokemon,
                  title: 'Pokédex',
                  value:
                      '${snapshot.pokedexSeen} vistos · ${snapshot.pokedexCaught} capturados',
                ),
                _InfoCard(
                  icon: Icons.emoji_events_outlined,
                  title: 'Liga Pokémon',
                  value: '${snapshot.leagueWins} victorias',
                ),
                _InfoCard(
                  icon: Icons.sports_martial_arts,
                  title: 'Último entrenador',
                  value: snapshot.lastDefeatedTrainer ?? 'Sin registro',
                  spritePath: snapshot.lastDefeatedTrainer == null
                      ? null
                      : CharacterAssetResolver.trainerForKnownClass(
                          profile: profile,
                          trainerClass: snapshot.lastDefeatedTrainer!,
                        ),
                ),
                _InfoCard(
                  icon: Icons.workspace_premium_outlined,
                  title: 'Medallas',
                  value: '$totalBadges/$badgeMaximum obtenidas',
                ),
              ],
            );
          },
        ),
        if (lastCaptured != null) ...[
          const _SectionTitle(title: 'Última captura'),
          _PokemonTile(
            name: lastCaptured['name']?.toString() ?? 'Pokémon',
            detail: 'Nivel ${lastCaptured['level'] ?? '—'}',
            spritePath: _pokemonSprite(profile, lastCaptured),
            shiny: _boolValue(lastCaptured['isShiny']),
          ),
        ],
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
                  final int? currentHp = int.tryParse(
                    pokemon['currentHp']?.toString() ?? '',
                  );
                  final int? maximumHp = int.tryParse(
                    pokemon['maximumHp']?.toString() ?? '',
                  );
                  final String hp = currentHp != null && maximumHp != null
                      ? ' · PS $currentHp/$maximumHp'
                      : '';
                  final bool isEgg = _boolValue(pokemon['isEgg']);
                  final int? friendship = int.tryParse(
                    pokemon['friendship']?.toString() ?? '',
                  );
                  final String friendshipDetail = friendship == null
                      ? ''
                      : ' · ♥ $friendship/255';
                  final int? eggStepsCurrent = int.tryParse(
                    pokemon['eggStepsCurrent']?.toString() ?? '',
                  );
                  final int? eggStepsTotal = int.tryParse(
                    pokemon['eggStepsTotal']?.toString() ?? '',
                  );
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
                    ),
                  );
                }).toList(),
              );
            },
          ),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => JournalHistoryPage(game: game)),
            );
          },
          icon: const Icon(Icons.auto_stories_outlined),
          label: const Text('Ver historia completa'),
        ),
      ],
    );
  }
}

class _AdventureHeader extends StatelessWidget {
  final Game game;
  final GameProgressSnapshot snapshot;
  final GameAssetProfile profile;
  final Map<String, dynamic>? leadPokemon;
  final String? leadPokemonPath;
  final String badgeSummary;

  const _AdventureHeader({
    required this.game,
    required this.snapshot,
    required this.profile,
    required this.leadPokemon,
    required this.leadPokemonPath,
    required this.badgeSummary,
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
                Text('$badgeSummary · ${snapshot.pokedexCaught} capturados'),
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

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? spritePath;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    this.spritePath,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            if (spritePath == null)
              Icon(icon)
            else
              SpriteImage(path: spritePath, size: 44, fallbackIcon: icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 3),
                  Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PokemonTile extends StatelessWidget {
  final String name;
  final String detail;
  final String? spritePath;
  final bool shiny;
  const _PokemonTile({
    required this.name,
    required this.detail,
    required this.spritePath,
    required this.shiny,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: SpriteImage(
          path: spritePath,
          size: 58,
          fallbackIcon: Icons.catching_pokemon,
        ),
        title: Row(
          children: [
            Expanded(child: Text(name)),
            if (shiny) const Text('✨', semanticsLabel: 'Shiny'),
          ],
        ),
        subtitle: Text(detail),
      ),
    );
  }
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
