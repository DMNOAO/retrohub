import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/assets/badge_asset_resolver.dart';
import '../../core/assets/character_asset_resolver.dart';
import '../../core/assets/game_asset_profile.dart';
import '../../core/assets/sprite_image.dart';
import '../../core/assets/sprite_resolver.dart';
import '../../data/database/app_database.dart';
import '../../data/database/database_provider.dart';
import '../pokemon/services/nds_trainer_resolver.dart';
import '../pokemon/decoder/pokemon_decoder.dart';
import '../pokemon/models/pokemon_game_profile.dart';
import '../pokemon/models/trainer_class.dart';
import '../../shared/theme/app_appearance.dart';
import 'pokedex_grid.dart';
import 'widgets/journal_chrome.dart';

class JournalHistoryPage extends ConsumerStatefulWidget {
  final Game game;
  final String initialSection;

  const JournalHistoryPage({
    super.key,
    required this.game,
    this.initialSection = 'all',
  });

  @override
  ConsumerState<JournalHistoryPage> createState() => _JournalHistoryPageState();
}

class _JournalHistoryPageState extends ConsumerState<JournalHistoryPage> {
  bool _loading = true;
  List<_TimelineItem> _items = const [];
  late String _filter;
  Set<int> _seenPokemonIds = const <int>{};
  Set<int> _caughtPokemonIds = const <int>{};
  bool _nationalDexUnlocked = false;
  bool _isFemale = false;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialSection;
    _load();
  }

  Future<void> _load() async {
    final database = ref.read(databaseProvider);
    final results = await Future.wait([
      database.getProgressEventsByGame(widget.game.id),
      database.getJournalEntriesByGame(widget.game.id),
      database.getLatestProgressSnapshot(widget.game.id),
    ]);

    final events = results[0] as List<GameProgressEvent>;
    final entries = results[1] as List<JournalEntry>;
    final snapshot = results[2] as GameProgressSnapshot?;
    final items = <_TimelineItem>[
      ...events.map(_TimelineItem.fromEvent),
      ...entries.map(_TimelineItem.fromEntry),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final seenIds = <int>{};
    final caughtIds = <int>{};
    var detailedStateFound = false;
    var nationalDexUnlocked = false;
    for (final event in events) {
      final metadata = _TimelineItem._decodeMetadata(event.metadataJson);
      if (!detailedStateFound && metadata['nationalDexUnlocked'] == true) {
        nationalDexUnlocked = true;
      }
      if (!detailedStateFound &&
          metadata['seenPokemonIds'] is List &&
          metadata['caughtPokemonIds'] is List) {
        seenIds.addAll(_intSet(metadata['seenPokemonIds']));
        caughtIds.addAll(_intSet(metadata['caughtPokemonIds']));
        detailedStateFound = true;
      }
      final capturedId = _nullableInt(metadata['pokemonId']);
      if (capturedId != null) {
        seenIds.add(capturedId);
        caughtIds.add(capturedId);
      }
      final party = metadata['partySpeciesIds'];
      if (party is List) seenIds.addAll(_intSet(party));
    }
    seenIds.addAll(caughtIds);

    final snapshotBadges = snapshot == null
        ? const <dynamic>[]
        : _TimelineItem._decodeList(snapshot.badgesJson);
    final snapshotGender = snapshotBadges.isNotEmpty &&
            snapshotBadges.first is Map
        ? (snapshotBadges.first as Map)['playerGender']?.toString()
        : null;
    String? eventGender;
    for (final event in events) {
      final gender = _TimelineItem._decodeMetadata(
        event.metadataJson,
      )['playerGender']?.toString();
      if (gender == 'female' || gender == 'male') {
        eventGender = gender;
        break;
      }
    }

    if (!mounted) return;
    setState(() {
      _items = items;
      _seenPokemonIds = seenIds;
      _caughtPokemonIds = caughtIds;
      _nationalDexUnlocked = nationalDexUnlocked;
      _isFemale = (snapshotGender ?? eventGender) == 'female';
      _loading = false;
    });
  }

  static Set<int> _intSet(dynamic values) {
    if (values is! List) return <int>{};
    return values.map(_nullableInt).whereType<int>().where((id) => id > 0).toSet();
  }

  static int? _nullableInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final profile = GameAssetProfile.fromGame(widget.game);
    final protagonistPath = CharacterAssetResolver.protagonist(
      profile,
      isFemale: _isFemale,
    );
    final locationProfile = PokemonGameProfile.fromGameIdentity(
      gameTitle: widget.game.title,
      romPath: widget.game.romPath,
    );
    final filtered = _filter == 'all'
        ? _items
        : _items.where((item) => item.category == _filter).toList();

    final journalAppearance = AppAppearance.forGameTitle(widget.game.title);
    final history = Scaffold(
      appBar: JournalAppBar(
        title: _filter == 'pokemon' ? 'Pokedex' : 'Historia',
        icon: _filter == 'pokemon'
            ? Icons.catching_pokemon
            : Icons.auto_stories_outlined,
        onRefresh: () {
          setState(() => _loading = true);
          _load();
        },
      ),
      bottomNavigationBar: JournalSectionBar(
        sections: _HistoryFilters.values,
        selected: _filter,
        onSelected: (value) => setState(() => _filter = value),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: _HistoryHeader(
                    game: widget.game,
                    protagonistPath: protagonistPath,
                    itemCount: _items.length,
                  ),
                ),
              ],
              body: _filter == 'pokemon'
                  ? PokedexGrid(
                      profile: profile,
                      seenIds: _seenPokemonIds,
                      caughtIds: _caughtPokemonIds,
                      nationalDexUnlocked:
                          profile.game != PokemonAssetGame.emerald &&
                          profile.game !=
                                  PokemonAssetGame.fireRedLeafGreen &&
                              profile.game !=
                                  PokemonAssetGame.heartGoldSoulSilver &&
                              profile.region != PokemonAssetRegion.sinnoh ||
                          _nationalDexUnlocked,
                    )
                  : filtered.isEmpty
                  ? const _EmptyHistory()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return _TimelineCard(
                          item: item,
                          profile: profile,
                          protagonistPath: protagonistPath,
                          locationProfile: locationProfile,
                          isLast: index == filtered.length - 1,
                        );
                      },
                    ),
            ),
    );
    if (journalAppearance == null) return history;
    return Theme(data: journalAppearance.theme, child: history);
  }
}

