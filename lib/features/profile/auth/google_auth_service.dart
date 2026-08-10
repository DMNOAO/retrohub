import 'dart:convert';
import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart' as mobile;
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart'
    as desktop;

import 'retrohub_user.dart';

class GoogleAuthService {
  static const _webClientId =
      '678015773472-667i0le5ufnvju5dcilqjdk666fia1l0.apps.googleusercontent.com';
  static const _clientSecret = String.fromEnvironment(
    'RETROHUB_GOOGLE_CLIENT_SECRET',
  );

  late final desktop.GoogleSignIn _desktopGoogleSignIn = desktop.GoogleSignIn(
    params: desktop.GoogleSignInParams(
      clientId: Platform.isWindows ? _webClientId : null,
      clientSecret: Platform.isWindows ? _clientSecret : null,
      redirectPort: 8000,
      scopes: const [
        'https://www.googleapis.com/auth/userinfo.profile',
        'https://www.googleapis.com/auth/userinfo.email',
      ],
    ),
  );

  final mobile.GoogleSignIn _mobileGoogleSignIn = mobile.GoogleSignIn.instance;

  late final Future<void> _mobileInitialization = _mobileGoogleSignIn.initialize(
    serverClientId: _webClientId,
  );

  Future<RetroHubUser?> restoreSession() async {
    if (Platform.isWindows) {
      if (_clientSecret.isEmpty) return null;

      final credentials = await _desktopGoogleSignIn.silentSignIn();
      if (credentials == null) return null;
      return _loadUser(credentials.accessToken);
    }

    if (Platform.isAndroid) {
      await _mobileInitialization;
      final account =
          await _mobileGoogleSignIn.attemptLightweightAuthentication();
      if (account == null) return null;
      return _userFromMobileAccount(account);
    }

    return null;
  }

  Future<RetroHubUser?> signIn() async {
    if (Platform.isWindows) {
      if (_clientSecret.isEmpty) {
        throw StateError(
          'Falta RETROHUB_GOOGLE_CLIENT_SECRET. Ejecuta RetroHub con --dart-define.',
        );
      }

      final credentials = await _desktopGoogleSignIn.signIn();
      if (credentials == null) return null;
      return _loadUser(credentials.accessToken);
    }

    if (Platform.isAndroid) {
      await _mobileInitialization;
      final account = await _mobileGoogleSignIn.authenticate();
      return _userFromMobileAccount(account);
    }

    throw UnsupportedError(
      'Google Sign-In todavía no está configurado para esta plataforma.',
    );
  }

  Future<void> signOut() async {
    if (Platform.isWindows) {
      await _desktopGoogleSignIn.signOut();
      return;
    }

    if (Platform.isAndroid) {
      await _mobileInitialization;
      await _mobileGoogleSignIn.signOut();
    }
  }

  RetroHubUser _userFromMobileAccount(mobile.GoogleSignInAccount account) {
    return RetroHubUser.fromGoogleJson({
      'id': account.id,
      'email': account.email,
      'name': account.displayName ?? account.email,
      'picture': account.photoUrl,
    });
  }

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
