// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $GamesTable extends Games with TableInfo<$GamesTable, Game> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GamesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _consoleMeta = const VerificationMeta(
    'console',
  );
  @override
  late final GeneratedColumn<String> console = GeneratedColumn<String>(
    'console',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _romPathMeta = const VerificationMeta(
    'romPath',
  );
  @override
  late final GeneratedColumn<String> romPath = GeneratedColumn<String>(
    'rom_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coverPathMeta = const VerificationMeta(
    'coverPath',
  );
  @override
  late final GeneratedColumn<String> coverPath = GeneratedColumn<String>(
    'cover_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _spriteSetMeta = const VerificationMeta(
    'spriteSet',
  );
  @override
  late final GeneratedColumn<String> spriteSet = GeneratedColumn<String>(
    'sprite_set',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _playTimeHoursMeta = const VerificationMeta(
    'playTimeHours',
  );
  @override
  late final GeneratedColumn<int> playTimeHours = GeneratedColumn<int>(
    'play_time_hours',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _playTimeSecondsMeta = const VerificationMeta(
    'playTimeSeconds',
  );
  @override
  late final GeneratedColumn<int> playTimeSeconds = GeneratedColumn<int>(
    'play_time_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastPlayedAtMeta = const VerificationMeta(
    'lastPlayedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPlayedAt = GeneratedColumn<DateTime>(
    'last_played_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    console,
    romPath,
    coverPath,
    spriteSet,
    playTimeHours,
    playTimeSeconds,
    createdAt,
    lastPlayedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'games';
  @override
  VerificationContext validateIntegrity(
    Insertable<Game> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('console')) {
      context.handle(
        _consoleMeta,
        console.isAcceptableOrUnknown(data['console']!, _consoleMeta),
      );
    } else if (isInserting) {
      context.missing(_consoleMeta);
    }
    if (data.containsKey('rom_path')) {
      context.handle(
        _romPathMeta,
        romPath.isAcceptableOrUnknown(data['rom_path']!, _romPathMeta),
      );
    } else if (isInserting) {
      context.missing(_romPathMeta);
    }
    if (data.containsKey('cover_path')) {
      context.handle(
        _coverPathMeta,
        coverPath.isAcceptableOrUnknown(data['cover_path']!, _coverPathMeta),
      );
    }
    if (data.containsKey('sprite_set')) {
      context.handle(
        _spriteSetMeta,
        spriteSet.isAcceptableOrUnknown(data['sprite_set']!, _spriteSetMeta),
      );
    }
    if (data.containsKey('play_time_hours')) {
      context.handle(
        _playTimeHoursMeta,
        playTimeHours.isAcceptableOrUnknown(
          data['play_time_hours']!,
          _playTimeHoursMeta,
        ),
      );
    }
    if (data.containsKey('play_time_seconds')) {
      context.handle(
        _playTimeSecondsMeta,
        playTimeSeconds.isAcceptableOrUnknown(
          data['play_time_seconds']!,
          _playTimeSecondsMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_played_at')) {
      context.handle(
        _lastPlayedAtMeta,
        lastPlayedAt.isAcceptableOrUnknown(
          data['last_played_at']!,
          _lastPlayedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Game map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Game(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      console: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}console'],
      )!,
      romPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rom_path'],
      )!,
      coverPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_path'],
      ),
      spriteSet: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sprite_set'],
      ),
      playTimeHours: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}play_time_hours'],
      )!,
      playTimeSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}play_time_seconds'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastPlayedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_played_at'],
      ),
    );
  }

  @override
  $GamesTable createAlias(String alias) {
    return $GamesTable(attachedDatabase, alias);
  }
}

