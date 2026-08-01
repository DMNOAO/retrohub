import 'package:drift/drift.dart';

import '../database/app_database.dart';

class GamesRepository {
  final AppDatabase database;

  GamesRepository(this.database);

  Future<List<Game>> getGames() => database.getAllGames();
  Future<Game?> getGameById(String id) => database.getGameById(id);
  Future<Game?> getLastPlayedGame() => database.getLastPlayedGame();
  Future<bool> gameExists(String id) => database.gameExists(id);

  Future<void> addGame({
    required String id,
    required String title,
    required String console,
    required String romPath,
    String? coverPath,
  }) {
    return database.insertGame(
      GamesCompanion.insert(
        id: id,
        title: title,
        console: console,
        romPath: romPath,
        coverPath: Value(coverPath),
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> markOpened(String gameId, DateTime openedAt) {
    return database.markGameOpened(gameId, openedAt);
  }

  Future<void> addPlayTime({
    required String gameId,
    required int sessionSeconds,
    required DateTime closedAt,
  }) {
    return database.addGamePlayTime(
      gameId: gameId,
      sessionSeconds: sessionSeconds,
      closedAt: closedAt,
    );
  }

  Future<void> deleteGame(String id) => database.deleteGame(id);
}
