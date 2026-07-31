import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../data/database/app_database.dart';

abstract final class JournalEventType {
  static const String gameStarted = 'game_started';
  static const String gameClosed = 'game_closed';
  static const String saveState = 'save_state';
  static const String loadState = 'load_state';
  static const String screenshot = 'screenshot';
}

class JournalEventService {
  final AppDatabase database;
  final String gameId;

  const JournalEventService({
    required this.database,
    required this.gameId,
  });

  Future<void> logGameStarted({required int playTimeMinutes}) {
    return _insert(
      eventType: JournalEventType.gameStarted,
      title: 'Juego iniciado',
      description: 'Comenzaste una nueva sesión de juego.',
      playTimeMinutes: playTimeMinutes,
    );
  }

  Future<void> logGameClosed({
    required int playTimeMinutes,
    required int sessionDurationMinutes,
  }) {
    return _insert(
      eventType: JournalEventType.gameClosed,
      title: 'Sesión finalizada',
      description: sessionDurationMinutes <= 0
          ? 'Cerraste la sesión de juego.'
          : 'Jugaste durante ${_formatDuration(sessionDurationMinutes)}.',
      playTimeMinutes: playTimeMinutes,
      metadata: <String, dynamic>{
        'sessionDurationMinutes': sessionDurationMinutes,
      },
    );
  }

  Future<void> logSaveState({
    required int slot,
    required String title,
    required int playTimeMinutes,
  }) {
    return _insert(
      eventType: JournalEventType.saveState,
      title: 'Estado guardado',
      description: 'Guardaste "$title" en el Slot $slot.',
      playTimeMinutes: playTimeMinutes,
      metadata: <String, dynamic>{'slot': slot, 'saveTitle': title},
    );
  }

  Future<void> logLoadState({
    required int slot,
    required int playTimeMinutes,
  }) {
    return _insert(
      eventType: JournalEventType.loadState,
      title: 'Estado cargado',
      description: 'Regresaste al momento guardado en el Slot $slot.',
      playTimeMinutes: playTimeMinutes,
      metadata: <String, dynamic>{'slot': slot},
    );
  }

  Future<void> logScreenshot({
    required int playTimeMinutes,
    String? screenshotPath,
  }) {
    return _insert(
      eventType: JournalEventType.screenshot,
      title: 'Captura tomada',
      description: 'Guardaste una imagen de este momento.',
      playTimeMinutes: playTimeMinutes,
      screenshotPath: screenshotPath,
    );
  }

  Future<void> _insert({
    required String eventType,
    required String title,
    required String description,
    required int playTimeMinutes,
    Map<String, dynamic>? metadata,
    String? screenshotPath,
  }) async {
    final safeMinutes = playTimeMinutes < 0 ? 0 : playTimeMinutes;

    await database.insertProgressEvent(
      GameProgressEventsCompanion(
        gameId: Value(gameId),
        createdAt: Value(DateTime.now()),
        eventType: Value(eventType),
        title: Value(title),
        description: Value(description),
        metadataJson: Value(
          jsonEncode(<String, dynamic>{
            'playTimeMinutes': safeMinutes,
            if (screenshotPath != null) 'screenshotPath': screenshotPath,
            ...?metadata,
          }),
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    if (hours == 0) return '$remaining min';
    return '$hours h ${remaining.toString().padLeft(2, '0')} min';
  }
}