class Game extends DataClass implements Insertable<Game> {
  final String id;
  final String title;
  final String console;
  final String romPath;
  final String? coverPath;
  final String? spriteSet;
  final int playTimeHours;
  final int playTimeSeconds;
  final DateTime createdAt;
  final DateTime? lastPlayedAt;
  const Game({
    required this.id,
    required this.title,
    required this.console,
    required this.romPath,
    this.coverPath,
    this.spriteSet,
    required this.playTimeHours,
    required this.playTimeSeconds,
    required this.createdAt,
    this.lastPlayedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['console'] = Variable<String>(console);
    map['rom_path'] = Variable<String>(romPath);
    if (!nullToAbsent || coverPath != null) {
      map['cover_path'] = Variable<String>(coverPath);
    }
    if (!nullToAbsent || spriteSet != null) {
      map['sprite_set'] = Variable<String>(spriteSet);
    }
    map['play_time_hours'] = Variable<int>(playTimeHours);
    map['play_time_seconds'] = Variable<int>(playTimeSeconds);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastPlayedAt != null) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt);
    }
    return map;
  }

  GamesCompanion toCompanion(bool nullToAbsent) {
    return GamesCompanion(
      id: Value(id),
      title: Value(title),
      console: Value(console),
      romPath: Value(romPath),
      coverPath: coverPath == null && nullToAbsent
          ? const Value.absent()
          : Value(coverPath),
      spriteSet: spriteSet == null && nullToAbsent
          ? const Value.absent()
          : Value(spriteSet),
      playTimeHours: Value(playTimeHours),
      playTimeSeconds: Value(playTimeSeconds),
      createdAt: Value(createdAt),
      lastPlayedAt: lastPlayedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPlayedAt),
    );
  }

  factory Game.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Game(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      console: serializer.fromJson<String>(json['console']),
      romPath: serializer.fromJson<String>(json['romPath']),
      coverPath: serializer.fromJson<String?>(json['coverPath']),
      spriteSet: serializer.fromJson<String?>(json['spriteSet']),
      playTimeHours: serializer.fromJson<int>(json['playTimeHours']),
      playTimeSeconds: serializer.fromJson<int>(json['playTimeSeconds']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastPlayedAt: serializer.fromJson<DateTime?>(json['lastPlayedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'console': serializer.toJson<String>(console),
      'romPath': serializer.toJson<String>(romPath),
      'coverPath': serializer.toJson<String?>(coverPath),
      'spriteSet': serializer.toJson<String?>(spriteSet),
      'playTimeHours': serializer.toJson<int>(playTimeHours),
      'playTimeSeconds': serializer.toJson<int>(playTimeSeconds),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastPlayedAt': serializer.toJson<DateTime?>(lastPlayedAt),
    };
  }

  Game copyWith({
    String? id,
    String? title,
    String? console,
    String? romPath,
    Value<String?> coverPath = const Value.absent(),
    Value<String?> spriteSet = const Value.absent(),
    int? playTimeHours,
    int? playTimeSeconds,
    DateTime? createdAt,
    Value<DateTime?> lastPlayedAt = const Value.absent(),
  }) => Game(
    id: id ?? this.id,
    title: title ?? this.title,
    console: console ?? this.console,
    romPath: romPath ?? this.romPath,
    coverPath: coverPath.present ? coverPath.value : this.coverPath,
    spriteSet: spriteSet.present ? spriteSet.value : this.spriteSet,
    playTimeHours: playTimeHours ?? this.playTimeHours,
    playTimeSeconds: playTimeSeconds ?? this.playTimeSeconds,
    createdAt: createdAt ?? this.createdAt,
    lastPlayedAt: lastPlayedAt.present ? lastPlayedAt.value : this.lastPlayedAt,
  );
  Game copyWithCompanion(GamesCompanion data) {
    return Game(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      console: data.console.present ? data.console.value : this.console,
      romPath: data.romPath.present ? data.romPath.value : this.romPath,
      coverPath: data.coverPath.present ? data.coverPath.value : this.coverPath,
      spriteSet: data.spriteSet.present ? data.spriteSet.value : this.spriteSet,
      playTimeHours: data.playTimeHours.present
          ? data.playTimeHours.value
          : this.playTimeHours,
      playTimeSeconds: data.playTimeSeconds.present
          ? data.playTimeSeconds.value
          : this.playTimeSeconds,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastPlayedAt: data.lastPlayedAt.present
          ? data.lastPlayedAt.value
          : this.lastPlayedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Game(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('console: $console, ')
          ..write('romPath: $romPath, ')
          ..write('coverPath: $coverPath, ')
          ..write('spriteSet: $spriteSet, ')
          ..write('playTimeHours: $playTimeHours, ')
          ..write('playTimeSeconds: $playTimeSeconds, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastPlayedAt: $lastPlayedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    console,
    romPath,
    coverPath,
    spriteSet,
    playTimeHours,
    playTimeSeconds,
    createdAt,
    lastPlayedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Game &&
          other.id == this.id &&
          other.title == this.title &&
          other.console == this.console &&
          other.romPath == this.romPath &&
          other.coverPath == this.coverPath &&
          other.spriteSet == this.spriteSet &&
          other.playTimeHours == this.playTimeHours &&
          other.playTimeSeconds == this.playTimeSeconds &&
          other.createdAt == this.createdAt &&
          other.lastPlayedAt == this.lastPlayedAt);
}

class GamesCompanion extends UpdateCompanion<Game> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> console;
  final Value<String> romPath;
  final Value<String?> coverPath;
  final Value<String?> spriteSet;
  final Value<int> playTimeHours;
  final Value<int> playTimeSeconds;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastPlayedAt;
  final Value<int> rowid;
  const GamesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.console = const Value.absent(),
    this.romPath = const Value.absent(),
    this.coverPath = const Value.absent(),
    this.spriteSet = const Value.absent(),
    this.playTimeHours = const Value.absent(),
    this.playTimeSeconds = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GamesCompanion.insert({
    required String id,
    required String title,
    required String console,
    required String romPath,
    this.coverPath = const Value.absent(),
    this.spriteSet = const Value.absent(),
    this.playTimeHours = const Value.absent(),
    this.playTimeSeconds = const Value.absent(),
    required DateTime createdAt,
    this.lastPlayedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       console = Value(console),
       romPath = Value(romPath),
       createdAt = Value(createdAt);
  static Insertable<Game> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? console,
    Expression<String>? romPath,
    Expression<String>? coverPath,
    Expression<String>? spriteSet,
    Expression<int>? playTimeHours,
    Expression<int>? playTimeSeconds,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastPlayedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (console != null) 'console': console,
      if (romPath != null) 'rom_path': romPath,
      if (coverPath != null) 'cover_path': coverPath,
      if (spriteSet != null) 'sprite_set': spriteSet,
      if (playTimeHours != null) 'play_time_hours': playTimeHours,
      if (playTimeSeconds != null) 'play_time_seconds': playTimeSeconds,
      if (createdAt != null) 'created_at': createdAt,
      if (lastPlayedAt != null) 'last_played_at': lastPlayedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GamesCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? console,
    Value<String>? romPath,
    Value<String?>? coverPath,
    Value<String?>? spriteSet,
    Value<int>? playTimeHours,
    Value<int>? playTimeSeconds,
    Value<DateTime>? createdAt,
    Value<DateTime?>? lastPlayedAt,
    Value<int>? rowid,
  }) {
    return GamesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      console: console ?? this.console,
      romPath: romPath ?? this.romPath,
      coverPath: coverPath ?? this.coverPath,
      spriteSet: spriteSet ?? this.spriteSet,
      playTimeHours: playTimeHours ?? this.playTimeHours,
      playTimeSeconds: playTimeSeconds ?? this.playTimeSeconds,
      createdAt: createdAt ?? this.createdAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (console.present) {
      map['console'] = Variable<String>(console.value);
    }
    if (romPath.present) {
      map['rom_path'] = Variable<String>(romPath.value);
    }
    if (coverPath.present) {
      map['cover_path'] = Variable<String>(coverPath.value);
    }
    if (spriteSet.present) {
      map['sprite_set'] = Variable<String>(spriteSet.value);
    }
    if (playTimeHours.present) {
      map['play_time_hours'] = Variable<int>(playTimeHours.value);
    }
    if (playTimeSeconds.present) {
      map['play_time_seconds'] = Variable<int>(playTimeSeconds.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastPlayedAt.present) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GamesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('console: $console, ')
          ..write('romPath: $romPath, ')
          ..write('coverPath: $coverPath, ')
          ..write('spriteSet: $spriteSet, ')
          ..write('playTimeHours: $playTimeHours, ')
          ..write('playTimeSeconds: $playTimeSeconds, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JournalEntriesTable extends JournalEntries
    with TableInfo<$JournalEntriesTable, JournalEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JournalEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _gameIdMeta = const VerificationMeta('gameId');
  @override
  late final GeneratedColumn<String> gameId = GeneratedColumn<String>(
    'game_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES games (id)',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _screenshotPathMeta = const VerificationMeta(
    'screenshotPath',
  );
  @override
  late final GeneratedColumn<String> screenshotPath = GeneratedColumn<String>(
    'screenshot_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _playTimeMinutesMeta = const VerificationMeta(
    'playTimeMinutes',
  );
  @override
  late final GeneratedColumn<int> playTimeMinutes = GeneratedColumn<int>(
    'play_time_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    gameId,
    title,
    content,
    screenshotPath,
    playTimeMinutes,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journal_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<JournalEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('game_id')) {
      context.handle(
        _gameIdMeta,
        gameId.isAcceptableOrUnknown(data['game_id']!, _gameIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gameIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('screenshot_path')) {
      context.handle(
        _screenshotPathMeta,
        screenshotPath.isAcceptableOrUnknown(
          data['screenshot_path']!,
          _screenshotPathMeta,
        ),
      );
    }
    if (data.containsKey('play_time_minutes')) {
      context.handle(
        _playTimeMinutesMeta,
        playTimeMinutes.isAcceptableOrUnknown(
          data['play_time_minutes']!,
          _playTimeMinutesMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JournalEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JournalEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      gameId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}game_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      screenshotPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}screenshot_path'],
      ),
      playTimeMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}play_time_minutes'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $JournalEntriesTable createAlias(String alias) {
    return $JournalEntriesTable(attachedDatabase, alias);
  }
}

class JournalEntry extends DataClass implements Insertable<JournalEntry> {
  final int id;
  final String gameId;
  final String? title;
  final String content;
  final String? screenshotPath;
  final int playTimeMinutes;
  final DateTime createdAt;
  const JournalEntry({
    required this.id,
    required this.gameId,
    this.title,
    required this.content,
    this.screenshotPath,
    required this.playTimeMinutes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['game_id'] = Variable<String>(gameId);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || screenshotPath != null) {
      map['screenshot_path'] = Variable<String>(screenshotPath);
    }
    map['play_time_minutes'] = Variable<int>(playTimeMinutes);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  JournalEntriesCompanion toCompanion(bool nullToAbsent) {
    return JournalEntriesCompanion(
      id: Value(id),
      gameId: Value(gameId),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      content: Value(content),
      screenshotPath: screenshotPath == null && nullToAbsent
          ? const Value.absent()
          : Value(screenshotPath),
      playTimeMinutes: Value(playTimeMinutes),
      createdAt: Value(createdAt),
    );
  }

  factory JournalEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JournalEntry(
      id: serializer.fromJson<int>(json['id']),
      gameId: serializer.fromJson<String>(json['gameId']),
      title: serializer.fromJson<String?>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      screenshotPath: serializer.fromJson<String?>(json['screenshotPath']),
      playTimeMinutes: serializer.fromJson<int>(json['playTimeMinutes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'gameId': serializer.toJson<String>(gameId),
      'title': serializer.toJson<String?>(title),
      'content': serializer.toJson<String>(content),
      'screenshotPath': serializer.toJson<String?>(screenshotPath),
      'playTimeMinutes': serializer.toJson<int>(playTimeMinutes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  JournalEntry copyWith({
    int? id,
    String? gameId,
    Value<String?> title = const Value.absent(),
    String? content,
    Value<String?> screenshotPath = const Value.absent(),
    int? playTimeMinutes,
    DateTime? createdAt,
  }) => JournalEntry(
    id: id ?? this.id,
    gameId: gameId ?? this.gameId,
    title: title.present ? title.value : this.title,
    content: content ?? this.content,
    screenshotPath: screenshotPath.present
        ? screenshotPath.value
        : this.screenshotPath,
    playTimeMinutes: playTimeMinutes ?? this.playTimeMinutes,
    createdAt: createdAt ?? this.createdAt,
  );
  JournalEntry copyWithCompanion(JournalEntriesCompanion data) {
    return JournalEntry(
      id: data.id.present ? data.id.value : this.id,
      gameId: data.gameId.present ? data.gameId.value : this.gameId,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      screenshotPath: data.screenshotPath.present
          ? data.screenshotPath.value
          : this.screenshotPath,
      playTimeMinutes: data.playTimeMinutes.present
          ? data.playTimeMinutes.value
          : this.playTimeMinutes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JournalEntry(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('screenshotPath: $screenshotPath, ')
          ..write('playTimeMinutes: $playTimeMinutes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    gameId,
    title,
    content,
    screenshotPath,
    playTimeMinutes,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JournalEntry &&
          other.id == this.id &&
          other.gameId == this.gameId &&
          other.title == this.title &&
          other.content == this.content &&
          other.screenshotPath == this.screenshotPath &&
          other.playTimeMinutes == this.playTimeMinutes &&
          other.createdAt == this.createdAt);
}

class JournalEntriesCompanion extends UpdateCompanion<JournalEntry> {
  final Value<int> id;
  final Value<String> gameId;
  final Value<String?> title;
  final Value<String> content;
  final Value<String?> screenshotPath;
  final Value<int> playTimeMinutes;
  final Value<DateTime> createdAt;
  const JournalEntriesCompanion({
    this.id = const Value.absent(),
    this.gameId = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.screenshotPath = const Value.absent(),
    this.playTimeMinutes = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  JournalEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String gameId,
    this.title = const Value.absent(),
    required String content,
    this.screenshotPath = const Value.absent(),
    this.playTimeMinutes = const Value.absent(),
    required DateTime createdAt,
  }) : gameId = Value(gameId),
       content = Value(content),
       createdAt = Value(createdAt);
  static Insertable<JournalEntry> custom({
    Expression<int>? id,
    Expression<String>? gameId,
    Expression<String>? title,
    Expression<String>? content,
    Expression<String>? screenshotPath,
    Expression<int>? playTimeMinutes,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (gameId != null) 'game_id': gameId,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (screenshotPath != null) 'screenshot_path': screenshotPath,
      if (playTimeMinutes != null) 'play_time_minutes': playTimeMinutes,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  JournalEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? gameId,
    Value<String?>? title,
    Value<String>? content,
    Value<String?>? screenshotPath,
    Value<int>? playTimeMinutes,
    Value<DateTime>? createdAt,
  }) {
    return JournalEntriesCompanion(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      title: title ?? this.title,
      content: content ?? this.content,
      screenshotPath: screenshotPath ?? this.screenshotPath,
      playTimeMinutes: playTimeMinutes ?? this.playTimeMinutes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (gameId.present) {
      map['game_id'] = Variable<String>(gameId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (screenshotPath.present) {
      map['screenshot_path'] = Variable<String>(screenshotPath.value);
    }
    if (playTimeMinutes.present) {
      map['play_time_minutes'] = Variable<int>(playTimeMinutes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JournalEntriesCompanion(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('screenshotPath: $screenshotPath, ')
          ..write('playTimeMinutes: $playTimeMinutes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $GameProgressSnapshotsTable extends GameProgressSnapshots
    with TableInfo<$GameProgressSnapshotsTable, GameProgressSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GameProgressSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _gameIdMeta = const VerificationMeta('gameId');
  @override
  late final GeneratedColumn<String> gameId = GeneratedColumn<String>(
    'game_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES games (id)',
    ),
  );
  static const VerificationMeta _savedAtMeta = const VerificationMeta(
    'savedAt',
  );
  @override
  late final GeneratedColumn<DateTime> savedAt = GeneratedColumn<DateTime>(
    'saved_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playTimeMinutesMeta = const VerificationMeta(
    'playTimeMinutes',
  );
  @override
  late final GeneratedColumn<int> playTimeMinutes = GeneratedColumn<int>(
    'play_time_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _currentLocationMeta = const VerificationMeta(
    'currentLocation',
  );
  @override
  late final GeneratedColumn<String> currentLocation = GeneratedColumn<String>(
    'current_location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _partyJsonMeta = const VerificationMeta(
    'partyJson',
  );
  @override
  late final GeneratedColumn<String> partyJson = GeneratedColumn<String>(
    'party_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _badgesJsonMeta = const VerificationMeta(
    'badgesJson',
  );
  @override
  late final GeneratedColumn<String> badgesJson = GeneratedColumn<String>(
    'badges_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _badgesCountMeta = const VerificationMeta(
    'badgesCount',
  );
  @override
  late final GeneratedColumn<int> badgesCount = GeneratedColumn<int>(
    'badges_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _pokedexSeenMeta = const VerificationMeta(
    'pokedexSeen',
  );
  @override
  late final GeneratedColumn<int> pokedexSeen = GeneratedColumn<int>(
    'pokedex_seen',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _pokedexCaughtMeta = const VerificationMeta(
    'pokedexCaught',
  );
  @override
  late final GeneratedColumn<int> pokedexCaught = GeneratedColumn<int>(
    'pokedex_caught',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastCapturedPokemonJsonMeta =
      const VerificationMeta('lastCapturedPokemonJson');
  @override
  late final GeneratedColumn<String> lastCapturedPokemonJson =
      GeneratedColumn<String>(
        'last_captured_pokemon_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastDefeatedTrainerMeta =
      const VerificationMeta('lastDefeatedTrainer');
  @override
  late final GeneratedColumn<String> lastDefeatedTrainer =
      GeneratedColumn<String>(
        'last_defeated_trainer',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _leagueWinsMeta = const VerificationMeta(
    'leagueWins',
  );
  @override
  late final GeneratedColumn<int> leagueWins = GeneratedColumn<int>(
    'league_wins',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    gameId,
    savedAt,
    playTimeMinutes,
    currentLocation,
    partyJson,
    badgesJson,
    badgesCount,
    pokedexSeen,
    pokedexCaught,
    lastCapturedPokemonJson,
    lastDefeatedTrainer,
    leagueWins,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'game_progress_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<GameProgressSnapshot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('game_id')) {
      context.handle(
        _gameIdMeta,
        gameId.isAcceptableOrUnknown(data['game_id']!, _gameIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gameIdMeta);
    }
    if (data.containsKey('saved_at')) {
      context.handle(
        _savedAtMeta,
        savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_savedAtMeta);
    }
    if (data.containsKey('play_time_minutes')) {
      context.handle(
        _playTimeMinutesMeta,
        playTimeMinutes.isAcceptableOrUnknown(
          data['play_time_minutes']!,
          _playTimeMinutesMeta,
        ),
      );
    }
    if (data.containsKey('current_location')) {
      context.handle(
        _currentLocationMeta,
        currentLocation.isAcceptableOrUnknown(
          data['current_location']!,
          _currentLocationMeta,
        ),
      );
    }
    if (data.containsKey('party_json')) {
      context.handle(
        _partyJsonMeta,
        partyJson.isAcceptableOrUnknown(data['party_json']!, _partyJsonMeta),
      );
    }
    if (data.containsKey('badges_json')) {
      context.handle(
        _badgesJsonMeta,
        badgesJson.isAcceptableOrUnknown(data['badges_json']!, _badgesJsonMeta),
      );
    }
    if (data.containsKey('badges_count')) {
      context.handle(
        _badgesCountMeta,
        badgesCount.isAcceptableOrUnknown(
          data['badges_count']!,
          _badgesCountMeta,
        ),
      );
    }
    if (data.containsKey('pokedex_seen')) {
      context.handle(
        _pokedexSeenMeta,
        pokedexSeen.isAcceptableOrUnknown(
          data['pokedex_seen']!,
          _pokedexSeenMeta,
        ),
      );
    }
    if (data.containsKey('pokedex_caught')) {
      context.handle(
        _pokedexCaughtMeta,
        pokedexCaught.isAcceptableOrUnknown(
          data['pokedex_caught']!,
          _pokedexCaughtMeta,
        ),
      );
    }
    if (data.containsKey('last_captured_pokemon_json')) {
      context.handle(
        _lastCapturedPokemonJsonMeta,
        lastCapturedPokemonJson.isAcceptableOrUnknown(
          data['last_captured_pokemon_json']!,
          _lastCapturedPokemonJsonMeta,
        ),
      );
    }
    if (data.containsKey('last_defeated_trainer')) {
      context.handle(
        _lastDefeatedTrainerMeta,
        lastDefeatedTrainer.isAcceptableOrUnknown(
          data['last_defeated_trainer']!,
          _lastDefeatedTrainerMeta,
        ),
      );
    }
    if (data.containsKey('league_wins')) {
      context.handle(
        _leagueWinsMeta,
        leagueWins.isAcceptableOrUnknown(data['league_wins']!, _leagueWinsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GameProgressSnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GameProgressSnapshot(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      gameId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}game_id'],
      )!,
      savedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}saved_at'],
      )!,
      playTimeMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}play_time_minutes'],
      )!,
      currentLocation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_location'],
      ),
      partyJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}party_json'],
      ),
      badgesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}badges_json'],
      ),
      badgesCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}badges_count'],
      )!,
      pokedexSeen: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pokedex_seen'],
      )!,
      pokedexCaught: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pokedex_caught'],
      )!,
      lastCapturedPokemonJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_captured_pokemon_json'],
      ),
      lastDefeatedTrainer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_defeated_trainer'],
      ),
      leagueWins: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}league_wins'],
      )!,
    );
  }

  @override
  $GameProgressSnapshotsTable createAlias(String alias) {
    return $GameProgressSnapshotsTable(attachedDatabase, alias);
  }
}

class GameProgressSnapshot extends DataClass
    implements Insertable<GameProgressSnapshot> {
  final int id;
  final String gameId;
  final DateTime savedAt;
  final int playTimeMinutes;
  final String? currentLocation;
  final String? partyJson;
  final String? badgesJson;
  final int badgesCount;
  final int pokedexSeen;
  final int pokedexCaught;
  final String? lastCapturedPokemonJson;
  final String? lastDefeatedTrainer;
  final int leagueWins;
  const GameProgressSnapshot({
    required this.id,
    required this.gameId,
    required this.savedAt,
    required this.playTimeMinutes,
    this.currentLocation,
    this.partyJson,
    this.badgesJson,
    required this.badgesCount,
    required this.pokedexSeen,
    required this.pokedexCaught,
    this.lastCapturedPokemonJson,
    this.lastDefeatedTrainer,
    required this.leagueWins,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['game_id'] = Variable<String>(gameId);
    map['saved_at'] = Variable<DateTime>(savedAt);
    map['play_time_minutes'] = Variable<int>(playTimeMinutes);
    if (!nullToAbsent || currentLocation != null) {
      map['current_location'] = Variable<String>(currentLocation);
    }
    if (!nullToAbsent || partyJson != null) {
      map['party_json'] = Variable<String>(partyJson);
    }
    if (!nullToAbsent || badgesJson != null) {
      map['badges_json'] = Variable<String>(badgesJson);
    }
    map['badges_count'] = Variable<int>(badgesCount);
    map['pokedex_seen'] = Variable<int>(pokedexSeen);
    map['pokedex_caught'] = Variable<int>(pokedexCaught);
    if (!nullToAbsent || lastCapturedPokemonJson != null) {
      map['last_captured_pokemon_json'] = Variable<String>(
        lastCapturedPokemonJson,
      );
    }
    if (!nullToAbsent || lastDefeatedTrainer != null) {
      map['last_defeated_trainer'] = Variable<String>(lastDefeatedTrainer);
    }
    map['league_wins'] = Variable<int>(leagueWins);
    return map;
  }

  GameProgressSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return GameProgressSnapshotsCompanion(
      id: Value(id),
      gameId: Value(gameId),
      savedAt: Value(savedAt),
      playTimeMinutes: Value(playTimeMinutes),
      currentLocation: currentLocation == null && nullToAbsent
          ? const Value.absent()
          : Value(currentLocation),
      partyJson: partyJson == null && nullToAbsent
          ? const Value.absent()
          : Value(partyJson),
      badgesJson: badgesJson == null && nullToAbsent
          ? const Value.absent()
          : Value(badgesJson),
      badgesCount: Value(badgesCount),
      pokedexSeen: Value(pokedexSeen),
      pokedexCaught: Value(pokedexCaught),
      lastCapturedPokemonJson: lastCapturedPokemonJson == null && nullToAbsent
          ? const Value.absent()
          : Value(lastCapturedPokemonJson),
      lastDefeatedTrainer: lastDefeatedTrainer == null && nullToAbsent
          ? const Value.absent()
          : Value(lastDefeatedTrainer),
      leagueWins: Value(leagueWins),
    );
  }

  factory GameProgressSnapshot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GameProgressSnapshot(
      id: serializer.fromJson<int>(json['id']),
      gameId: serializer.fromJson<String>(json['gameId']),
      savedAt: serializer.fromJson<DateTime>(json['savedAt']),
      playTimeMinutes: serializer.fromJson<int>(json['playTimeMinutes']),
      currentLocation: serializer.fromJson<String?>(json['currentLocation']),
      partyJson: serializer.fromJson<String?>(json['partyJson']),
      badgesJson: serializer.fromJson<String?>(json['badgesJson']),
      badgesCount: serializer.fromJson<int>(json['badgesCount']),
      pokedexSeen: serializer.fromJson<int>(json['pokedexSeen']),
      pokedexCaught: serializer.fromJson<int>(json['pokedexCaught']),
      lastCapturedPokemonJson: serializer.fromJson<String?>(
        json['lastCapturedPokemonJson'],
      ),
      lastDefeatedTrainer: serializer.fromJson<String?>(
        json['lastDefeatedTrainer'],
      ),
      leagueWins: serializer.fromJson<int>(json['leagueWins']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'gameId': serializer.toJson<String>(gameId),
      'savedAt': serializer.toJson<DateTime>(savedAt),
      'playTimeMinutes': serializer.toJson<int>(playTimeMinutes),
      'currentLocation': serializer.toJson<String?>(currentLocation),
      'partyJson': serializer.toJson<String?>(partyJson),
      'badgesJson': serializer.toJson<String?>(badgesJson),
      'badgesCount': serializer.toJson<int>(badgesCount),
      'pokedexSeen': serializer.toJson<int>(pokedexSeen),
      'pokedexCaught': serializer.toJson<int>(pokedexCaught),
      'lastCapturedPokemonJson': serializer.toJson<String?>(
        lastCapturedPokemonJson,
      ),
      'lastDefeatedTrainer': serializer.toJson<String?>(lastDefeatedTrainer),
      'leagueWins': serializer.toJson<int>(leagueWins),
    };
  }

  GameProgressSnapshot copyWith({
    int? id,
    String? gameId,
    DateTime? savedAt,
    int? playTimeMinutes,
    Value<String?> currentLocation = const Value.absent(),
    Value<String?> partyJson = const Value.absent(),
    Value<String?> badgesJson = const Value.absent(),
    int? badgesCount,
    int? pokedexSeen,
    int? pokedexCaught,
    Value<String?> lastCapturedPokemonJson = const Value.absent(),
    Value<String?> lastDefeatedTrainer = const Value.absent(),
    int? leagueWins,
  }) => GameProgressSnapshot(
    id: id ?? this.id,
    gameId: gameId ?? this.gameId,
    savedAt: savedAt ?? this.savedAt,
    playTimeMinutes: playTimeMinutes ?? this.playTimeMinutes,
    currentLocation: currentLocation.present
        ? currentLocation.value
        : this.currentLocation,
    partyJson: partyJson.present ? partyJson.value : this.partyJson,
    badgesJson: badgesJson.present ? badgesJson.value : this.badgesJson,
    badgesCount: badgesCount ?? this.badgesCount,
    pokedexSeen: pokedexSeen ?? this.pokedexSeen,
    pokedexCaught: pokedexCaught ?? this.pokedexCaught,
    lastCapturedPokemonJson: lastCapturedPokemonJson.present
        ? lastCapturedPokemonJson.value
        : this.lastCapturedPokemonJson,
    lastDefeatedTrainer: lastDefeatedTrainer.present
        ? lastDefeatedTrainer.value
        : this.lastDefeatedTrainer,
    leagueWins: leagueWins ?? this.leagueWins,
  );
  GameProgressSnapshot copyWithCompanion(GameProgressSnapshotsCompanion data) {
    return GameProgressSnapshot(
      id: data.id.present ? data.id.value : this.id,
      gameId: data.gameId.present ? data.gameId.value : this.gameId,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
      playTimeMinutes: data.playTimeMinutes.present
          ? data.playTimeMinutes.value
          : this.playTimeMinutes,
      currentLocation: data.currentLocation.present
          ? data.currentLocation.value
          : this.currentLocation,
      partyJson: data.partyJson.present ? data.partyJson.value : this.partyJson,
      badgesJson: data.badgesJson.present
          ? data.badgesJson.value
          : this.badgesJson,
      badgesCount: data.badgesCount.present
          ? data.badgesCount.value
          : this.badgesCount,
      pokedexSeen: data.pokedexSeen.present
          ? data.pokedexSeen.value
          : this.pokedexSeen,
      pokedexCaught: data.pokedexCaught.present
          ? data.pokedexCaught.value
          : this.pokedexCaught,
      lastCapturedPokemonJson: data.lastCapturedPokemonJson.present
          ? data.lastCapturedPokemonJson.value
          : this.lastCapturedPokemonJson,
      lastDefeatedTrainer: data.lastDefeatedTrainer.present
          ? data.lastDefeatedTrainer.value
          : this.lastDefeatedTrainer,
      leagueWins: data.leagueWins.present
          ? data.leagueWins.value
          : this.leagueWins,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GameProgressSnapshot(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('savedAt: $savedAt, ')
          ..write('playTimeMinutes: $playTimeMinutes, ')
          ..write('currentLocation: $currentLocation, ')
          ..write('partyJson: $partyJson, ')
          ..write('badgesJson: $badgesJson, ')
          ..write('badgesCount: $badgesCount, ')
          ..write('pokedexSeen: $pokedexSeen, ')
          ..write('pokedexCaught: $pokedexCaught, ')
          ..write('lastCapturedPokemonJson: $lastCapturedPokemonJson, ')
          ..write('lastDefeatedTrainer: $lastDefeatedTrainer, ')
          ..write('leagueWins: $leagueWins')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    gameId,
    savedAt,
    playTimeMinutes,
    currentLocation,
    partyJson,
    badgesJson,
    badgesCount,
    pokedexSeen,
    pokedexCaught,
    lastCapturedPokemonJson,
    lastDefeatedTrainer,
    leagueWins,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GameProgressSnapshot &&
          other.id == this.id &&
          other.gameId == this.gameId &&
          other.savedAt == this.savedAt &&
          other.playTimeMinutes == this.playTimeMinutes &&
          other.currentLocation == this.currentLocation &&
          other.partyJson == this.partyJson &&
          other.badgesJson == this.badgesJson &&
          other.badgesCount == this.badgesCount &&
          other.pokedexSeen == this.pokedexSeen &&
          other.pokedexCaught == this.pokedexCaught &&
          other.lastCapturedPokemonJson == this.lastCapturedPokemonJson &&
          other.lastDefeatedTrainer == this.lastDefeatedTrainer &&
          other.leagueWins == this.leagueWins);
}

class GameProgressSnapshotsCompanion
    extends UpdateCompanion<GameProgressSnapshot> {
  final Value<int> id;
  final Value<String> gameId;
  final Value<DateTime> savedAt;
  final Value<int> playTimeMinutes;
  final Value<String?> currentLocation;
  final Value<String?> partyJson;
  final Value<String?> badgesJson;
  final Value<int> badgesCount;
  final Value<int> pokedexSeen;
  final Value<int> pokedexCaught;
  final Value<String?> lastCapturedPokemonJson;
  final Value<String?> lastDefeatedTrainer;
  final Value<int> leagueWins;
  const GameProgressSnapshotsCompanion({
    this.id = const Value.absent(),
    this.gameId = const Value.absent(),
    this.savedAt = const Value.absent(),
    this.playTimeMinutes = const Value.absent(),
    this.currentLocation = const Value.absent(),
    this.partyJson = const Value.absent(),
    this.badgesJson = const Value.absent(),
    this.badgesCount = const Value.absent(),
    this.pokedexSeen = const Value.absent(),
    this.pokedexCaught = const Value.absent(),
    this.lastCapturedPokemonJson = const Value.absent(),
    this.lastDefeatedTrainer = const Value.absent(),
    this.leagueWins = const Value.absent(),
  });
  GameProgressSnapshotsCompanion.insert({
    this.id = const Value.absent(),
    required String gameId,
    required DateTime savedAt,
    this.playTimeMinutes = const Value.absent(),
    this.currentLocation = const Value.absent(),
    this.partyJson = const Value.absent(),
    this.badgesJson = const Value.absent(),
    this.badgesCount = const Value.absent(),
    this.pokedexSeen = const Value.absent(),
    this.pokedexCaught = const Value.absent(),
    this.lastCapturedPokemonJson = const Value.absent(),
    this.lastDefeatedTrainer = const Value.absent(),
    this.leagueWins = const Value.absent(),
  }) : gameId = Value(gameId),
       savedAt = Value(savedAt);
  static Insertable<GameProgressSnapshot> custom({
    Expression<int>? id,
    Expression<String>? gameId,
    Expression<DateTime>? savedAt,
    Expression<int>? playTimeMinutes,
    Expression<String>? currentLocation,
    Expression<String>? partyJson,
    Expression<String>? badgesJson,
    Expression<int>? badgesCount,
    Expression<int>? pokedexSeen,
    Expression<int>? pokedexCaught,
    Expression<String>? lastCapturedPokemonJson,
    Expression<String>? lastDefeatedTrainer,
    Expression<int>? leagueWins,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (gameId != null) 'game_id': gameId,
      if (savedAt != null) 'saved_at': savedAt,
      if (playTimeMinutes != null) 'play_time_minutes': playTimeMinutes,
      if (currentLocation != null) 'current_location': currentLocation,
      if (partyJson != null) 'party_json': partyJson,
      if (badgesJson != null) 'badges_json': badgesJson,
      if (badgesCount != null) 'badges_count': badgesCount,
      if (pokedexSeen != null) 'pokedex_seen': pokedexSeen,
      if (pokedexCaught != null) 'pokedex_caught': pokedexCaught,
      if (lastCapturedPokemonJson != null)
        'last_captured_pokemon_json': lastCapturedPokemonJson,
      if (lastDefeatedTrainer != null)
        'last_defeated_trainer': lastDefeatedTrainer,
      if (leagueWins != null) 'league_wins': leagueWins,
    });
  }

  GameProgressSnapshotsCompanion copyWith({
    Value<int>? id,
    Value<String>? gameId,
    Value<DateTime>? savedAt,
    Value<int>? playTimeMinutes,
    Value<String?>? currentLocation,
    Value<String?>? partyJson,
    Value<String?>? badgesJson,
    Value<int>? badgesCount,
    Value<int>? pokedexSeen,
    Value<int>? pokedexCaught,
    Value<String?>? lastCapturedPokemonJson,
    Value<String?>? lastDefeatedTrainer,
    Value<int>? leagueWins,
  }) {
    return GameProgressSnapshotsCompanion(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      savedAt: savedAt ?? this.savedAt,
      playTimeMinutes: playTimeMinutes ?? this.playTimeMinutes,
      currentLocation: currentLocation ?? this.currentLocation,
      partyJson: partyJson ?? this.partyJson,
      badgesJson: badgesJson ?? this.badgesJson,
      badgesCount: badgesCount ?? this.badgesCount,
      pokedexSeen: pokedexSeen ?? this.pokedexSeen,
      pokedexCaught: pokedexCaught ?? this.pokedexCaught,
      lastCapturedPokemonJson:
          lastCapturedPokemonJson ?? this.lastCapturedPokemonJson,
      lastDefeatedTrainer: lastDefeatedTrainer ?? this.lastDefeatedTrainer,
      leagueWins: leagueWins ?? this.leagueWins,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (gameId.present) {
      map['game_id'] = Variable<String>(gameId.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<DateTime>(savedAt.value);
    }
    if (playTimeMinutes.present) {
      map['play_time_minutes'] = Variable<int>(playTimeMinutes.value);
    }
    if (currentLocation.present) {
      map['current_location'] = Variable<String>(currentLocation.value);
    }
    if (partyJson.present) {
      map['party_json'] = Variable<String>(partyJson.value);
    }
    if (badgesJson.present) {
      map['badges_json'] = Variable<String>(badgesJson.value);
    }
    if (badgesCount.present) {
      map['badges_count'] = Variable<int>(badgesCount.value);
    }
    if (pokedexSeen.present) {
      map['pokedex_seen'] = Variable<int>(pokedexSeen.value);
    }
    if (pokedexCaught.present) {
      map['pokedex_caught'] = Variable<int>(pokedexCaught.value);
    }
    if (lastCapturedPokemonJson.present) {
      map['last_captured_pokemon_json'] = Variable<String>(
        lastCapturedPokemonJson.value,
      );
    }
    if (lastDefeatedTrainer.present) {
      map['last_defeated_trainer'] = Variable<String>(
        lastDefeatedTrainer.value,
      );
    }
    if (leagueWins.present) {
      map['league_wins'] = Variable<int>(leagueWins.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GameProgressSnapshotsCompanion(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('savedAt: $savedAt, ')
          ..write('playTimeMinutes: $playTimeMinutes, ')
          ..write('currentLocation: $currentLocation, ')
          ..write('partyJson: $partyJson, ')
          ..write('badgesJson: $badgesJson, ')
          ..write('badgesCount: $badgesCount, ')
          ..write('pokedexSeen: $pokedexSeen, ')
          ..write('pokedexCaught: $pokedexCaught, ')
          ..write('lastCapturedPokemonJson: $lastCapturedPokemonJson, ')
          ..write('lastDefeatedTrainer: $lastDefeatedTrainer, ')
          ..write('leagueWins: $leagueWins')
          ..write(')'))
        .toString();
  }
}

class $GameProgressEventsTable extends GameProgressEvents
    with TableInfo<$GameProgressEventsTable, GameProgressEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GameProgressEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _gameIdMeta = const VerificationMeta('gameId');
  @override
  late final GeneratedColumn<String> gameId = GeneratedColumn<String>(
    'game_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES games (id)',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _spritePathMeta = const VerificationMeta(
    'spritePath',
  );
  @override
  late final GeneratedColumn<String> spritePath = GeneratedColumn<String>(
    'sprite_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _metadataJsonMeta = const VerificationMeta(
    'metadataJson',
  );
  @override
  late final GeneratedColumn<String> metadataJson = GeneratedColumn<String>(
    'metadata_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    gameId,
    createdAt,
    eventType,
    title,
    description,
    spritePath,
    metadataJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'game_progress_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<GameProgressEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('game_id')) {
      context.handle(
        _gameIdMeta,
        gameId.isAcceptableOrUnknown(data['game_id']!, _gameIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gameIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('sprite_path')) {
      context.handle(
        _spritePathMeta,
        spritePath.isAcceptableOrUnknown(data['sprite_path']!, _spritePathMeta),
      );
    }
    if (data.containsKey('metadata_json')) {
      context.handle(
        _metadataJsonMeta,
        metadataJson.isAcceptableOrUnknown(
          data['metadata_json']!,
          _metadataJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GameProgressEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GameProgressEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      gameId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}game_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      spritePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sprite_path'],
      ),
      metadataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata_json'],
      ),
    );
  }

  @override
  $GameProgressEventsTable createAlias(String alias) {
    return $GameProgressEventsTable(attachedDatabase, alias);
  }
}

class GameProgressEvent extends DataClass
    implements Insertable<GameProgressEvent> {
  final int id;
  final String gameId;
  final DateTime createdAt;
  final String eventType;
  final String title;
  final String? description;
  final String? spritePath;
  final String? metadataJson;
  const GameProgressEvent({
    required this.id,
    required this.gameId,
    required this.createdAt,
    required this.eventType,
    required this.title,
    this.description,
    this.spritePath,
    this.metadataJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['game_id'] = Variable<String>(gameId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['event_type'] = Variable<String>(eventType);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || spritePath != null) {
      map['sprite_path'] = Variable<String>(spritePath);
    }
    if (!nullToAbsent || metadataJson != null) {
      map['metadata_json'] = Variable<String>(metadataJson);
    }
    return map;
  }

  GameProgressEventsCompanion toCompanion(bool nullToAbsent) {
    return GameProgressEventsCompanion(
      id: Value(id),
      gameId: Value(gameId),
      createdAt: Value(createdAt),
      eventType: Value(eventType),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      spritePath: spritePath == null && nullToAbsent
          ? const Value.absent()
          : Value(spritePath),
      metadataJson: metadataJson == null && nullToAbsent
          ? const Value.absent()
          : Value(metadataJson),
    );
  }

  factory GameProgressEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GameProgressEvent(
      id: serializer.fromJson<int>(json['id']),
      gameId: serializer.fromJson<String>(json['gameId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      eventType: serializer.fromJson<String>(json['eventType']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      spritePath: serializer.fromJson<String?>(json['spritePath']),
      metadataJson: serializer.fromJson<String?>(json['metadataJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'gameId': serializer.toJson<String>(gameId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'eventType': serializer.toJson<String>(eventType),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'spritePath': serializer.toJson<String?>(spritePath),
      'metadataJson': serializer.toJson<String?>(metadataJson),
    };
  }

  GameProgressEvent copyWith({
    int? id,
    String? gameId,
    DateTime? createdAt,
    String? eventType,
    String? title,
    Value<String?> description = const Value.absent(),
    Value<String?> spritePath = const Value.absent(),
    Value<String?> metadataJson = const Value.absent(),
  }) => GameProgressEvent(
    id: id ?? this.id,
    gameId: gameId ?? this.gameId,
    createdAt: createdAt ?? this.createdAt,
    eventType: eventType ?? this.eventType,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    spritePath: spritePath.present ? spritePath.value : this.spritePath,
    metadataJson: metadataJson.present ? metadataJson.value : this.metadataJson,
  );
  GameProgressEvent copyWithCompanion(GameProgressEventsCompanion data) {
    return GameProgressEvent(
      id: data.id.present ? data.id.value : this.id,
      gameId: data.gameId.present ? data.gameId.value : this.gameId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      spritePath: data.spritePath.present
          ? data.spritePath.value
          : this.spritePath,
      metadataJson: data.metadataJson.present
          ? data.metadataJson.value
          : this.metadataJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GameProgressEvent(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('createdAt: $createdAt, ')
          ..write('eventType: $eventType, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('spritePath: $spritePath, ')
          ..write('metadataJson: $metadataJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    gameId,
    createdAt,
    eventType,
    title,
    description,
    spritePath,
    metadataJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GameProgressEvent &&
          other.id == this.id &&
          other.gameId == this.gameId &&
          other.createdAt == this.createdAt &&
          other.eventType == this.eventType &&
          other.title == this.title &&
          other.description == this.description &&
          other.spritePath == this.spritePath &&
          other.metadataJson == this.metadataJson);
}

class GameProgressEventsCompanion extends UpdateCompanion<GameProgressEvent> {
  final Value<int> id;
  final Value<String> gameId;
  final Value<DateTime> createdAt;
  final Value<String> eventType;
  final Value<String> title;
  final Value<String?> description;
  final Value<String?> spritePath;
  final Value<String?> metadataJson;
  const GameProgressEventsCompanion({
    this.id = const Value.absent(),
    this.gameId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.eventType = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.spritePath = const Value.absent(),
    this.metadataJson = const Value.absent(),
  });
  GameProgressEventsCompanion.insert({
    this.id = const Value.absent(),
    required String gameId,
    required DateTime createdAt,
    required String eventType,
    required String title,
    this.description = const Value.absent(),
    this.spritePath = const Value.absent(),
    this.metadataJson = const Value.absent(),
  }) : gameId = Value(gameId),
       createdAt = Value(createdAt),
       eventType = Value(eventType),
       title = Value(title);
  static Insertable<GameProgressEvent> custom({
    Expression<int>? id,
    Expression<String>? gameId,
    Expression<DateTime>? createdAt,
    Expression<String>? eventType,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? spritePath,
    Expression<String>? metadataJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (gameId != null) 'game_id': gameId,
      if (createdAt != null) 'created_at': createdAt,
      if (eventType != null) 'event_type': eventType,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (spritePath != null) 'sprite_path': spritePath,
      if (metadataJson != null) 'metadata_json': metadataJson,
    });
  }

  GameProgressEventsCompanion copyWith({
    Value<int>? id,
    Value<String>? gameId,
    Value<DateTime>? createdAt,
    Value<String>? eventType,
    Value<String>? title,
    Value<String?>? description,
    Value<String?>? spritePath,
    Value<String?>? metadataJson,
  }) {
    return GameProgressEventsCompanion(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      createdAt: createdAt ?? this.createdAt,
      eventType: eventType ?? this.eventType,
      title: title ?? this.title,
      description: description ?? this.description,
      spritePath: spritePath ?? this.spritePath,
      metadataJson: metadataJson ?? this.metadataJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (gameId.present) {
      map['game_id'] = Variable<String>(gameId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (spritePath.present) {
      map['sprite_path'] = Variable<String>(spritePath.value);
    }
    if (metadataJson.present) {
      map['metadata_json'] = Variable<String>(metadataJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GameProgressEventsCompanion(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('createdAt: $createdAt, ')
          ..write('eventType: $eventType, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('spritePath: $spritePath, ')
          ..write('metadataJson: $metadataJson')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $GamesTable games = $GamesTable(this);
  late final $JournalEntriesTable journalEntries = $JournalEntriesTable(this);
  late final $GameProgressSnapshotsTable gameProgressSnapshots =
      $GameProgressSnapshotsTable(this);
  late final $GameProgressEventsTable gameProgressEvents =
      $GameProgressEventsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    games,
    journalEntries,
    gameProgressSnapshots,
    gameProgressEvents,
  ];
}

typedef $$GamesTableCreateCompanionBuilder =
    GamesCompanion Function({
      required String id,
      required String title,
      required String console,
      required String romPath,
      Value<String?> coverPath,
      Value<String?> spriteSet,
      Value<int> playTimeHours,
      Value<int> playTimeSeconds,
      required DateTime createdAt,
      Value<DateTime?> lastPlayedAt,
      Value<int> rowid,
    });
typedef $$GamesTableUpdateCompanionBuilder =
    GamesCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> console,
      Value<String> romPath,
      Value<String?> coverPath,
      Value<String?> spriteSet,
      Value<int> playTimeHours,
      Value<int> playTimeSeconds,
      Value<DateTime> createdAt,
      Value<DateTime?> lastPlayedAt,
      Value<int> rowid,
    });

final class $$GamesTableReferences
    extends BaseReferences<_$AppDatabase, $GamesTable, Game> {
  $$GamesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$JournalEntriesTable, List<JournalEntry>>
  _journalEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.journalEntries,
    aliasName: 'games__id__journal_entries__game_id',
  );

  $$JournalEntriesTableProcessedTableManager get journalEntriesRefs {
    final manager = $$JournalEntriesTableTableManager(
      $_db,
      $_db.journalEntries,
    ).filter((f) => f.gameId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_journalEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $GameProgressSnapshotsTable,
    List<GameProgressSnapshot>
  >
  _gameProgressSnapshotsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.gameProgressSnapshots,
        aliasName: 'games__id__game_progress_snapshots__game_id',
      );

  $$GameProgressSnapshotsTableProcessedTableManager
  get gameProgressSnapshotsRefs {
    final manager = $$GameProgressSnapshotsTableTableManager(
      $_db,
      $_db.gameProgressSnapshots,
    ).filter((f) => f.gameId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _gameProgressSnapshotsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$GameProgressEventsTable, List<GameProgressEvent>>
  _gameProgressEventsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.gameProgressEvents,
        aliasName: 'games__id__game_progress_events__game_id',
      );

  $$GameProgressEventsTableProcessedTableManager get gameProgressEventsRefs {
    final manager = $$GameProgressEventsTableTableManager(
      $_db,
      $_db.gameProgressEvents,
    ).filter((f) => f.gameId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _gameProgressEventsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$GamesTableFilterComposer extends Composer<_$AppDatabase, $GamesTable> {
  $$GamesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get console => $composableBuilder(
    column: $table.console,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get romPath => $composableBuilder(
    column: $table.romPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverPath => $composableBuilder(
    column: $table.coverPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get spriteSet => $composableBuilder(
    column: $table.spriteSet,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playTimeHours => $composableBuilder(
    column: $table.playTimeHours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playTimeSeconds => $composableBuilder(
    column: $table.playTimeSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> journalEntriesRefs(
    Expression<bool> Function($$JournalEntriesTableFilterComposer f) f,
  ) {
    final $$JournalEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.journalEntries,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JournalEntriesTableFilterComposer(
            $db: $db,
            $table: $db.journalEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> gameProgressSnapshotsRefs(
    Expression<bool> Function($$GameProgressSnapshotsTableFilterComposer f) f,
  ) {
    final $$GameProgressSnapshotsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.gameProgressSnapshots,
          getReferencedColumn: (t) => t.gameId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$GameProgressSnapshotsTableFilterComposer(
                $db: $db,
                $table: $db.gameProgressSnapshots,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> gameProgressEventsRefs(
    Expression<bool> Function($$GameProgressEventsTableFilterComposer f) f,
  ) {
    final $$GameProgressEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.gameProgressEvents,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GameProgressEventsTableFilterComposer(
            $db: $db,
            $table: $db.gameProgressEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GamesTableOrderingComposer
    extends Composer<_$AppDatabase, $GamesTable> {
  $$GamesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get console => $composableBuilder(
    column: $table.console,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get romPath => $composableBuilder(
    column: $table.romPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverPath => $composableBuilder(
    column: $table.coverPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get spriteSet => $composableBuilder(
    column: $table.spriteSet,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playTimeHours => $composableBuilder(
    column: $table.playTimeHours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playTimeSeconds => $composableBuilder(
    column: $table.playTimeSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GamesTableAnnotationComposer
    extends Composer<_$AppDatabase, $GamesTable> {
  $$GamesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get console =>
      $composableBuilder(column: $table.console, builder: (column) => column);

  GeneratedColumn<String> get romPath =>
      $composableBuilder(column: $table.romPath, builder: (column) => column);

  GeneratedColumn<String> get coverPath =>
      $composableBuilder(column: $table.coverPath, builder: (column) => column);

  GeneratedColumn<String> get spriteSet =>
      $composableBuilder(column: $table.spriteSet, builder: (column) => column);

  GeneratedColumn<int> get playTimeHours => $composableBuilder(
    column: $table.playTimeHours,
    builder: (column) => column,
  );

  GeneratedColumn<int> get playTimeSeconds => $composableBuilder(
    column: $table.playTimeSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => column,
  );

  Expression<T> journalEntriesRefs<T extends Object>(
    Expression<T> Function($$JournalEntriesTableAnnotationComposer a) f,
  ) {
    final $$JournalEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.journalEntries,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JournalEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.journalEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> gameProgressSnapshotsRefs<T extends Object>(
    Expression<T> Function($$GameProgressSnapshotsTableAnnotationComposer a) f,
  ) {
    final $$GameProgressSnapshotsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.gameProgressSnapshots,
          getReferencedColumn: (t) => t.gameId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$GameProgressSnapshotsTableAnnotationComposer(
                $db: $db,
                $table: $db.gameProgressSnapshots,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> gameProgressEventsRefs<T extends Object>(
    Expression<T> Function($$GameProgressEventsTableAnnotationComposer a) f,
  ) {
    final $$GameProgressEventsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.gameProgressEvents,
          getReferencedColumn: (t) => t.gameId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$GameProgressEventsTableAnnotationComposer(
                $db: $db,
                $table: $db.gameProgressEvents,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$GamesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GamesTable,
          Game,
          $$GamesTableFilterComposer,
          $$GamesTableOrderingComposer,
          $$GamesTableAnnotationComposer,
          $$GamesTableCreateCompanionBuilder,
          $$GamesTableUpdateCompanionBuilder,
          (Game, $$GamesTableReferences),
          Game,
          PrefetchHooks Function({
            bool journalEntriesRefs,
            bool gameProgressSnapshotsRefs,
            bool gameProgressEventsRefs,
          })
        > {
  $$GamesTableTableManager(_$AppDatabase db, $GamesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GamesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GamesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GamesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> console = const Value.absent(),
                Value<String> romPath = const Value.absent(),
                Value<String?> coverPath = const Value.absent(),
                Value<String?> spriteSet = const Value.absent(),
                Value<int> playTimeHours = const Value.absent(),
                Value<int> playTimeSeconds = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> lastPlayedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GamesCompanion(
                id: id,
                title: title,
                console: console,
                romPath: romPath,
                coverPath: coverPath,
                spriteSet: spriteSet,
                playTimeHours: playTimeHours,
                playTimeSeconds: playTimeSeconds,
                createdAt: createdAt,
                lastPlayedAt: lastPlayedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String console,
                required String romPath,
                Value<String?> coverPath = const Value.absent(),
                Value<String?> spriteSet = const Value.absent(),
                Value<int> playTimeHours = const Value.absent(),
                Value<int> playTimeSeconds = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> lastPlayedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GamesCompanion.insert(
                id: id,
                title: title,
                console: console,
                romPath: romPath,
                coverPath: coverPath,
                spriteSet: spriteSet,
                playTimeHours: playTimeHours,
                playTimeSeconds: playTimeSeconds,
                createdAt: createdAt,
                lastPlayedAt: lastPlayedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$GamesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                journalEntriesRefs = false,
                gameProgressSnapshotsRefs = false,
                gameProgressEventsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (journalEntriesRefs) db.journalEntries,
                    if (gameProgressSnapshotsRefs) db.gameProgressSnapshots,
                    if (gameProgressEventsRefs) db.gameProgressEvents,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (journalEntriesRefs)
                        await $_getPrefetchedData<
                          Game,
                          $GamesTable,
                          JournalEntry
                        >(
                          currentTable: table,
                          referencedTable: $$GamesTableReferences
                              ._journalEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GamesTableReferences(
                                db,
                                table,
                                p0,
                              ).journalEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.gameId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (gameProgressSnapshotsRefs)
                        await $_getPrefetchedData<
                          Game,
                          $GamesTable,
                          GameProgressSnapshot
                        >(
                          currentTable: table,
                          referencedTable: $$GamesTableReferences
                              ._gameProgressSnapshotsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GamesTableReferences(
                                db,
                                table,
                                p0,
                              ).gameProgressSnapshotsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.gameId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (gameProgressEventsRefs)
                        await $_getPrefetchedData<
                          Game,
                          $GamesTable,
                          GameProgressEvent
                        >(
                          currentTable: table,
                          referencedTable: $$GamesTableReferences
                              ._gameProgressEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GamesTableReferences(
                                db,
                                table,
                                p0,
                              ).gameProgressEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.gameId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$GamesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GamesTable,
      Game,
      $$GamesTableFilterComposer,
      $$GamesTableOrderingComposer,
      $$GamesTableAnnotationComposer,
      $$GamesTableCreateCompanionBuilder,
      $$GamesTableUpdateCompanionBuilder,
      (Game, $$GamesTableReferences),
      Game,
      PrefetchHooks Function({
        bool journalEntriesRefs,
        bool gameProgressSnapshotsRefs,
        bool gameProgressEventsRefs,
      })
    >;
typedef $$JournalEntriesTableCreateCompanionBuilder =
    JournalEntriesCompanion Function({
      Value<int> id,
      required String gameId,
      Value<String?> title,
      required String content,
      Value<String?> screenshotPath,
      Value<int> playTimeMinutes,
      required DateTime createdAt,
    });
typedef $$JournalEntriesTableUpdateCompanionBuilder =
    JournalEntriesCompanion Function({
      Value<int> id,
      Value<String> gameId,
      Value<String?> title,
      Value<String> content,
      Value<String?> screenshotPath,
      Value<int> playTimeMinutes,
      Value<DateTime> createdAt,
    });

final class $$JournalEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $JournalEntriesTable, JournalEntry> {
  $$JournalEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $GamesTable _gameIdTable(_$AppDatabase db) =>
      db.games.createAlias('journal_entries__game_id__games__id');

  $$GamesTableProcessedTableManager get gameId {
    final $_column = $_itemColumn<String>('game_id')!;

    final manager = $$GamesTableTableManager(
      $_db,
      $_db.games,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_gameIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$JournalEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $JournalEntriesTable> {
  $$JournalEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get screenshotPath => $composableBuilder(
    column: $table.screenshotPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playTimeMinutes => $composableBuilder(
    column: $table.playTimeMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$GamesTableFilterComposer get gameId {
    final $$GamesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableFilterComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JournalEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $JournalEntriesTable> {
  $$JournalEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get screenshotPath => $composableBuilder(
    column: $table.screenshotPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playTimeMinutes => $composableBuilder(
    column: $table.playTimeMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$GamesTableOrderingComposer get gameId {
    final $$GamesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableOrderingComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JournalEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $JournalEntriesTable> {
  $$JournalEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get screenshotPath => $composableBuilder(
    column: $table.screenshotPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get playTimeMinutes => $composableBuilder(
    column: $table.playTimeMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$GamesTableAnnotationComposer get gameId {
    final $$GamesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableAnnotationComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JournalEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JournalEntriesTable,
          JournalEntry,
          $$JournalEntriesTableFilterComposer,
          $$JournalEntriesTableOrderingComposer,
          $$JournalEntriesTableAnnotationComposer,
          $$JournalEntriesTableCreateCompanionBuilder,
          $$JournalEntriesTableUpdateCompanionBuilder,
          (JournalEntry, $$JournalEntriesTableReferences),
          JournalEntry,
          PrefetchHooks Function({bool gameId})
        > {
  $$JournalEntriesTableTableManager(
    _$AppDatabase db,
    $JournalEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JournalEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JournalEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JournalEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> gameId = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> screenshotPath = const Value.absent(),
                Value<int> playTimeMinutes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => JournalEntriesCompanion(
                id: id,
                gameId: gameId,
                title: title,
                content: content,
                screenshotPath: screenshotPath,
                playTimeMinutes: playTimeMinutes,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String gameId,
                Value<String?> title = const Value.absent(),
                required String content,
                Value<String?> screenshotPath = const Value.absent(),
                Value<int> playTimeMinutes = const Value.absent(),
                required DateTime createdAt,
              }) => JournalEntriesCompanion.insert(
                id: id,
                gameId: gameId,
                title: title,
                content: content,
                screenshotPath: screenshotPath,
                playTimeMinutes: playTimeMinutes,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$JournalEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({gameId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (gameId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.gameId,
                                referencedTable: $$JournalEntriesTableReferences
                                    ._gameIdTable(db),
                                referencedColumn:
                                    $$JournalEntriesTableReferences
                                        ._gameIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$JournalEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JournalEntriesTable,
      JournalEntry,
      $$JournalEntriesTableFilterComposer,
      $$JournalEntriesTableOrderingComposer,
      $$JournalEntriesTableAnnotationComposer,
      $$JournalEntriesTableCreateCompanionBuilder,
      $$JournalEntriesTableUpdateCompanionBuilder,
      (JournalEntry, $$JournalEntriesTableReferences),
      JournalEntry,
      PrefetchHooks Function({bool gameId})
    >;
typedef $$GameProgressSnapshotsTableCreateCompanionBuilder =
    GameProgressSnapshotsCompanion Function({
      Value<int> id,
      required String gameId,
      required DateTime savedAt,
      Value<int> playTimeMinutes,
      Value<String?> currentLocation,
      Value<String?> partyJson,
      Value<String?> badgesJson,
      Value<int> badgesCount,
      Value<int> pokedexSeen,
      Value<int> pokedexCaught,
      Value<String?> lastCapturedPokemonJson,
      Value<String?> lastDefeatedTrainer,
      Value<int> leagueWins,
    });
typedef $$GameProgressSnapshotsTableUpdateCompanionBuilder =
    GameProgressSnapshotsCompanion Function({
      Value<int> id,
      Value<String> gameId,
      Value<DateTime> savedAt,
      Value<int> playTimeMinutes,
      Value<String?> currentLocation,
      Value<String?> partyJson,
      Value<String?> badgesJson,
      Value<int> badgesCount,
      Value<int> pokedexSeen,
      Value<int> pokedexCaught,
      Value<String?> lastCapturedPokemonJson,
      Value<String?> lastDefeatedTrainer,
      Value<int> leagueWins,
    });

final class $$GameProgressSnapshotsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $GameProgressSnapshotsTable,
          GameProgressSnapshot
        > {
  $$GameProgressSnapshotsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $GamesTable _gameIdTable(_$AppDatabase db) =>
      db.games.createAlias('game_progress_snapshots__game_id__games__id');

  $$GamesTableProcessedTableManager get gameId {
    final $_column = $_itemColumn<String>('game_id')!;

    final manager = $$GamesTableTableManager(
      $_db,
      $_db.games,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_gameIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$GameProgressSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $GameProgressSnapshotsTable> {
  $$GameProgressSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playTimeMinutes => $composableBuilder(
    column: $table.playTimeMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currentLocation => $composableBuilder(
    column: $table.currentLocation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partyJson => $composableBuilder(
    column: $table.partyJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get badgesJson => $composableBuilder(
    column: $table.badgesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get badgesCount => $composableBuilder(
    column: $table.badgesCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pokedexSeen => $composableBuilder(
    column: $table.pokedexSeen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pokedexCaught => $composableBuilder(
    column: $table.pokedexCaught,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastCapturedPokemonJson => $composableBuilder(
    column: $table.lastCapturedPokemonJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastDefeatedTrainer => $composableBuilder(
    column: $table.lastDefeatedTrainer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get leagueWins => $composableBuilder(
    column: $table.leagueWins,
    builder: (column) => ColumnFilters(column),
  );

  $$GamesTableFilterComposer get gameId {
    final $$GamesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableFilterComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GameProgressSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $GameProgressSnapshotsTable> {
  $$GameProgressSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playTimeMinutes => $composableBuilder(
    column: $table.playTimeMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currentLocation => $composableBuilder(
    column: $table.currentLocation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partyJson => $composableBuilder(
    column: $table.partyJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get badgesJson => $composableBuilder(
    column: $table.badgesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get badgesCount => $composableBuilder(
    column: $table.badgesCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pokedexSeen => $composableBuilder(
    column: $table.pokedexSeen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pokedexCaught => $composableBuilder(
    column: $table.pokedexCaught,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastCapturedPokemonJson => $composableBuilder(
    column: $table.lastCapturedPokemonJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastDefeatedTrainer => $composableBuilder(
    column: $table.lastDefeatedTrainer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get leagueWins => $composableBuilder(
    column: $table.leagueWins,
    builder: (column) => ColumnOrderings(column),
  );

  $$GamesTableOrderingComposer get gameId {
    final $$GamesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableOrderingComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GameProgressSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GameProgressSnapshotsTable> {
  $$GameProgressSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => column);

  GeneratedColumn<int> get playTimeMinutes => $composableBuilder(
    column: $table.playTimeMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currentLocation => $composableBuilder(
    column: $table.currentLocation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get partyJson =>
      $composableBuilder(column: $table.partyJson, builder: (column) => column);

  GeneratedColumn<String> get badgesJson => $composableBuilder(
    column: $table.badgesJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get badgesCount => $composableBuilder(
    column: $table.badgesCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pokedexSeen => $composableBuilder(
    column: $table.pokedexSeen,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pokedexCaught => $composableBuilder(
    column: $table.pokedexCaught,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastCapturedPokemonJson => $composableBuilder(
    column: $table.lastCapturedPokemonJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastDefeatedTrainer => $composableBuilder(
    column: $table.lastDefeatedTrainer,
    builder: (column) => column,
  );

  GeneratedColumn<int> get leagueWins => $composableBuilder(
    column: $table.leagueWins,
    builder: (column) => column,
  );

  $$GamesTableAnnotationComposer get gameId {
    final $$GamesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableAnnotationComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GameProgressSnapshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GameProgressSnapshotsTable,
          GameProgressSnapshot,
          $$GameProgressSnapshotsTableFilterComposer,
          $$GameProgressSnapshotsTableOrderingComposer,
          $$GameProgressSnapshotsTableAnnotationComposer,
          $$GameProgressSnapshotsTableCreateCompanionBuilder,
          $$GameProgressSnapshotsTableUpdateCompanionBuilder,
          (GameProgressSnapshot, $$GameProgressSnapshotsTableReferences),
          GameProgressSnapshot,
          PrefetchHooks Function({bool gameId})
        > {
  $$GameProgressSnapshotsTableTableManager(
    _$AppDatabase db,
    $GameProgressSnapshotsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GameProgressSnapshotsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$GameProgressSnapshotsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$GameProgressSnapshotsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> gameId = const Value.absent(),
                Value<DateTime> savedAt = const Value.absent(),
                Value<int> playTimeMinutes = const Value.absent(),
                Value<String?> currentLocation = const Value.absent(),
                Value<String?> partyJson = const Value.absent(),
                Value<String?> badgesJson = const Value.absent(),
                Value<int> badgesCount = const Value.absent(),
                Value<int> pokedexSeen = const Value.absent(),
                Value<int> pokedexCaught = const Value.absent(),
                Value<String?> lastCapturedPokemonJson = const Value.absent(),
                Value<String?> lastDefeatedTrainer = const Value.absent(),
                Value<int> leagueWins = const Value.absent(),
              }) => GameProgressSnapshotsCompanion(
                id: id,
                gameId: gameId,
                savedAt: savedAt,
                playTimeMinutes: playTimeMinutes,
                currentLocation: currentLocation,
                partyJson: partyJson,
                badgesJson: badgesJson,
                badgesCount: badgesCount,
                pokedexSeen: pokedexSeen,
                pokedexCaught: pokedexCaught,
                lastCapturedPokemonJson: lastCapturedPokemonJson,
                lastDefeatedTrainer: lastDefeatedTrainer,
                leagueWins: leagueWins,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String gameId,
                required DateTime savedAt,
                Value<int> playTimeMinutes = const Value.absent(),
                Value<String?> currentLocation = const Value.absent(),
                Value<String?> partyJson = const Value.absent(),
                Value<String?> badgesJson = const Value.absent(),
                Value<int> badgesCount = const Value.absent(),
                Value<int> pokedexSeen = const Value.absent(),
                Value<int> pokedexCaught = const Value.absent(),
                Value<String?> lastCapturedPokemonJson = const Value.absent(),
                Value<String?> lastDefeatedTrainer = const Value.absent(),
                Value<int> leagueWins = const Value.absent(),
              }) => GameProgressSnapshotsCompanion.insert(
                id: id,
                gameId: gameId,
                savedAt: savedAt,
                playTimeMinutes: playTimeMinutes,
                currentLocation: currentLocation,
                partyJson: partyJson,
                badgesJson: badgesJson,
                badgesCount: badgesCount,
                pokedexSeen: pokedexSeen,
                pokedexCaught: pokedexCaught,
                lastCapturedPokemonJson: lastCapturedPokemonJson,
                lastDefeatedTrainer: lastDefeatedTrainer,
                leagueWins: leagueWins,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$GameProgressSnapshotsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({gameId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (gameId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.gameId,
                                referencedTable:
                                    $$GameProgressSnapshotsTableReferences
                                        ._gameIdTable(db),
                                referencedColumn:
                                    $$GameProgressSnapshotsTableReferences
                                        ._gameIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$GameProgressSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GameProgressSnapshotsTable,
      GameProgressSnapshot,
      $$GameProgressSnapshotsTableFilterComposer,
      $$GameProgressSnapshotsTableOrderingComposer,
      $$GameProgressSnapshotsTableAnnotationComposer,
      $$GameProgressSnapshotsTableCreateCompanionBuilder,
      $$GameProgressSnapshotsTableUpdateCompanionBuilder,
      (GameProgressSnapshot, $$GameProgressSnapshotsTableReferences),
      GameProgressSnapshot,
      PrefetchHooks Function({bool gameId})
    >;
typedef $$GameProgressEventsTableCreateCompanionBuilder =
    GameProgressEventsCompanion Function({
      Value<int> id,
      required String gameId,
      required DateTime createdAt,
      required String eventType,
      required String title,
      Value<String?> description,
      Value<String?> spritePath,
      Value<String?> metadataJson,
    });
typedef $$GameProgressEventsTableUpdateCompanionBuilder =
    GameProgressEventsCompanion Function({
      Value<int> id,
      Value<String> gameId,
      Value<DateTime> createdAt,
      Value<String> eventType,
      Value<String> title,
      Value<String?> description,
      Value<String?> spritePath,
      Value<String?> metadataJson,
    });

final class $$GameProgressEventsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $GameProgressEventsTable,
          GameProgressEvent
        > {
  $$GameProgressEventsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $GamesTable _gameIdTable(_$AppDatabase db) =>
      db.games.createAlias('game_progress_events__game_id__games__id');

  $$GamesTableProcessedTableManager get gameId {
    final $_column = $_itemColumn<String>('game_id')!;

    final manager = $$GamesTableTableManager(
      $_db,
      $_db.games,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_gameIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$GameProgressEventsTableFilterComposer
    extends Composer<_$AppDatabase, $GameProgressEventsTable> {
  $$GameProgressEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get spritePath => $composableBuilder(
    column: $table.spritePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnFilters(column),
  );

  $$GamesTableFilterComposer get gameId {
    final $$GamesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableFilterComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GameProgressEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $GameProgressEventsTable> {
  $$GameProgressEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get spritePath => $composableBuilder(
    column: $table.spritePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnOrderings(column),
  );

  $$GamesTableOrderingComposer get gameId {
    final $$GamesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableOrderingComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GameProgressEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GameProgressEventsTable> {
  $$GameProgressEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get spritePath => $composableBuilder(
    column: $table.spritePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => column,
  );

  $$GamesTableAnnotationComposer get gameId {
    final $$GamesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableAnnotationComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GameProgressEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GameProgressEventsTable,
          GameProgressEvent,
          $$GameProgressEventsTableFilterComposer,
          $$GameProgressEventsTableOrderingComposer,
          $$GameProgressEventsTableAnnotationComposer,
          $$GameProgressEventsTableCreateCompanionBuilder,
          $$GameProgressEventsTableUpdateCompanionBuilder,
          (GameProgressEvent, $$GameProgressEventsTableReferences),
          GameProgressEvent,
          PrefetchHooks Function({bool gameId})
        > {
  $$GameProgressEventsTableTableManager(
    _$AppDatabase db,
    $GameProgressEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GameProgressEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GameProgressEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GameProgressEventsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> gameId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> spritePath = const Value.absent(),
                Value<String?> metadataJson = const Value.absent(),
              }) => GameProgressEventsCompanion(
                id: id,
                gameId: gameId,
                createdAt: createdAt,
                eventType: eventType,
                title: title,
                description: description,
                spritePath: spritePath,
                metadataJson: metadataJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String gameId,
                required DateTime createdAt,
                required String eventType,
                required String title,
                Value<String?> description = const Value.absent(),
                Value<String?> spritePath = const Value.absent(),
                Value<String?> metadataJson = const Value.absent(),
              }) => GameProgressEventsCompanion.insert(
                id: id,
                gameId: gameId,
                createdAt: createdAt,
                eventType: eventType,
                title: title,
                description: description,
                spritePath: spritePath,
                metadataJson: metadataJson,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$GameProgressEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({gameId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (gameId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.gameId,
                                referencedTable:
                                    $$GameProgressEventsTableReferences
                                        ._gameIdTable(db),
                                referencedColumn:
                                    $$GameProgressEventsTableReferences
                                        ._gameIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$GameProgressEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GameProgressEventsTable,
      GameProgressEvent,
      $$GameProgressEventsTableFilterComposer,
      $$GameProgressEventsTableOrderingComposer,
      $$GameProgressEventsTableAnnotationComposer,
      $$GameProgressEventsTableCreateCompanionBuilder,
      $$GameProgressEventsTableUpdateCompanionBuilder,
      (GameProgressEvent, $$GameProgressEventsTableReferences),
      GameProgressEvent,
      PrefetchHooks Function({bool gameId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$GamesTableTableManager get games =>
      $$GamesTableTableManager(_db, _db.games);
  $$JournalEntriesTableTableManager get journalEntries =>
      $$JournalEntriesTableTableManager(_db, _db.journalEntries);
  $$GameProgressSnapshotsTableTableManager get gameProgressSnapshots =>
      $$GameProgressSnapshotsTableTableManager(_db, _db.gameProgressSnapshots);
  $$GameProgressEventsTableTableManager get gameProgressEvents =>
      $$GameProgressEventsTableTableManager(_db, _db.gameProgressEvents);
}