class _HistoryHeader extends StatelessWidget {
  final Game game;
  final int itemCount;
  final String? protagonistPath;

  const _HistoryHeader({
    required this.game,
    required this.itemCount,
    required this.protagonistPath,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SpriteImage(path: protagonistPath, size: 54, fallbackIcon: Icons.person_outline),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(game.title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text('$itemCount momentos registrados'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

abstract final class _HistoryFilters {
  static const values = <JournalSection>[
    JournalSection('all', 'Todo', Icons.view_timeline_outlined),
    JournalSection('pokemon', 'Pokedex', Icons.catching_pokemon),
    JournalSection('adventure', 'Aventura', Icons.explore_outlined),
    JournalSection('battle', 'Combates', Icons.sports_martial_arts_outlined),
    JournalSection('system', 'Sesiones', Icons.save_outlined),
    JournalSection('manual', 'Notas', Icons.edit_note_outlined),
  ];
}

class _TimelineCard extends StatelessWidget {
  final _TimelineItem item;
  final GameAssetProfile profile;
  final PokemonGameProfile locationProfile;
  final bool isLast;
  final String? protagonistPath;

  const _TimelineCard({
    required this.item,
    required this.profile,
    required this.locationProfile,
    required this.isLast,
    required this.protagonistPath,
  });

  @override
  Widget build(BuildContext context) {
    final visual = _resolveVisual(item, profile, protagonistPath);
    final scheme = Theme.of(context).colorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: scheme.outlineVariant)),
              ],
            ),
          ),
          Expanded(
            child: Card(
              margin: const EdgeInsets.only(bottom: 14),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: scheme.primary, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: .20),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: SpriteImage(
                        path: visual.path,
                        size: 58,
                        fallbackIcon: visual.icon,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(item.title, style: Theme.of(context).textTheme.titleMedium)),
                              Text(_formatDate(item.createdAt), style: Theme.of(context).textTheme.labelMedium),
                            ],
                          ),
                          if (_resolvedDescription(item, locationProfile)
                              case final description?) ...[
                            const SizedBox(height: 6),
                            Text(description),
                          ],
                          const SizedBox(height: 9),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _MetaChip(icon: Icons.schedule, label: _formatPlayTime(item.playTimeMinutes)),
                              if (_resolvedMapName(item, locationProfile) case final mapName?)
                                _MetaChip(
                                  icon: Icons.place_outlined,
                                  label: mapName,
                                ),
                              if (item.metadata['playerName'] != null &&
                                  item.metadata['playerName'].toString().isNotEmpty)
                                _MetaChip(
                                  icon: Icons.person_outline,
                                  label: item.metadata['playerName'].toString(),
                                ),
                              if (item.metadata['money'] != null)
                                _MetaChip(
                                  icon: Icons.payments_outlined,
                                  label: r'$' + item.metadata['money'].toString(),
                                ),
                              if (item.metadata['level'] != null)
                                _MetaChip(icon: Icons.trending_up, label: 'Nv. ${item.metadata['level']}'),
                              if (item.metadata['isShiny'] == true)
                                const _MetaChip(icon: Icons.auto_awesome, label: 'Shiny'),
                            ],
                          ),
                          if (item.screenshotPath != null) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SpriteImage(path: item.screenshotPath, size: 220, fit: BoxFit.cover),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String? _resolvedMapName(
    _TimelineItem item,
    PokemonGameProfile profile,
  ) {
    final stored = item.metadata['mapName']?.toString();
    final mapId = _toInt(item.metadata['mapId']);
    if (mapId == null) return stored;
    final resolved = PokemonDecoder.mapName(profile, mapId);
    if (!resolved.startsWith('Zona ')) return resolved;
    return stored ?? resolved;
  }

  static String? _resolvedDescription(
    _TimelineItem item,
    PokemonGameProfile profile,
  ) {
    final description = item.description?.trim();
    if (description == null || description.isEmpty) return null;
    if (item.type != 'location_changed' ||
        !description.startsWith('Zona ')) {
      return description;
    }
    return _resolvedMapName(item, profile) ?? description;
  }

  _Visual _resolveVisual(
    _TimelineItem item,
    GameAssetProfile profile,
    String? protagonistPath,
  ) {
    switch (item.type) {
      case 'badge_obtained':
        final index = _toInt(item.metadata['badgeIndex']) ?? _firstBadgeIndex(_toInt(item.metadata['newBadgesMask']) ?? 0);
        return _Visual(BadgeAssetResolver.resolve(profile, index).path, Icons.workspace_premium_outlined);
      case 'pokemon_captured':
        final id = _toInt(item.metadata['pokemonId']);
        if (id != null) {
          return _Visual(
            SpriteResolver.pokemonForGame(
              profile: profile,
              pokemonId: id,
              isShiny: item.metadata['isShiny'] == true,
            ),
            Icons.catching_pokemon,
          );
        }
        return const _Visual(null, Icons.catching_pokemon);
      case 'party_changed':
        final party = item.metadata['party'];
        if (party is List && party.isNotEmpty && party.first is Map) {
          final pokemon = Map<String, dynamic>.from(party.first as Map);
          final id = _toInt(pokemon['id']);
          if (id != null) {
            return _Visual(SpriteResolver.pokemonForGame(profile: profile, pokemonId: id), Icons.catching_pokemon);
          }
        }
        return const _Visual(null, Icons.groups_outlined);
      case 'location_changed':
      case 'pokemon_progress_detected':
        return _Visual(protagonistPath, Icons.place_outlined);
      case 'gym_leader_defeated':
        final spritePath = item.metadata['spritePath']?.toString();
        return _Visual(spritePath, Icons.shield_outlined);
      case 'rival_defeated':
        return _Visual(CharacterAssetResolver.rival(profile), Icons.sports_martial_arts);
      case 'champion_defeated':
        return _Visual(CharacterAssetResolver.champion(profile), Icons.emoji_events_outlined);
      case 'elite_four_defeated':
        return _Visual(
          item.metadata['spritePath']?.toString(),
          Icons.military_tech_outlined,
        );
      case 'trainer_defeated':
        final trainerClass = item.metadata['trainerClass']?.toString();
        final explicitPath = item.metadata['spritePath']?.toString();
        final trainerClassId = _toInt(item.metadata['trainerClassId']);
        final gen2Trainer = trainerClassId == null
            ? null
            : TrainerClassResolver.forClassId(trainerClassId);
        final trainerFlagId = _toInt(item.metadata['trainerFlagId']);
        final flagTrainer = trainerFlagId == null
            ? null
            : NdsTrainerResolver.forGen5TrainerFlag(trainerFlagId);
        return _Visual(
          flagTrainer?.spritePath ??
              explicitPath ??
              gen2Trainer?.spritePath ??
              (trainerClass == null
                  ? CharacterAssetResolver.genericTrainer(profile)
                  : CharacterAssetResolver.trainer(
                      profile: profile,
                      trainerClass: trainerClass,
                    )),
          Icons.sports_martial_arts,
        );
      case 'screenshot':
        return _Visual(item.screenshotPath, Icons.photo_camera_outlined);
      case 'save_state':
        return const _Visual(null, Icons.save_outlined);
      case 'load_state':
        return const _Visual(null, Icons.history);
      case 'game_started':
        return _Visual(protagonistPath, Icons.play_arrow);
      case 'game_closed':
        return const _Visual(null, Icons.stop_circle_outlined);
      case 'manual_entry':
        return const _Visual(null, Icons.edit_note_outlined);
      default:
        return const _Visual(null, Icons.auto_stories_outlined);
    }
  }

  int _firstBadgeIndex(int mask) {
    for (var i = 0; i < 8; i++) {
      if ((mask & (1 << i)) != 0) return i;
    }
    return 0;
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  String _formatDate(DateTime value) {
    final d = value.day.toString().padLeft(2, '0');
    final m = value.month.toString().padLeft(2, '0');
    final h = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '$d/$m · $h:$min';
  }

  String _formatPlayTime(int minutes) {
    if (minutes < 1) return '< 1 min';
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    return hours == 0 ? '$remaining min' : '$hours h ${remaining.toString().padLeft(2, '0')} min';
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_stories_outlined, size: 64),
            SizedBox(height: 14),
            Text('Todavía no hay momentos en esta categoría.'),
          ],
        ),
      ),
    );
  }
}

