import 'package:flutter/material.dart';

import '../../pokemon/decoder/move_type_resolver.dart';

class MoveTypeTile extends StatelessWidget {
  final String name;
  final PokemonMoveType type;
  final String? leadingLabel;

  const MoveTypeTile({
    super.key,
    required this.name,
    required this.type,
    this.leadingLabel,
  });

  @override
  Widget build(BuildContext context) {
    final visual = _MoveTypeVisual.forType(type);
    final hasLabel = leadingLabel != null;
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
          if (hasLabel)
            Positioned(
              left: 12,
              width: 54,
              child: Text(
                leadingLabel!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Positioned(
            left: hasLabel ? 72 : 14,
            child: _MoveTypeBadge(visual: visual),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: hasLabel ? 120 : 62,
              right: hasLabel ? 18 : 62,
            ),
            child: SizedBox(
              width: double.infinity,
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
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
    PokemonMoveType.normal => const _MoveTypeVisual(Color(0xFFA8A878), Icons.circle_outlined),
    PokemonMoveType.fire => const _MoveTypeVisual(Color(0xFFF08030), Icons.local_fire_department),
    PokemonMoveType.water => const _MoveTypeVisual(Color(0xFF6890F0), Icons.water_drop),
    PokemonMoveType.electric => const _MoveTypeVisual(Color(0xFFF8D030), Icons.bolt),
    PokemonMoveType.grass => const _MoveTypeVisual(Color(0xFF78C850), Icons.eco),
    PokemonMoveType.ice => const _MoveTypeVisual(Color(0xFF98D8D8), Icons.ac_unit),
    PokemonMoveType.fighting => const _MoveTypeVisual(Color(0xFFC03028), Icons.sports_mma),
    PokemonMoveType.poison => const _MoveTypeVisual(Color(0xFFA040A0), Icons.science),
    PokemonMoveType.ground => const _MoveTypeVisual(Color(0xFFE0C068), Icons.landscape),
    PokemonMoveType.flying => const _MoveTypeVisual(Color(0xFFA890F0), Icons.air),
    PokemonMoveType.psychic => const _MoveTypeVisual(Color(0xFFF85888), Icons.visibility),
    PokemonMoveType.bug => const _MoveTypeVisual(Color(0xFFA8B820), Icons.pest_control),
    PokemonMoveType.rock => const _MoveTypeVisual(Color(0xFFB8A038), Icons.hexagon),
    PokemonMoveType.ghost => const _MoveTypeVisual(Color(0xFF705898), Icons.blur_on),
    PokemonMoveType.dragon => const _MoveTypeVisual(Color(0xFF7038F8), Icons.pets, emoji: '🐉'),
    PokemonMoveType.dark => const _MoveTypeVisual(Color(0xFF705848), Icons.dark_mode),
    PokemonMoveType.steel => const _MoveTypeVisual(Color(0xFFB8B8D0), Icons.settings),
    PokemonMoveType.unknown => const _MoveTypeVisual(Color(0xFF686868), Icons.question_mark),
  };
}

