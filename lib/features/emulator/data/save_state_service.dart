import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../../core/emulation/core_loader.dart';
import 'models/save_slot.dart';

class SaveStateService {
  static const int slotCount = 5;

  final String gameId;
  final String romPath;

  const SaveStateService({
    required this.gameId,
    required this.romPath,
  });

  GamePersistencePaths get _paths {
    return CoreLoader.ensurePersistenceDirectories(
      gameId: gameId,
      romPath: romPath,
    );
  }

  String statePath(int slot) {
    _validateSlot(slot);
    return '${_paths.statesDirectory}${Platform.pathSeparator}'
        'slot_$slot.state';
  }

  String metadataPath(int slot) {
    _validateSlot(slot);
    return '${_paths.statesDirectory}${Platform.pathSeparator}'
        'slot_$slot.json';
  }

  String thumbnailPath(int slot) {
    _validateSlot(slot);
    return '${_paths.statesDirectory}${Platform.pathSeparator}'
        'slot_$slot.png';
  }

  Future<List<SaveSlot>> loadSlots() async {
    final List<SaveSlot> slots = <SaveSlot>[];

    for (int slot = 1; slot <= slotCount; slot++) {
      slots.add(await loadSlot(slot));
    }

    slots.sort((SaveSlot a, SaveSlot b) {
      if (a.isFavorite != b.isFavorite) {
        return a.isFavorite ? -1 : 1;
      }

      final DateTime aDate =
          a.lastUsedAt ?? a.createdAt ?? DateTime(1970);
      final DateTime bDate =
          b.lastUsedAt ?? b.createdAt ?? DateTime(1970);

      final int byRecent = bDate.compareTo(aDate);
      return byRecent != 0 ? byRecent : a.slot.compareTo(b.slot);
    });

    return slots;
  }

  Future<SaveSlot> loadSlot(int slot) async {
    _validateSlot(slot);

    final String state = statePath(slot);
    final String metadata = metadataPath(slot);
    final File stateFile = File(state);
    final File metadataFile = File(metadata);

    if (!await stateFile.exists()) {
      return SaveSlot.empty(
        slot: slot,
        statePath: state,
        metadataPath: metadata,
      );
    }

    if (!await metadataFile.exists()) {
      return SaveSlot(
        slot: slot,
        exists: true,
        title: 'Slot $slot',
        createdAt: await stateFile.lastModified(),
        playTimeMinutes: 0,
        thumbnailPath: await File(thumbnailPath(slot)).exists()
            ? thumbnailPath(slot)
            : null,
        statePath: state,
        metadataPath: metadata,
      );
    }

    try {
      final Map<String, dynamic> json =
          jsonDecode(await metadataFile.readAsString())
              as Map<String, dynamic>;

      return SaveSlot.fromJson(
        json: json,
        statePath: state,
        metadataPath: metadata,
      );
    } on Object {
      return SaveSlot(
        slot: slot,
        exists: true,
        title: 'Slot $slot',
        createdAt: await stateFile.lastModified(),
        playTimeMinutes: 0,
        thumbnailPath: await File(thumbnailPath(slot)).exists()
            ? thumbnailPath(slot)
            : null,
        statePath: state,
        metadataPath: metadata,
      );
    }
  }

  Future<void> writeMetadata({
    required int slot,
    required String title,
    required int playTimeMinutes,
    required DateTime createdAt,
    required bool hasThumbnail,
    bool? isFavorite,
    DateTime? lastUsedAt,
  }) async {
    _validateSlot(slot);

    final SaveSlot current = await loadSlot(slot);

    final SaveSlot saveSlot = SaveSlot(
      slot: slot,
      exists: true,
      title: title.trim().isEmpty ? 'Slot $slot' : title.trim(),
      createdAt: createdAt,
      playTimeMinutes: playTimeMinutes,
      thumbnailPath: hasThumbnail ? thumbnailPath(slot) : null,
      statePath: statePath(slot),
      metadataPath: metadataPath(slot),
      isFavorite: isFavorite ?? current.isFavorite,
      lastUsedAt: lastUsedAt ?? current.lastUsedAt,
    );

    await _writeMetadata(saveSlot);
  }

  Future<bool> writeThumbnail({
    required int slot,
    required Uint8List bytes,
  }) async {
    _validateSlot(slot);

    if (bytes.isEmpty) return false;

    final File file = File(thumbnailPath(slot));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);

    return true;
  }

  Future<void> deleteSlot(int slot) async {
    _validateSlot(slot);

    for (final File file in <File>[
      File(statePath(slot)),
      File(metadataPath(slot)),
      File(thumbnailPath(slot)),
    ]) {
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<void> renameSlot({
    required int slot,
    required String title,
  }) async {
    final SaveSlot current = await loadSlot(slot);
    if (!current.exists) return;

    await _writeMetadata(
      current.copyWith(
        title: title.trim().isEmpty ? 'Slot $slot' : title.trim(),
      ),
    );
  }

  Future<void> toggleFavorite(int slot) async {
    final SaveSlot current = await loadSlot(slot);
    if (!current.exists) return;

    await _writeMetadata(
      current.copyWith(isFavorite: !current.isFavorite),
    );
  }

  Future<void> markLastUsed(int slot) async {
    final SaveSlot current = await loadSlot(slot);
    if (!current.exists) return;

    await _writeMetadata(
      current.copyWith(lastUsedAt: DateTime.now()),
    );
  }

  Future<void> _writeMetadata(SaveSlot slot) async {
    final File file = File(slot.metadataPath);
    await file.parent.create(recursive: true);

    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(
      encoder.convert(slot.toJson()),
      flush: true,
    );
  }

  void _validateSlot(int slot) {
    if (slot < 1 || slot > slotCount) {
      throw RangeError.range(slot, 1, slotCount, 'slot');
    }
  }
}