class _Visual {
  final String? path;
  final IconData icon;
  const _Visual(this.path, this.icon);
}

class _TimelineItem {
  final DateTime createdAt;
  final String type;
  final String category;
  final String title;
  final String? description;
  final Map<String, dynamic> metadata;
  final int playTimeMinutes;
  final String? screenshotPath;

  const _TimelineItem({
    required this.createdAt,
    required this.type,
    required this.category,
    required this.title,
    required this.description,
    required this.metadata,
    required this.playTimeMinutes,
    required this.screenshotPath,
  });

  factory _TimelineItem.fromEvent(GameProgressEvent event) {
    final metadata = _decodeMetadata(event.metadataJson);
    return _TimelineItem(
      createdAt: event.createdAt,
      type: event.eventType,
      category: _categoryFor(event.eventType),
      title: event.title,
      description: event.description,
      metadata: metadata,
      playTimeMinutes: _readInt(metadata['playTimeMinutes']),
      screenshotPath: metadata['screenshotPath']?.toString(),
    );
  }

  factory _TimelineItem.fromEntry(JournalEntry entry) {
    return _TimelineItem(
      createdAt: entry.createdAt,
      type: 'manual_entry',
      category: 'manual',
      title: entry.title?.trim().isNotEmpty == true ? entry.title! : 'Nota de la aventura',
      description: entry.content,
      metadata: const {},
      playTimeMinutes: entry.playTimeMinutes,
      screenshotPath: entry.screenshotPath,
    );
  }

  static Map<String, dynamic> _decodeMetadata(String? value) {
    if (value == null || value.trim().isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return <String, dynamic>{};
  }

  static List<dynamic> _decodeList(String? value) {
    if (value == null || value.trim().isEmpty) return const <dynamic>[];
    try {
      final decoded = jsonDecode(value);
      if (decoded is List) return decoded;
    } catch (_) {}
    return const <dynamic>[];
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _categoryFor(String type) {
    if (type == 'badge_obtained' || type.contains('defeated') || type == 'trainer_defeated') return 'battle';
    if (type == 'pokemon_captured' || type == 'party_changed') return 'pokemon';
    if (type == 'game_started' || type == 'game_closed' || type == 'save_state' || type == 'load_state' || type == 'screenshot') return 'system';
    return 'adventure';
  }
}
