enum ConsoleType {
  gb,
  gbc,
  gba,
  snes,
}

class Game {
  final String id;
  final String title;
  final ConsoleType console;
  final String cover;
  final int playTimeHours;

  const Game({
    required this.id,
    required this.title,
    required this.console,
    required this.cover,
    required this.playTimeHours,
  });

  String get consoleLabel {
    switch (console) {
      case ConsoleType.gb:
        return 'GB';

      case ConsoleType.gbc:
        return 'GBC';

      case ConsoleType.gba:
        return 'GBA';

      case ConsoleType.snes:
        return 'SNES';
    }
  }
}

final games = [
  Game(
    id: '1',
    title: 'Pokémon FireRed',
    console: ConsoleType.gba,
    cover: '',
    playTimeHours: 42,
  ),
  Game(
    id: '2',
    title: 'Pokémon Crystal',
    console: ConsoleType.gbc,
    cover: '',
    playTimeHours: 28,
  ),
  Game(
    id: '3',
    title: 'Super Mario World',
    console: ConsoleType.snes,
    cover: '',
    playTimeHours: 12,
  ),
];