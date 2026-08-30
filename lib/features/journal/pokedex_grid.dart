import 'package:flutter/material.dart';

import '../../core/assets/game_asset_profile.dart';
import '../../core/assets/sprite_image.dart';
import '../../core/assets/sprite_resolver.dart';
import '../pokemon/decoder/pokemon_decoder.dart';
import 'pokedex_detail_page.dart';
import 'pokedex_orders.dart';

enum PokedexOrder { johto, kanto, hoenn, sinnoh, unova, national }

class PokedexGrid extends StatefulWidget {
  final GameAssetProfile profile;
  final Set<int> seenIds;
  final Set<int> caughtIds;
  final bool nationalDexUnlocked;

  const PokedexGrid({super.key, required this.profile, required this.seenIds, required this.caughtIds, this.nationalDexUnlocked = true});

  @override
  State<PokedexGrid> createState() => _PokedexGridState();
}

class _PokedexGridState extends State<PokedexGrid> {
  late PokedexOrder _order;
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();
  bool get _isGen2 => widget.profile.region == PokemonAssetRegion.johto;
  bool get _isHgss =>
      widget.profile.game == PokemonAssetGame.heartGoldSoulSilver;
  bool get _isHoenn => widget.profile.region == PokemonAssetRegion.hoenn;
  bool get _isGen3Kanto =>
      widget.profile.game == PokemonAssetGame.fireRedLeafGreen;
  bool get _isGen3 => _isHoenn || _isGen3Kanto;
  bool get _isSinnoh => widget.profile.region == PokemonAssetRegion.sinnoh;
  bool get _isUnova => widget.profile.region == PokemonAssetRegion.unova;
  bool get _isB2W2 => widget.profile.game == PokemonAssetGame.black2White2;

