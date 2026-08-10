import 'dart:convert';

class CloudSaveManifest {
  static const int currentFormatVersion = 1;

  final int formatVersion;
  final String gameId;
  final String gameTitle;
  final String romHash;
  final DateTime createdAtUtc;
  final String sourcePlatform;
  final int sramSize;
  final int? rtcSize;

  const CloudSaveManifest({
    required this.formatVersion,
    required this.gameId,
    required this.gameTitle,
    required this.romHash,
    required this.createdAtUtc,
    required this.sourcePlatform,
    required this.sramSize,
    required this.rtcSize,
  });

  bool get hasRtc => rtcSize != null;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'formatVersion': formatVersion,
      'gameId': gameId,
      'gameTitle': gameTitle,
      'romHash': romHash,
      'createdAtUtc': createdAtUtc.toUtc().toIso8601String(),
      'sourcePlatform': sourcePlatform,
      'sramSize': sramSize,
      'rtcSize': rtcSize,
    };
  }

  String toJsonString() => const JsonEncoder.withIndent('  ').convert(toJson());

  factory CloudSaveManifest.fromJson(Map<String, dynamic> json) {
    final int formatVersion = _requiredInt(json, 'formatVersion');
    if (formatVersion != currentFormatVersion) {
      throw FormatException(
        'Versión de respaldo no compatible: $formatVersion '
        '(esperada: $currentFormatVersion).',
      );
    }

    final String gameId = _requiredString(json, 'gameId');
    final String romHash = _requiredString(json, 'romHash');
    final String gameTitle = _requiredString(json, 'gameTitle');
    final String sourcePlatform = _requiredString(json, 'sourcePlatform');
    final String createdAtRaw = _requiredString(json, 'createdAtUtc');

    final DateTime? createdAt = DateTime.tryParse(createdAtRaw);
    if (createdAt == null) {
      throw const FormatException('createdAtUtc no contiene una fecha válida.');
    }

    final int sramSize = _requiredInt(json, 'sramSize');
    if (sramSize <= 0) {
      throw const FormatException('sramSize debe ser mayor que cero.');
    }

    final Object? rtcRaw = json['rtcSize'];
    final int? rtcSize;
    if (rtcRaw == null) {
      rtcSize = null;
    } else if (rtcRaw is int && rtcRaw > 0) {
      rtcSize = rtcRaw;
    } else {
      throw const FormatException(
        'rtcSize debe ser null o un entero mayor que cero.',
      );
    }

    return CloudSaveManifest(
      formatVersion: formatVersion,
      gameId: gameId,
      gameTitle: gameTitle,
      romHash: romHash,
      createdAtUtc: createdAt.toUtc(),
      sourcePlatform: sourcePlatform,
      sramSize: sramSize,
      rtcSize: rtcSize,
    );
  }

  factory CloudSaveManifest.fromJsonString(String source) {
    final Object? decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'El manifest del respaldo no es un objeto JSON válido.',
      );
    }
    return CloudSaveManifest.fromJson(decoded);
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final Object? value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('$key es obligatorio.');
    }
    return value.trim();
  }

  static int _requiredInt(Map<String, dynamic> json, String key) {
    final Object? value = json[key];
    if (value is! int) {
      throw FormatException('$key debe ser un entero.');
    }
    return value;
  }
}
