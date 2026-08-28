import '../../../core/assets/game_asset_profile.dart';
import 'pokedex_models.dart';

class PokedexAcquisitionData {
  const PokedexAcquisitionData._();

  static List<PokedexAcquisition> forGame(
    GameAssetProfile profile,
    int pokemonId,
  ) {
    final common = switch (profile.game) {
      PokemonAssetGame.redBlue || PokemonAssetGame.yellow =>
        _kanto(profile, pokemonId),
      PokemonAssetGame.gold ||
      PokemonAssetGame.silver ||
      PokemonAssetGame.crystal => _johto(profile, pokemonId),
      _ => const <PokedexAcquisition>[],
    };
    return common;
  }

  static List<PokedexAcquisition> _kanto(
    GameAssetProfile profile,
    int pokemonId,
  ) {
    switch (pokemonId) {
      case 106:
        return const [
          PokedexAcquisition(
            method: 'Regalo · Elección',
            location: 'Dojo Karate · Ciudad Azafrán',
            detail: 'Premio tras vencer al Maestro Karateka. Debes elegir entre Hitmonlee y Hitmonchan.',
          ),
        ];
      case 107:
        return const [
          PokedexAcquisition(
            method: 'Regalo · Elección',
            location: 'Dojo Karate · Ciudad Azafrán',
            detail: 'Premio tras vencer al Maestro Karateka. Debes elegir entre Hitmonlee y Hitmonchan.',
          ),
        ];
      case 122:
        final yellow = profile.game == PokemonAssetGame.yellow;
        return [
          PokedexAcquisition(
            method: 'Intercambio con NPC',
            location: 'Ruta 2',
            detail: yellow
                ? 'Entrega un Clefairy para recibir a Mr. Mime.'
                : 'Entrega un Abra para recibir a Mr. Mime.',
          ),
        ];
      case 124:
        if (profile.game == PokemonAssetGame.yellow) {
          return const <PokedexAcquisition>[];
        }
        return const [
          PokedexAcquisition(
            method: 'Intercambio con NPC',
            location: 'Ciudad Celeste',
            detail: 'Entrega un Poliwhirl para recibir a Jynx.',
          ),
        ];
      case 131:
        return const [
          PokedexAcquisition(
            method: 'Regalo',
            location: 'Silph S.A. · Ciudad Azafrán',
            detail: 'Un empleado te entrega a Lapras durante la incursión del Team Rocket.',
          ),
        ];
      case 133:
        return const [
          PokedexAcquisition(
            method: 'Regalo',
            location: 'Mansión Azulona · Ciudad Azulona',
            detail: 'Entra por la puerta trasera y recoge la Poké Ball de Eevee en la azotea.',
          ),
        ];
      default:
        return const <PokedexAcquisition>[];
    }
  }

  static List<PokedexAcquisition> _johto(
    GameAssetProfile profile,
    int pokemonId,
  ) {
    if (pokemonId == 37 && profile.game == PokemonAssetGame.gold) {
      return const [
        PokedexAcquisition(
          method: 'Otra versión',
          location: 'Pokémon Plata',
          detail: 'Vulpix no aparece en Pokémon Oro. Debes intercambiarlo desde Pokémon Plata.',
        ),
      ];
    }
    if (pokemonId == 58 && profile.game == PokemonAssetGame.silver) {
      return const [
        PokedexAcquisition(
          method: 'Otra versión',
          location: 'Pokémon Oro',
          detail: 'Growlithe no aparece en Pokémon Plata. Debes intercambiarlo desde Pokémon Oro.',
        ),
      ];
    }
    switch (pokemonId) {
      case 131:
        return const [
          PokedexAcquisition(
            method: 'Encuentro único semanal',
            location: 'Cueva Unión · Planta B2',
            detail: 'Aparece los viernes después de conseguir la Medalla Planicie.',
          ),
        ];
      case 133:
        return const [
          PokedexAcquisition(
            method: 'Regalo',
            location: 'Ciudad Trigal',
            detail: 'Bill te entrega a Eevee en su casa después de conocerlo en Ciudad Iris.',
          ),
        ];
      case 236:
        return const [
          PokedexAcquisition(
            method: 'Regalo',
            location: 'Monte Mortero',
            detail: 'Kiyo te entrega a Tyrogue después de vencerlo. Necesitas un espacio libre en el equipo.',
          ),
        ];
      default:
        return const <PokedexAcquisition>[];
    }
  }
}