  @override
  void initState() {
    super.initState();
    _order = _isUnova
        ? PokedexOrder.unova
        : _isSinnoh
        ? PokedexOrder.sinnoh
        : _isHoenn
        ? PokedexOrder.hoenn
        : _isGen3Kanto
        ? PokedexOrder.kanto
        : PokedexOrder.johto;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final national = List<int>.generate(
      _isUnova ? 649 : (_isSinnoh || _isHgss) ? 493 : (_isGen3 ? 386 : (_isGen2 ? 251 : 151)),
      (index) => index + 1,
    );
    final sinnoh = widget.profile.game == PokemonAssetGame.platinum
        ? sinnohPlatinumPokedexOrder
        : sinnohDiamondPearlPokedexOrder;
    final ids = _isUnova && _order == PokedexOrder.unova
        ? (_isB2W2
              ? unovaBlack2White2PokedexOrder
              : unovaBlackWhitePokedexOrder)
        : _isSinnoh && _order == PokedexOrder.sinnoh
        ? sinnoh
        : _isGen2 && _order == PokedexOrder.johto
        ? (_isHgss ? johtoHeartGoldSoulSilverPokedexOrder : _johtoOrder)
        : _isHoenn && _order == PokedexOrder.hoenn
        ? hoennPokedexOrder
        : _isGen3Kanto && _order == PokedexOrder.kanto
        ? List<int>.generate(151, (index) => index + 1)
        : national;
    final visibleSeen = pokedexIdsInOrder(widget.seenIds, ids);
    final visibleCaught = pokedexIdsInOrder(widget.caughtIds, ids);
    final normalizedQuery = _normalizeSearch(_searchText);
    final filteredIds = normalizedQuery.isEmpty
        ? ids
        : ids.where((id) {
            final name = PokemonDecoder.pokemonName(id);
            return _normalizeSearch(name).contains(normalizedQuery);
          }).toList(growable: false);
    final scheme = Theme.of(context).colorScheme;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 12),
        child: Row(children: [
          Expanded(child: Text('${visibleSeen.length} vistos · ${visibleCaught.length} capturados', style: Theme.of(context).textTheme.titleMedium)),
          if (_isGen2) SegmentedButton<PokedexOrder>(segments: [const ButtonSegment(value: PokedexOrder.johto, label: Text('Johto')), ButtonSegment(value: PokedexOrder.national, enabled: !_isHgss || widget.nationalDexUnlocked, label: const Text('Nacional'), icon: !_isHgss || widget.nationalDexUnlocked ? null : const Icon(Icons.lock_outline))], selected: {_order}, onSelectionChanged: (value) => setState(() => _order = value.first)),
          if (_isHoenn) SegmentedButton<PokedexOrder>(segments: [const ButtonSegment(value: PokedexOrder.hoenn, label: Text('Hoenn')), ButtonSegment(value: PokedexOrder.national, enabled: widget.nationalDexUnlocked, label: const Text('Nacional'), icon: widget.nationalDexUnlocked ? null : const Icon(Icons.lock_outline))], selected: {_order}, onSelectionChanged: (value) => setState(() => _order = value.first)),
          if (_isGen3Kanto) SegmentedButton<PokedexOrder>(segments: [const ButtonSegment(value: PokedexOrder.kanto, label: Text('Kanto')), ButtonSegment(value: PokedexOrder.national, enabled: widget.nationalDexUnlocked, label: const Text('Nacional'), icon: widget.nationalDexUnlocked ? null : const Icon(Icons.lock_outline))], selected: {_order}, onSelectionChanged: (value) => setState(() => _order = value.first)),
          if (_isSinnoh) SegmentedButton<PokedexOrder>(segments: [const ButtonSegment(value: PokedexOrder.sinnoh, label: Text('Sinnoh')), ButtonSegment(value: PokedexOrder.national, enabled: widget.nationalDexUnlocked, label: const Text('Nacional'), icon: widget.nationalDexUnlocked ? null : const Icon(Icons.lock_outline))], selected: {_order}, onSelectionChanged: (value) => setState(() => _order = value.first)),
          if (_isUnova) SegmentedButton<PokedexOrder>(segments: [const ButtonSegment(value: PokedexOrder.unova, label: Text('Teselia')), ButtonSegment(value: PokedexOrder.national, enabled: widget.nationalDexUnlocked, label: const Text('Nacional'), icon: widget.nationalDexUnlocked ? null : const Icon(Icons.lock_outline))], selected: {_order}, onSelectionChanged: (value) => setState(() => _order = value.first)),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchText = value),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Buscar Pokémon por nombre...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchText.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Limpiar búsqueda',
                    onPressed: () {
                      _searchController.clear();
                      FocusScope.of(context).unfocus();
                      setState(() => _searchText = '');
                    },
                    icon: const Icon(Icons.close),
                  ),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
      Expanded(child: LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100 ? 10 : constraints.maxWidth >= 800 ? 8 : constraints.maxWidth >= 560 ? 6 : 3;
        if (filteredIds.isEmpty) {
          return const Center(child: Text('No se encontraron Pokémon'));
        }
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
          itemCount: filteredIds.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: .82),
          itemBuilder: (context, index) {
            final dexId = filteredIds[index];
            final regionalIndex = ids.indexOf(dexId);
            final seen = widget.seenIds.contains(dexId);
            final caught = widget.caughtIds.contains(dexId);
            final displayNumber = _isUnova && _order == PokedexOrder.unova
                ? (regionalIndex == 0 ? 0 : regionalIndex)
                : (_isGen2 && _order == PokedexOrder.johto) || (_isHoenn && _order == PokedexOrder.hoenn) || (_isSinnoh && _order == PokedexOrder.sinnoh) ? regionalIndex + 1 : dexId;
            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: seen ? () {
                final gameTheme = Theme.of(context);
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => Theme(
                  data: gameTheme,
                  child: PokedexDetailPage(
                    profile: widget.profile,
                    pokemonId: dexId,
                    displayNumber: displayNumber,
                    caught: caught,
                    availableIds: visibleSeen,
                    caughtIds: widget.caughtIds,
                    dexOrder: ids,
                  ),
                )));
              } : null,
              child: Container(
                decoration: BoxDecoration(color: seen ? scheme.surfaceContainerHigh : scheme.surfaceContainerLow, borderRadius: BorderRadius.circular(14), border: Border.all(color: caught ? scheme.primary : scheme.outlineVariant, width: caught ? 2 : 1)),
                child: Stack(children: [
                  Padding(
                    padding: const EdgeInsets.all(7),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Align(alignment: Alignment.topLeft, child: Text('#${displayNumber.toString().padLeft(4, '0')}', style: Theme.of(context).textTheme.labelSmall)),
                      Expanded(
                        child: Center(
                          child: seen
                              ? Container(
                                  width: 72,
                                  height: 72,
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: scheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: scheme.primary,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: scheme.primary.withValues(alpha: .18),
                                        blurRadius: 7,
                                      ),
                                    ],
                                  ),
                                  child: SpriteImage(
                                    path: SpriteResolver.pokemonForGame(
                                      profile: widget.profile,
                                      pokemonId: dexId,
                                    ),
                                    size: 62,
                                    fallbackIcon: Icons.catching_pokemon,
                                  ),
                                )
                              : Icon(
                                  Icons.question_mark,
                                  size: 34,
                                  color: scheme.onSurfaceVariant.withValues(alpha: .38),
                                ),
                        ),
                      ),
                      Text(
                        seen ? PokemonDecoder.pokemonName(dexId) : 'No visto',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ]),
                  ),
                  if (caught) Positioned(right: 7, top: 7, child: Icon(Icons.catching_pokemon, size: 18, color: scheme.primary)),
                ]),
              ),
            );
          },
        );
      })),
    ]);
  }

  String _normalizeSearch(String value) {
    const accents = 'áéíóúüñÁÉÍÓÚÜÑ';
    const plain = 'aeiouunAEIOUUN';
    var normalized = value.trim().toLowerCase();
    for (var index = 0; index < accents.length; index++) {
      normalized = normalized.replaceAll(accents[index], plain[index]);
    }
    return normalized;
  }
}

const List<int> _johtoOrder = <int>[
  152,153,154,155,156,157,158,159,160,16,17,18,21,22,163,164,19,20,161,162,172,25,26,10,11,12,13,14,15,165,166,167,168,74,75,76,41,42,169,173,35,36,174,39,40,175,176,27,28,23,24,206,179,180,181,194,195,92,93,94,201,95,208,69,70,71,187,188,189,46,47,60,61,62,186,129,130,118,119,79,80,199,43,44,45,182,96,97,63,64,65,132,204,205,29,30,31,32,33,34,193,191,192,102,103,185,202,48,49,123,212,127,214,109,110,88,89,81,82,100,101,190,209,210,37,38,58,59,234,183,184,50,51,56,57,52,53,54,55,66,67,68,236,106,107,237,203,128,241,240,126,238,124,239,125,122,235,83,177,178,211,72,73,98,99,213,120,121,90,91,222,223,224,170,171,86,87,108,114,133,134,135,136,196,197,116,117,230,207,225,220,221,216,217,231,232,226,227,84,85,77,78,104,105,115,111,112,198,228,229,218,219,215,200,137,233,113,242,131,138,139,140,141,142,143,1,2,3,4,5,6,7,8,9,144,145,146,243,244,245,147,148,149,246,247,248,249,250,150,151,251
];
