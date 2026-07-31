class SaveSlot {
  final int slot;
  final bool exists;
  final String title;
  final DateTime? createdAt;
  final int playTimeMinutes;
  final String? thumbnailPath;
  final String statePath;
  final String metadataPath;
  final bool isFavorite;
  final DateTime? lastUsedAt;

  const SaveSlot({
    required this.slot,
    required this.exists,
    required this.title,
    required this.createdAt,
    required this.playTimeMinutes,
    required this.thumbnailPath,
    required this.statePath,
    required this.metadataPath,
    this.isFavorite = false,
    this.lastUsedAt,
  });

  factory SaveSlot.empty({
    required int slot,
    required String statePath,
    required String metadataPath,
  }) {
    return SaveSlot(
      slot: slot,
      exists: false,
      title: 'Slot $slot',
      createdAt: null,
      playTimeMinutes: 0,
      thumbnailPath: null,
      statePath: statePath,
      metadataPath: metadataPath,
    );
  }

  factory SaveSlot.fromJson({
    required Map<String, dynamic> json,
    required String statePath,
    required String metadataPath,
  }) {
    final int slot = (json['slot'] as num?)?.toInt() ?? 1;
    final String? rawDate = json['createdAt'] as String?;
    final String? rawLastUsed = json['lastUsedAt'] as String?;

    return SaveSlot(
      slot: slot,
      exists: true,
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? (json['title'] as String).trim()
          : 'Slot $slot',
      createdAt: rawDate == null ? null : DateTime.tryParse(rawDate),
      playTimeMinutes:
          (json['playTimeMinutes'] as num?)?.toInt() ?? 0,
      thumbnailPath: json['thumbnailPath'] as String?,
      statePath: statePath,
      metadataPath: metadataPath,
      isFavorite: json['isFavorite'] as bool? ?? false,
      lastUsedAt:
          rawLastUsed == null ? null : DateTime.tryParse(rawLastUsed),
    );
  }

  SaveSlot copyWith({
    String? title,
    bool? isFavorite,
    DateTime? lastUsedAt,
  }) {
    return SaveSlot(
      slot: slot,
      exists: exists,
      title: title ?? this.title,
      createdAt: createdAt,
      playTimeMinutes: playTimeMinutes,
      thumbnailPath: thumbnailPath,
      statePath: statePath,
      metadataPath: metadataPath,
      isFavorite: isFavorite ?? this.isFavorite,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'slot': slot,
      'title': title,
      'createdAt': createdAt?.toIso8601String(),
      'playTimeMinutes': playTimeMinutes,
      'thumbnailPath': thumbnailPath,
      'isFavorite': isFavorite,
      'lastUsedAt': lastUsedAt?.toIso8601String(),
    };
  }

  String get formattedPlayTime {
    final int safeMinutes = playTimeMinutes < 0 ? 0 : playTimeMinutes;
    final int hours = safeMinutes ~/ 60;
    final int minutes = safeMinutes % 60;

    if (hours == 0) {
      return '$minutes min';
    }

    return '$hours h ${minutes.toString().padLeft(2, '0')} min';
  }

  String get formattedDate => _formatDate(createdAt, 'Sin fecha');

  String get formattedLastUsed =>
      _formatDate(lastUsedAt, 'Nunca utilizado');

  String _formatDate(DateTime? date, String fallback) {
    if (date == null) return fallback;

    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();
    final String hour = date.hour.toString().padLeft(2, '0');
    final String minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year · $hour:$minute';
  }
}
