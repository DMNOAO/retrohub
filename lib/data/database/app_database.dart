import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Games extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get console => text()();
  TextColumn get romPath => text()();
  TextColumn get coverPath => text().nullable()();
  TextColumn get spriteSet => text().nullable()();
  IntColumn get playTimeHours => integer().withDefault(const Constant(0))();
  IntColumn get playTimeSeconds => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastPlayedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class JournalEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get gameId => text().references(Games, #id)();
  TextColumn get title => text().nullable()();
  TextColumn get content => text()();
  TextColumn get screenshotPath => text().nullable()();
  IntColumn get playTimeMinutes => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
}

class GameProgressSnapshots extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get gameId => text().references(Games, #id)();
  DateTimeColumn get savedAt => dateTime()();
  IntColumn get playTimeMinutes => integer().withDefault(const Constant(0))();
  TextColumn get currentLocation => text().nullable()();
  TextColumn get partyJson => text().nullable()();
  TextColumn get badgesJson => text().nullable()();
  IntColumn get badgesCount => integer().withDefault(const Constant(0))();
  IntColumn get pokedexSeen => integer().withDefault(const Constant(0))();
  IntColumn get pokedexCaught => integer().withDefault(const Constant(0))();
  TextColumn get lastCapturedPokemonJson => text().nullable()();
  TextColumn get lastDefeatedTrainer => text().nullable()();
  IntColumn get leagueWins => integer().withDefault(const Constant(0))();
}

class GameProgressEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get gameId => text().references(Games, #id)();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get eventType => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get spritePath => text().nullable()();
  TextColumn get metadataJson => text().nullable()();
}

