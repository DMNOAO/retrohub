import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../auth/google_auth_service.dart';
import 'cloud_save_local_service.dart';
import 'cloud_save_manifest.dart';

class GoogleDriveCloudBackup {
  final CloudSaveManifest manifest;
  final String manifestFileId;
  final String sramFileId;
  final String? rtcFileId;

  const GoogleDriveCloudBackup({
    required this.manifest,
    required this.manifestFileId,
    required this.sramFileId,
    required this.rtcFileId,
  });
}

class GoogleDriveSaveService {
  static const String _apiBase = 'https://www.googleapis.com/drive/v3/files';
  static const String _uploadBase =
      'https://www.googleapis.com/upload/drive/v3/files';

  final GoogleAuthService authService;

  const GoogleDriveSaveService({required this.authService});

  Future<GoogleDriveCloudBackup> uploadBackup(
    LocalCloudSaveBackup backup, {
    required String cloudGameId,
  }) async {
    return authService.withDriveClient((client) async {
      final manifestName = _name(cloudGameId, 'manifest.json');
      final sramName = _name(cloudGameId, 'game.srm');
      final rtcName = _name(cloudGameId, 'game.rtc');

      await _deleteByName(client, manifestName);
      await _deleteByName(client, sramName);
      await _deleteByName(client, rtcName);

      final manifestId = await _uploadFile(
        client: client,
        name: manifestName,
        file: backup.manifestFile,
        mimeType: 'application/json',
      );
      final sramId = await _uploadFile(
        client: client,
        name: sramName,
        file: backup.sramFile,
        mimeType: 'application/octet-stream',
      );

      String? rtcId;
      if (backup.manifest.hasRtc && await backup.rtcFile.exists()) {
        rtcId = await _uploadFile(
          client: client,
          name: rtcName,
          file: backup.rtcFile,
          mimeType: 'application/octet-stream',
        );
      }

      return GoogleDriveCloudBackup(
        manifest: backup.manifest,
        manifestFileId: manifestId,
        sramFileId: sramId,
        rtcFileId: rtcId,
      );
    });
  }

  Future<Directory?> downloadBackup({
    required String gameId,
    required Directory destinationRoot,
  }) async {
    return authService.withDriveClient((client) async {
      final manifestRemote = await _findByName(
        client,
        _name(gameId, 'manifest.json'),
      );
      final sramRemote = await _findByName(client, _name(gameId, 'game.srm'));

      if (manifestRemote == null || sramRemote == null) {
        return null;
      }

      final manifestBytes = await _download(client, manifestRemote.id);
      final manifest = CloudSaveManifest.fromJsonString(
        utf8.decode(manifestBytes),
      );
      if (manifest.romHash != gameId) {
        throw StateError('El respaldo remoto pertenece a otra ROM.');
      }

      final directory = Directory(
        '${destinationRoot.path}${Platform.pathSeparator}'
        'drive_${_safe(gameId)}_${DateTime.now().millisecondsSinceEpoch}',
      );
      await directory.create(recursive: true);

      try {
        await File(
          '${directory.path}${Platform.pathSeparator}manifest.json',
        ).writeAsBytes(manifestBytes, flush: true);

        await File(
          '${directory.path}${Platform.pathSeparator}game.srm',
        ).writeAsBytes(
          await _download(client, sramRemote.id),
          flush: true,
        );

        if (manifest.hasRtc) {
          final rtcRemote = await _findByName(
            client,
            _name(gameId, 'game.rtc'),
          );
          if (rtcRemote == null) {
            throw StateError('El respaldo remoto declara RTC pero no existe.');
          }
          await File(
            '${directory.path}${Platform.pathSeparator}game.rtc',
          ).writeAsBytes(
            await _download(client, rtcRemote.id),
            flush: true,
          );
        }

        return directory;
      } catch (_) {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
        rethrow;
      }
    });
  }

  Future<String> _uploadFile({
    required http.Client client,
    required String name,
    required File file,
    required String mimeType,
  }) async {
    final boundary =
        'retrohub_${DateTime.now().microsecondsSinceEpoch}_${file.lengthSync()}';
    final metadata = jsonEncode({
      'name': name,
      'parents': ['appDataFolder'],
      'appProperties': {'retrohub': 'cloud-save'},
    });
    final bytes = await file.readAsBytes();

    final builder = BytesBuilder();
    builder.add(utf8.encode('--$boundary\r\n'));
    builder.add(
      utf8.encode('Content-Type: application/json; charset=UTF-8\r\n\r\n'),
    );
    builder.add(utf8.encode(metadata));
    builder.add(utf8.encode('\r\n--$boundary\r\n'));
    builder.add(utf8.encode('Content-Type: $mimeType\r\n\r\n'));
    builder.add(bytes);
    builder.add(utf8.encode('\r\n--$boundary--'));

    final uri = Uri.parse('$_uploadBase?uploadType=multipart&fields=id');
    final response = await client.post(
      uri,
      headers: {
        HttpHeaders.contentTypeHeader: 'multipart/related; boundary=$boundary',
      },
      body: builder.takeBytes(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Google Drive upload respondió ${response.statusCode}: ${response.body}',
      );
    }

    return (jsonDecode(response.body) as Map<String, dynamic>)['id'] as String;
  }

  Future<_RemoteFile?> _findByName(
    http.Client client,
    String name,
  ) async {
    final escaped = name.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
    final uri = Uri.parse(_apiBase).replace(
      queryParameters: {
        'spaces': 'appDataFolder',
        'q': "name = '$escaped' and trashed = false",
        'fields': 'files(id,name,modifiedTime)',
        'pageSize': '10',
      },
    );

    final decoded = await _jsonRequest(client, uri);
    final files = (decoded['files'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    if (files.isEmpty) return null;

    files.sort(
      (a, b) => (b['modifiedTime'] as String? ?? '')
          .compareTo(a['modifiedTime'] as String? ?? ''),
    );

    final file = files.first;
    return _RemoteFile(
      id: file['id'] as String,
      name: file['name'] as String,
    );
  }

  Future<void> _deleteByName(
    http.Client client,
    String name,
  ) async {
    while (true) {
      final remote = await _findByName(client, name);
      if (remote == null) return;

      final response = await client.delete(
        Uri.parse('$_apiBase/${remote.id}'),
      );
      if (response.statusCode != 204 &&
          (response.statusCode < 200 || response.statusCode >= 300)) {
        throw HttpException(
          'Google Drive delete respondió ${response.statusCode}: '
          '${response.body}',
        );
      }
    }
  }

  Future<List<int>> _download(
    http.Client client,
    String fileId,
  ) async {
    final uri = Uri.parse('$_apiBase/$fileId').replace(
      queryParameters: {'alt': 'media'},
    );
    final response = await client.get(uri);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Google Drive download respondió ${response.statusCode}: '
        '${utf8.decode(response.bodyBytes, allowMalformed: true)}',
      );
    }

    return response.bodyBytes;
  }

  Future<Map<String, dynamic>> _jsonRequest(
    http.Client client,
    Uri uri,
  ) async {
    final response = await client.get(
      uri,
      headers: {HttpHeaders.acceptHeader: 'application/json'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Google Drive respondió ${response.statusCode}: ${response.body}',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  String _name(String gameId, String suffix) =>
      'retrohub_${_safe(gameId)}_$suffix';

  String _safe(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_-]+'), '_');
}

class _RemoteFile {
  final String id;
  final String name;

  const _RemoteFile({required this.id, required this.name});
}
