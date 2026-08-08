final class PokemonMemoryAddresses {
  final int playerName;
  final int partyCount;
  final int partySpecies;
  final int partyMons;
  final int pokedexOwned;
  final int pokedexSeen;
  final int playerMoney;
  final int playerId;
  final int obtainedBadges;
  final int? kantoBadges;
  final int currentMap;
  final int? currentMapGroup;
  final int playerY;
  final int playerX;
  final int playerNameLength;
  final int partyStructLength;
  final int partyLevelOffset;
  final int pokedexBytes;
  final int? partyDvOffset;

  // --- Combate (Fase 4.2/4.3) ---
  // Gen2 (Crystal/Gold): wBattleMode indica 0=fuera de combate,
  // 1=combate salvaje, 2=combate de entrenador. wOtherTrainerClass/ID
  // identifican al rival (0 = combate salvaje, no entrenador).
  final int? battleMode;
  final int? otherTrainerClass;
  final int? otherTrainerId;
  final int? battleResult;
  // Gen1 (Red/Blue/Yellow): mismo concepto con otros nombres/valores.
  // wIsInBattle: 0=fuera de combate, 1=salvaje, 2=entrenador.
  final int? isInBattle;

  const PokemonMemoryAddresses({
    required this.playerName,
    required this.partyCount,
    required this.partySpecies,
    required this.partyMons,
    required this.pokedexOwned,
    required this.pokedexSeen,
    required this.playerMoney,
    required this.playerId,
    required this.obtainedBadges,
    this.kantoBadges,
    required this.currentMap,
    this.currentMapGroup,
    required this.playerY,
    required this.playerX,
    required this.playerNameLength,
    required this.partyStructLength,
    required this.partyLevelOffset,
    required this.pokedexBytes,
    this.partyDvOffset,
    this.battleMode,
    this.otherTrainerClass,
    this.otherTrainerId,
    this.battleResult,
    this.isInBattle,
  });

  static const int maximumPartySize = 6;

  PokemonMemoryAddresses shifted(int delta) => PokemonMemoryAddresses(
    playerName: playerName + delta,
    partyCount: partyCount + delta,
    partySpecies: partySpecies + delta,
    partyMons: partyMons + delta,
    pokedexOwned: pokedexOwned + delta,
    pokedexSeen: pokedexSeen + delta,
    playerMoney: playerMoney + delta,
    playerId: playerId + delta,
    obtainedBadges: obtainedBadges + delta,
    kantoBadges: kantoBadges == null ? null : kantoBadges! + delta,
    currentMap: currentMap + delta,
    currentMapGroup: currentMapGroup == null ? null : currentMapGroup! + delta,
    playerY: playerY + delta,
    playerX: playerX + delta,
    playerNameLength: playerNameLength,
    partyStructLength: partyStructLength,
    partyLevelOffset: partyLevelOffset,
    pokedexBytes: pokedexBytes,
    partyDvOffset: partyDvOffset,
    battleMode: battleMode == null ? null : battleMode! + delta,
    otherTrainerClass: otherTrainerClass == null
        ? null
        : otherTrainerClass! + delta,
    otherTrainerId: otherTrainerId == null ? null : otherTrainerId! + delta,
    battleResult: battleResult == null ? null : battleResult! + delta,
    isInBattle: isInBattle == null ? null : isInBattle! + delta,
  );

  static const redBlue = PokemonMemoryAddresses(
    playerName: 0x1158,
    partyCount: 0x1163,
    partySpecies: 0x1164,
    partyMons: 0x116B,
    pokedexOwned: 0x12F7,
    pokedexSeen: 0x130A,
    playerMoney: 0x1347,
    playerId: 0x1359,
    obtainedBadges: 0x1356,
    currentMap: 0x135E,
    playerY: 0x1361,
    playerX: 0x1362,
    playerNameLength: 11,
    partyStructLength: 44,
    partyLevelOffset: 33,
    pokedexBytes: 19,
    // Verificado contra pokered.sym real (wIsInBattle = 0xD057).
    isInBattle: 0x1057,
  );

  static const yellow = PokemonMemoryAddresses(
    playerName: 0x115C,
    partyCount: 0x1167,
    partySpecies: 0x1168,
    partyMons: 0x116F,
    pokedexOwned: 0x12FB,
    pokedexSeen: 0x130E,
    playerMoney: 0x134B,
    playerId: 0x135D,
    obtainedBadges: 0x135A,
    currentMap: 0x1362,
    playerY: 0x1365,
    playerX: 0x1366,
    playerNameLength: 11,
    partyStructLength: 44,
    partyLevelOffset: 33,
    pokedexBytes: 19,
    // Verificado contra pokeyellow.sym real (wIsInBattle = 0xD056).
    isInBattle: 0x1056,
  );

  // Pokémon Gold/Silver occidental. Offsets relativos a SYSTEM RAM (0xC000).
  // NOTA: verificado contra pokegold.sym real (money/badges/party/mapa
  // coinciden exactos). Para Silver se asume el mismo layout por compartir
  // motor con Gold — el .sym subido como "Silver" resultó ser en realidad
  // una copia de Red, así que no se pudo verificar Silver de forma
  // independiente todavía.
  static const goldSilver = PokemonMemoryAddresses(
    playerName: 0x11A3,
    playerId: 0x11A1,
    playerMoney: 0x1573,
    obtainedBadges: 0x157C,
    kantoBadges: 0x157D,
    pokedexOwned: 0x1BE4,
    pokedexSeen: 0x1C04,
    partyCount: 0x1A22,
    partySpecies: 0x1A23,
    partyMons: 0x1A2A,
    currentMapGroup: 0x1A00,
    currentMap: 0x1A01,
    playerX: 0x1A02,
    playerY: 0x1A03,
    playerNameLength: 11,
    partyStructLength: 48,
    partyLevelOffset: 31,
    pokedexBytes: 32,
    partyDvOffset: 21,
    // Verificado contra pokegold.sym real.
    battleMode: 0x1116,
    otherTrainerClass: 0x1118,
    battleResult: 0x0FE9,
    otherTrainerId: 0x111B,
  );

  // Pokémon Crystal occidental. SameBoy expone la WRAM activa como 32 KiB.
  static const crystal = PokemonMemoryAddresses(
    playerName: 0x147D,
    playerId: 0x147B,
    playerMoney: 0x184E,
    obtainedBadges: 0x1857,
    kantoBadges: 0x1858,
    pokedexOwned: 0x1E99,
    pokedexSeen: 0x1EB9,
    partyCount: 0x1CD7,
    partySpecies: 0x1CD8,
    partyMons: 0x1CDF,
    currentMapGroup: 0x1CB5,
    currentMap: 0x1CB6,
    playerY: 0x1CB8,
    playerX: 0x1CB9,
    playerNameLength: 11,
    partyStructLength: 48,
    partyLevelOffset: 31,
    pokedexBytes: 32,
    partyDvOffset: 21,
    // Verificado contra pokecrystal.sym real.
    battleMode: 0x122D,
    otherTrainerClass: 0x122F,
    battleResult: 0x10EE,
    otherTrainerId: 0x1231,
  );
}
