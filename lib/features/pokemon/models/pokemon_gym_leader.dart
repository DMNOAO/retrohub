import '../models/pokemon_game_profile.dart';

/// Nombre y sprite de un líder de gimnasio para una medalla específica.
class GymLeaderInfo {
  final String name;
  final String spritePath;
  const GymLeaderInfo(this.name, this.spritePath);
}

/// Resuelve qué líder corresponde a cada medalla, por versión de juego.
///
/// Solo se completan aquí las entradas que se pueden confirmar con certeza
/// (nombre de archivo inequívoco o confirmado por el propio equipo). Las
/// medallas sin líder confirmado devuelven null: en ese caso el evento de
/// "medalla obtenida" se sigue registrando igual, solo sin el evento
/// adicional de "derrotó a [líder]" hasta tener el dato correcto.
class GymLeaderAssetResolver {
  const GymLeaderAssetResolver._();

  static GymLeaderInfo? forBadge(PokemonGameProfile profile, int badgeIndex) {
    switch (profile.version) {
      case PokemonGameVersion.redBlue:
      case PokemonGameVersion.yellow:
        return _kanto[badgeIndex];
      case PokemonGameVersion.gold:
      case PokemonGameVersion.silver:
      case PokemonGameVersion.crystal:
        return _johto[badgeIndex];
      case PokemonGameVersion.unsupported:
        return null;
    }
  }

  // Orden estándar de medallas Kanto (Roca..Tierra). Nombres de archivo
  // inequívocos en assets/sprites/characters/gym_leaders/gb/.
  static const List<GymLeaderInfo?> _kanto = <GymLeaderInfo?>[
    GymLeaderInfo('Brock', 'assets/sprites/characters/gym_leaders/gb/brock_kanto.png'),
    GymLeaderInfo('Misty', 'assets/sprites/characters/gym_leaders/gb/misty_kanto.png'),
    GymLeaderInfo('Lt. Surge', 'assets/sprites/characters/gym_leaders/gb/lt._surge_kanto.png'),
    GymLeaderInfo('Erika', 'assets/sprites/characters/gym_leaders/gb/erika_kanto.png'),
    GymLeaderInfo('Koga', 'assets/sprites/characters/gym_leaders/gb/koga_kanto.png'),
    GymLeaderInfo('Sabrina', 'assets/sprites/characters/gym_leaders/gb/sabrina_kanto.png'),
    GymLeaderInfo('Blaine', 'assets/sprites/characters/gym_leaders/gb/blaine_kanto.png'),
    GymLeaderInfo('Giovanni', 'assets/sprites/characters/gym_leaders/gb/giovanni_kanto.png'),
  ];

  // Orden de medallas Johto (Céfiro..Dragón). Solo se confirmaron 2 de 8
  // hasta ahora (Pegaso y Blanca, según el propio ejemplo de la Fase 4.1/4.2).
  // Los demás índices quedan en null: pendientes de confirmar el orden real
  // contra los archivos restantes (Yasmina, Sachiko, Morti, Antón, Débora,
  // Azul, Fredo, Aníbal) antes de asignarlos a una medalla concreta.
  static const List<GymLeaderInfo?> _johto = <GymLeaderInfo?>[
    GymLeaderInfo('Pegaso', 'assets/sprites/characters/gym_leaders/gbc/Pegaso_OPC.png'), // Céfiro
    null, // Colmena
    GymLeaderInfo('Blanca', 'assets/sprites/characters/gym_leaders/gbc/Blanca_OPC.png'), // Planicie
    null, // Niebla
    null, // Tormenta
    null, // Mineral
    null, // Glaciar
    null, // Dragón
  ];
}
