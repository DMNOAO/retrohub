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
import '../pokemon/decoder/pokemon_type_resolver.dart';
import '../pokemon/decoder/pokemon_ability_resolver.dart';
import '../pokemon/decoder/pokemon_item_resolver.dart';
import '../pokemon/decoder/pokemon_nature_resolver.dart';
import 'journal_history_page.dart';
import 'widgets/move_type_tile.dart';
import 'widgets/journal_chrome.dart';
import '../emulator/special_events/gen2_red_reward.dart';

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
  int _redVictories = 0;
  Set<String> _claimedRedRewards = const {};

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
    var redVictories = 0;
    final claimedRedRewards = <String>{};
    for (final event in events) {
      try {
        final metadata = jsonDecode(event.metadataJson ?? '');
        if (metadata is! Map) continue;
        if (event.eventType == 'trainer_defeated' &&
            metadata['trainerClassId']?.toString() == '63') {
          redVictories++;
        } else if (event.eventType == 'red_reward_received') {
          final key = metadata['rewardKey']?.toString();
          if (key != null) claimedRedRewards.add(key);
        }
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _game = currentGame;
      _snapshot = snapshot;
      _showKantoReveal = hasRecentKantoUnlock;
      _redVictories = redVictories;
      _claimedRedRewards = claimedRedRewards;
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
      appBar: JournalAppBar(
        title: 'Bitácora',
        icon: Icons.menu_book_rounded,
        onRefresh: () {
          setState(() => _isLoading = true);
          _loadSnapshot();
        },
      ),
      bottomNavigationBar: JournalSectionBar(
        sections: const [
          JournalSection('summary', 'Resumen', Icons.dashboard_outlined),
          JournalSection('history', 'Historia', Icons.auto_stories_outlined),
          JournalSection('pokemon', 'Pokedex', Icons.catching_pokemon),
        ],
        selected: 'summary',
        onSelected: (section) {
          if (section == 'summary') return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => JournalHistoryPage(
                game: game,
                initialSection: section == 'pokemon' ? 'pokemon' : 'all',
              ),
            ),
          );
        },
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
              redVictories: _redVictories,
              claimedRedRewards: _claimedRedRewards,
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
  final int redVictories;
  final Set<String> claimedRedRewards;

  const _ProgressJournal({
    required this.game,
    required this.snapshot,
    required this.decodeList,
    required this.showKantoReveal,
    required this.redVictories,
    required this.claimedRedRewards,
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
    final bool isFemale =
        badges.isNotEmpty && badges.first['playerGender'] == 'female';
    final String? protagonistPath = isFemale
        ? profile.femaleProtagonistAsset ?? profile.protagonistAsset
        : profile.protagonistAsset;
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
          protagonistPath: protagonistPath,
          leadPokemon: party.isEmpty ? null : party.first,
          leadPokemonPath: party.isEmpty
              ? null
              : _pokemonSprite(profile, party.first),
        ),
        const SizedBox(height: 8),
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
                children: party.asMap().entries.map((entry) {
                  final index = entry.key;
                  final pokemon = entry.value;
                  final int? currentHp = _intValue(pokemon['currentHp']);
                  final int? maximumHp = _intValue(pokemon['maximumHp']);
                  final String hp = currentHp != null && maximumHp != null
                      ? 'PS $currentHp/$maximumHp'
                      : '';
                  final bool isEgg = _boolValue(pokemon['isEgg']);
                  final int? friendship = _intValue(pokemon['friendship']);
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
                          : 'Nivel ${pokemon['level'] ?? '—'}',
                      hpDetail: isEgg ? null : hp,
                      friendship: isEgg ? null : friendship,
                      spritePath: _pokemonSprite(profile, pokemon),
                      shiny: _boolValue(pokemon['isShiny']),
                      types: isEgg
                          ? const []
                          : PokemonTypeResolver.resolve(
                              profile,
                              _intValue(pokemon['id']) ?? 0,
                            ),
                      onTap: () => _showPokemonDetails(
                        context,
                        party: party,
                        initialIndex: index,
                        pokemon: pokemon,
                        spritePath: _pokemonSprite(profile, pokemon),
                        profile: profile,
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
          _RedChallengeSection(
            profile: profile,
            victories: redVictories,
            claimedRewards: claimedRedRewards,
          ),
        ] else ...[
          _SectionTitle(title: 'Medallas ${snapshot.badgesCount}/8'),
          _BadgeGrid(
            region: profile.region,
            profile: profile,
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
    required List<Map<String, dynamic>> party,
    required int initialIndex,
    required Map<String, dynamic> pokemon,
    required String? spritePath,
    required GameAssetProfile profile,
  }) {
    final bool isEgg = _boolValue(pokemon['isEgg']);
    final List<int> moves = (pokemon['moveIds'] as List<dynamic>? ?? const [])
        .map(_intValue)
        .whereType<int>()
        .where((move) => move > 0)
        .toList();
    final pokemonId = _intValue(pokemon['id']) ?? 0;
    final ability = PokemonAbilityResolver.current(
      profile,
      pokemonId,
      _intValue(pokemon['abilitySlot']) ?? 1,
    );
    final personality = _intValue(pokemon['personality']);
    final nature = personality == null
        ? null
        : PokemonNatureResolver.resolve(personality);
    final heldItem = PokemonItemResolver.resolve(
      profile,
      _intValue(pokemon['heldItemId']) ?? 0,
    );
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          final direction = velocity < -250 ? 1 : velocity > 250 ? -1 : 0;
          final nextIndex = initialIndex + direction;
          if (direction == 0 || nextIndex < 0 || nextIndex >= party.length) return;
          Navigator.of(sheetContext).pop();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            final nextPokemon = party[nextIndex];
            _showPokemonDetails(
              context,
              party: party,
              initialIndex: nextIndex,
              pokemon: nextPokemon,
              spritePath: _pokemonSprite(profile, nextPokemon),
              profile: profile,
            );
          });
        },
        child: SafeArea(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      isEgg
                          ? 'Huevo'
                          : (pokemon['name']?.toString() ?? 'Pokémon'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  if (!isEgg)
                    PokemonTypeIcons(
                      types: PokemonTypeResolver.resolve(
                        profile,
                        _intValue(pokemon['id']) ?? 0,
                      ),
                      size: 26,
                    ),
                  if (!isEgg && _boolValue(pokemon['isShiny']))
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Text('✨', semanticsLabel: 'Variocolor'),
                    ),
                ],
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
                if (pokemon['nickname']?.toString().trim().isNotEmpty == true)
                  _PokemonDetailRow(
                    label: 'Apodo',
                    value: pokemon['nickname'].toString(),
                  ),
                if (ability != null)
                  _PokemonDetailRow(label: 'Habilidad', value: ability.name),
                if (nature != null)
                  _PokemonDetailRow(
                    label: 'Naturaleza',
                    value: '${nature.name} (${nature.effect})',
                  ),
                if (heldItem != null)
                  _PokemonDetailRow(label: 'Objeto', value: heldItem),
                const SizedBox(height: 16),
                Text(
                  'Estadísticas',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _PokemonStatsGrid(pokemon: pokemon),
                const SizedBox(height: 16),
                Text('Movimientos', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (moves.isEmpty)
                  const Text('Se mostrarán después de volver a abrir la partida.')
                else
                  ...moves.map(
                    (move) => MoveTypeTile(
                      profile: profile,
                      moveId: move,
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
    ),
    );
  }
}

class _RedChallengeSection extends StatelessWidget {
  final GameAssetProfile profile;
  final int victories;
  final Set<String> claimedRewards;

  const _RedChallengeSection({
    required this.profile,
    required this.victories,
    required this.claimedRewards,
  });

  @override
  Widget build(BuildContext context) {
    final completed = victories.clamp(0, Gen2RedReward.values.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const _SectionTitle(title: 'Enfrentamientos contra Rojo'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$victories victorias · $completed/10 premios desbloqueados'),
                const SizedBox(height: 10),
                LinearProgressIndicator(value: completed / 10),
                const SizedBox(height: 12),
                ...Gen2RedReward.values.map((reward) {
                  final unlocked = victories >= reward.requiredVictories;
                  final claimed = claimedRewards.contains(reward.eventKey);
                  final sprite = SpriteResolver.pokemonForGame(
                    profile: profile,
                    pokemonId: reward.speciesId,
                    isShiny: true,
                  );
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Opacity(
                      opacity: unlocked ? 1 : .35,
                      child: SpriteImage(path: sprite, size: 48),
                    ),
                    title: Text('${reward.requiredVictories} victoria${reward.requiredVictories == 1 ? '' : 's'} · ${reward.name} variocolor'),
                    subtitle: Text(claimed
                        ? 'Premio recibido'
                        : unlocked
                        ? 'Disponible en Eventos especiales'
                        : 'Bloqueado'),
                    trailing: Icon(
                      claimed
                          ? Icons.check_circle
                          : unlocked
                          ? Icons.card_giftcard
                          : Icons.lock_outline,
                      color: claimed ? Colors.green : null,
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AdventureHeader extends StatelessWidget {
  final Game game;
  final GameProgressSnapshot snapshot;
  final GameAssetProfile profile;
  final String? protagonistPath;
  final Map<String, dynamic>? leadPokemon;
  final String? leadPokemonPath;

  const _AdventureHeader({
    required this.game,
    required this.snapshot,
    required this.profile,
    required this.protagonistPath,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              game.title,
              maxLines: 1,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 16),
          Row(
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
                  path: protagonistPath,
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
                      snapshot.currentLocation ?? 'Aventura en progreso',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('${snapshot.pokedexCaught} capturados'),
                  ],
                ),
              ),
              if (leadPokemon != null) ...[
                const SizedBox(width: 12),
                Column(
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.surface,
                        border: Border.all(color: scheme.primary, width: 2.5),
                      ),
                      child: ClipOval(
                        child: SpriteImage(
                          path: leadPokemonPath,
                          size: 64,
                          fallbackIcon: Icons.catching_pokemon,
                        ),
                      ),
                    ),
                    Text(
                      'Nv. ${leadPokemon!['level'] ?? '—'}',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ],
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
  final GameAssetProfile? profile;
  final List<Map<String, dynamic>> badges;
  final List<int> badgeIndices;

  const _BadgeGrid({
    required this.region,
    this.profile,
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
            final asset = profile == null
                ? BadgeAssetResolver.resolveForRegion(region, visualIndex)
                : BadgeAssetResolver.resolve(profile!, visualIndex);
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
  final String? hpDetail;
  final int? friendship;
  final String? spritePath;
  final bool shiny;
  final List<PokemonMoveType> types;
  final VoidCallback? onTap;

  const _PokemonTile({
    required this.name,
    required this.detail,
    this.hpDetail,
    this.friendship,
    required this.spritePath,
    required this.shiny,
    this.types = const <PokemonMoveType>[],
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              _ThemedSpriteFrame(
                spritePath: spritePath,
                size: 62,
                fallbackIcon: Icons.catching_pokemon,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (types.isNotEmpty)
                          PokemonTypeIcons(types: types, size: 22),
                        if (shiny)
                          const Text('✨', semanticsLabel: 'Shiny'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _PokemonSummaryMetric(value: detail),
                        if (hpDetail?.isNotEmpty == true)
                          _PokemonSummaryMetric(value: hpDetail!),
                        if (friendship != null)
                          _PokemonSummaryMetric(
                            value: '$friendship/255',
                            icon: Icons.favorite,
                            iconColor: Colors.red,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PokemonSummaryMetric extends StatelessWidget {
  final String value;
  final IconData? icon;
  final Color? iconColor;

  const _PokemonSummaryMetric({
    required this.value,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: .34),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 4),
          ],
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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

  const _PokemonDetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: .28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PokemonStatsGrid extends StatelessWidget {
  final Map<String, dynamic> pokemon;
  const _PokemonStatsGrid({required this.pokemon});

  int? _value(String key) {
    final value = pokemon[key];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final stats = <(String, int?)>[
      ('Ataque', _value('attack')),
      ('Defensa', _value('defense')),
      if (_value('special') != null) ('Especial', _value('special')),
      if (_value('specialAttack') != null)
        ('At. Especial', _value('specialAttack')),
      if (_value('specialDefense') != null)
        ('Def. Especial', _value('specialDefense')),
      ('Velocidad', _value('speed')),
    ].where((entry) => entry.$2 != null).toList();
    if (stats.isEmpty) {
      return const Text('Se mostrarán después de volver a abrir la partida.');
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: stats
              .map(
                (entry) => Container(
                  width: width,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(entry.$1)),
                      Text(
                        '${entry.$2}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        );
      },
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
