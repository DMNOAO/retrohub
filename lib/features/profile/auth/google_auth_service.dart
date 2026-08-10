import 'dart:convert';
import 'dart:io';

import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';

import 'retrohub_user.dart';

class GoogleAuthService {
  static const _webClientId =
      '678015773472-667i0le5ufnvju5dcilqjdk666fia1l0.apps.googleusercontent.com';
  static const _clientSecret = String.fromEnvironment(
    'RETROHUB_GOOGLE_CLIENT_SECRET',
  );

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    params: GoogleSignInParams(
      clientId: Platform.isWindows ? _webClientId : null,
      clientSecret: Platform.isWindows ? _clientSecret : null,
      redirectPort: 8000,
      scopes: const [
        'https://www.googleapis.com/auth/userinfo.profile',
        'https://www.googleapis.com/auth/userinfo.email',
      ],
    ),
  );

  Future<RetroHubUser?> restoreSession() async {
    if (Platform.isWindows && _clientSecret.isEmpty) return null;

    final credentials = Platform.isWindows
        ? await _googleSignIn.silentSignIn()
        : await _googleSignIn.lightweightSignIn();

    if (credentials == null) return null;
    return _loadUser(credentials.accessToken);
  }

  Future<RetroHubUser?> signIn() async {
    if (Platform.isWindows && _clientSecret.isEmpty) {
      throw StateError(
        'Falta RETROHUB_GOOGLE_CLIENT_SECRET. Ejecuta RetroHub con --dart-define.',
      );
    }

    final credentials = await _googleSignIn.signIn();
    if (credentials == null) return null;
    return _loadUser(credentials.accessToken);
  }

  Future<void> signOut() => _googleSignIn.signOut();

  Future<RetroHubUser> _loadUser(String accessToken) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(
        Uri.parse('https://www.googleapis.com/oauth2/v2/userinfo'),
      );
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Google userinfo respondió ${response.statusCode}: $body',
        );
      }

      return RetroHubUser.fromGoogleJson(
        jsonDecode(body) as Map<String, dynamic>,
      );
    } finally {
      client.close(force: true);
    }
  }
}