@DriftDatabase(
  tables: [
    Games,
    JournalEntries,
    GameProgressSnapshots,
    GameProgressEvents,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(journalEntries);
        }

        if (from < 3) {
          await m.addColumn(journalEntries, journalEntries.title);
          await m.addColumn(
            journalEntries,
            journalEntries.playTimeMinutes,
          );
        }

        if (from < 4) {
          await m.createTable(gameProgressSnapshots);
          await m.createTable(gameProgressEvents);
        }

        if (from < 5) {
          await m.addColumn(games, games.spriteSet);
        }

        if (from < 7) {
          await m.addColumn(games, games.playTimeSeconds);
          await customStatement(
            'UPDATE games SET play_time_seconds = play_time_hours * 3600',
          );
        }

        // Las versiones 6, 8 y 9 no requieren cambios destructivos.
        // Los snapshots y eventos existentes se conservan íntegramente.
      },
    );
  }

  Future<List<Game>> getAllGames() {
    return select(games).get();
  }

  /// El id es el hash SHA-1 del archivo ROM: si el usuario reimporta el
  /// mismo juego, el id coincide con el que ya existe.
  ///
  /// IMPORTANTE: a diferencia de insertOnConflictUpdate (que usa el mismo
  /// companion para el INSERT y el UPDATE), aquí se usa DoUpdate para que:
  ///   - el INSERT (juego nuevo, sin conflicto) use TODOS los valores
  ///     nuevos, incluyendo createdAt (que es obligatorio y no tiene
  ///     valor por defecto — omitirlo rompe el INSERT).
  ///   - el UPDATE (juego que ya existía) preserve createdAt, tiempo
  ///     jugado y última vez jugado, y solo actualice título/consola/
  ///     romPath/portada.
  Future<void> insertGame(GamesCompanion game) {
    return into(games).insert(
      game,
      onConflict: DoUpdate(
        (old) => GamesCompanion.custom(
          title: Constant(game.title.value),
          console: Constant(game.console.value),
          romPath: Constant(game.romPath.value),
          coverPath: game.coverPath.present
              ? Constant(game.coverPath.value)
              : old.coverPath,
          spriteSet: game.spriteSet.present
              ? Constant(game.spriteSet.value)
              : old.spriteSet,
          // Progreso del usuario: nunca se pisa al reimportar.
          playTimeHours: old.playTimeHours,
          playTimeSeconds: old.playTimeSeconds,
          createdAt: old.createdAt,
          lastPlayedAt: old.lastPlayedAt,
        ),
        target: [games.id],
      ),
    );
  }

  Future<bool> gameExists(String id) async {
    final Game? existing = await getGameById(id);
    return existing != null;
  }

  Future<void> deleteGame(String id) {
    return (delete(games)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> updateGameSpriteSet(String gameId, String spriteSet) {
    return (update(games)..where((tbl) => tbl.id.equals(gameId))).write(
      GamesCompanion(
        spriteSet: Value(spriteSet),
      ),
    );
  }

  Future<List<JournalEntry>> getJournalEntriesByGame(String gameId) {
    return (select(journalEntries)
          ..where((tbl) => tbl.gameId.equals(gameId))
          ..orderBy([
            (tbl) => OrderingTerm(
                  expression: tbl.createdAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
  }

  Future<void> insertJournalEntry(JournalEntriesCompanion entry) {
    return into(journalEntries).insert(entry);
  }

  Future<void> deleteJournalEntry(int id) {
    return (delete(journalEntries)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<GameProgressSnapshot?> getLatestProgressSnapshot(String gameId) {
    return (select(gameProgressSnapshots)
          ..where((tbl) => tbl.gameId.equals(gameId))
          ..orderBy([
            (tbl) => OrderingTerm(
                  expression: tbl.savedAt,
                  mode: OrderingMode.desc,
                ),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<GameProgressSnapshot>> getProgressSnapshotsByGame(
    String gameId,
  ) {
    return (select(gameProgressSnapshots)
          ..where((tbl) => tbl.gameId.equals(gameId))
          ..orderBy([
            (tbl) => OrderingTerm(
                  expression: tbl.savedAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
  }

  Future<void> insertProgressSnapshot(
    GameProgressSnapshotsCompanion snapshot,
  ) {
    return into(gameProgressSnapshots).insert(snapshot);
  }

  Future<List<GameProgressEvent>> getProgressEventsByGame(String gameId) {
    return (select(gameProgressEvents)
          ..where((tbl) => tbl.gameId.equals(gameId))
          ..orderBy([
            (tbl) => OrderingTerm(
                  expression: tbl.createdAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
  }

  Future<void> insertProgressEvent(GameProgressEventsCompanion event) {
    return into(gameProgressEvents).insert(event);
  }


  Future<Game?> getGameById(String id) {
    return (select(games)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<Game?> getLastPlayedGame() {
    return (select(games)
          ..where((tbl) => tbl.lastPlayedAt.isNotNull())
          ..orderBy([
            (tbl) => OrderingTerm(
                  expression: tbl.lastPlayedAt,
                  mode: OrderingMode.desc,
                ),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> markGameOpened(String gameId, DateTime openedAt) {
    return (update(games)..where((tbl) => tbl.id.equals(gameId))).write(
      GamesCompanion(lastPlayedAt: Value(openedAt)),
    );
  }

  Future<void> addGamePlayTime({
    required String gameId,
    required int sessionSeconds,
    required DateTime closedAt,
  }) async {
    if (sessionSeconds <= 0) return;
    final current = await getGameById(gameId);
    if (current == null) return;
    final totalSeconds = current.playTimeSeconds + sessionSeconds;
    await (update(games)..where((tbl) => tbl.id.equals(gameId))).write(
      GamesCompanion(
        playTimeSeconds: Value(totalSeconds),
        playTimeHours: Value(totalSeconds ~/ 3600),
        lastPlayedAt: Value(closedAt),
      ),
    );
  }

  Future<List<GameProgressEvent>> getRecentProgressEvents({int limit = 8}) {
    return (select(gameProgressEvents)
          ..orderBy([
            (tbl) => OrderingTerm(
                  expression: tbl.createdAt,
                  mode: OrderingMode.desc,
                ),
          ])
          ..limit(limit))
        .get();
  }

  Future<List<JournalEntry>> getRecentJournalEntries({int limit = 8}) {
    return (select(journalEntries)
          ..orderBy([
            (tbl) => OrderingTerm(
                  expression: tbl.createdAt,
                  mode: OrderingMode.desc,
                ),
          ])
          ..limit(limit))
        .get();
  }

  Future<int> countProgressEvents() async {
    final expression = gameProgressEvents.id.count();
    final query = selectOnly(gameProgressEvents)..addColumns([expression]);
    return (await query.map((row) => row.read(expression) ?? 0).getSingle());
  }

  Future<int> countJournalEntries() async {
    final expression = journalEntries.id.count();
    final query = selectOnly(journalEntries)..addColumns([expression]);
    return (await query.map((row) => row.read(expression) ?? 0).getSingle());
  }

}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'retrohub_database',
  );
}