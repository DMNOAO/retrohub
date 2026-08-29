import 'dart:convert';
import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart' as mobile;
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart'
    as desktop;
import 'package:http/http.dart' as http;

import 'retrohub_user.dart';

class GoogleAuthService {
  static const _driveAppDataScope =
      'https://www.googleapis.com/auth/drive.appdata';
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
        _driveAppDataScope,
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

      final client = await _desktopGoogleSignIn.authenticatedClient;
      if (client == null) return null;
      try {
        return await _loadUserWithDesktopClient(client);
      } finally {
        client.close();
      }
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

      // En Windows usamos el flujo OAuth completo. Esto es importante cuando
      // RetroHub agrega permisos nuevos (por ejemplo Drive appDataFolder):
      // signIn() intenta primero una sesión ligera y podría reutilizar un token
      // antiguo que no contiene los scopes actuales.
      final credentials = await _desktopGoogleSignIn.signInOnline();
      if (credentials == null) return null;

      final client = await _desktopGoogleSignIn.authenticatedClient;
      if (client == null) {
        throw StateError(
          'Google inició sesión, pero no se pudo crear un cliente autenticado.',
        );
      }
      try {
        return await _loadUserWithDesktopClient(client);
      } finally {
        client.close();
      }
    }

    if (Platform.isAndroid) {
      await _mobileInitialization;
      final account = await _mobileGoogleSignIn.authenticate();
      // El consentimiento ocurre junto al inicio de sesión explícito. Así,
      // “Guardar y salir” nunca necesita abrir una ventana de Google.
      try {
        await account.authorizationClient.authorizeScopes(const [
          _driveAppDataScope,
        ]);
      } catch (_) {
        // La cuenta sigue siendo válida aunque el usuario posponga Drive. El
        // botón manual de RetroHub Cloud podrá solicitarlo más adelante.
      }
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

  Future<T> withDriveClient<T>(
    Future<T> Function(http.Client client) action, {
    bool requestIfNeeded = true,
  }) async {
    if (Platform.isWindows) {
      if (_clientSecret.isEmpty) {
        throw StateError(
          'Falta RETROHUB_GOOGLE_CLIENT_SECRET. Ejecuta RetroHub con --dart-define.',
        );
      }

      var credentials = await _desktopGoogleSignIn.silentSignIn();

      // Una sesión guardada puede provenir de una versión anterior de RetroHub
      // y no incluir todavía drive.appdata. En ese caso hay que eliminar esas
      // credenciales y ejecutar el flujo OAuth completo para que Google vuelva
      // a mostrar el consentimiento con los scopes actuales.
      final hasDriveScope =
          credentials?.scopes.contains(_driveAppDataScope) ?? false;

      if (credentials == null || !hasDriveScope) {
        if (credentials != null) {
          await _desktopGoogleSignIn.signOut();
        }
        credentials = await _desktopGoogleSignIn.signInOnline();
      }

      if (credentials == null ||
          !credentials.scopes.contains(_driveAppDataScope)) {
        throw StateError(
          'Google no concedió el permiso necesario para RetroHub Cloud.',
        );
      }

      final client = await _desktopGoogleSignIn.authenticatedClient;
      if (client == null) {
        throw StateError(
          'No se pudo crear un cliente autenticado para Google Drive.',
        );
      }

      try {
        return await action(client);
      } finally {
        client.close();
      }
    }

    if (Platform.isAndroid) {
      final token = await driveAccessToken(
        requestIfNeeded: requestIfNeeded,
      );
      final client = _BearerHttpClient(token);
      try {
        return await action(client);
      } finally {
        client.close();
      }
    }

    throw UnsupportedError(
      'Google Drive todavía no está configurado para esta plataforma.',
    );
  }

  Future<String> driveAccessToken({bool requestIfNeeded = true}) async {
    if (Platform.isWindows) {
      if (_clientSecret.isEmpty) {
        throw StateError(
          'Falta RETROHUB_GOOGLE_CLIENT_SECRET. Ejecuta RetroHub con --dart-define.',
        );
      }

      var credentials = await _desktopGoogleSignIn.silentSignIn();

      final hasDriveScope =
          credentials?.scopes.contains(_driveAppDataScope) ?? false;

      if (credentials == null || !hasDriveScope) {
        if (credentials != null) {
          await _desktopGoogleSignIn.signOut();
        }
        credentials = await _desktopGoogleSignIn.signInOnline();
      }

      if (credentials == null ||
          !credentials.scopes.contains(_driveAppDataScope)) {
        throw StateError(
          'Google no concedió el permiso necesario para RetroHub Cloud.',
        );
      }

      // Fuerza al paquete de escritorio a validar/renovar las credenciales.
      final client = await _desktopGoogleSignIn.authenticatedClient;
      if (client == null) {
        throw StateError(
          'No se pudo validar o renovar la autorización de Google Drive.',
        );
      }
      client.close();

      // Recupera nuevamente las credenciales persistidas después de validarlas.
      credentials = await _desktopGoogleSignIn.silentSignIn();
      if (credentials == null || credentials.accessToken.isEmpty) {
        throw StateError(
          'Google Drive no devolvió un access token válido para Windows.',
        );
      }
      return credentials.accessToken;
    }

    if (Platform.isAndroid) {
      await _mobileInitialization;
      var account =
          await _mobileGoogleSignIn.attemptLightweightAuthentication();
      account ??= await _mobileGoogleSignIn.authenticate();

      var authorization = await account.authorizationClient
          .authorizationForScopes(const [_driveAppDataScope]);

      if (authorization == null && requestIfNeeded) {
        authorization = await account.authorizationClient
            .authorizeScopes(const [_driveAppDataScope]);
      }

      if (authorization == null || authorization.accessToken.isEmpty) {
        throw StateError(
          'RetroHub necesita permiso para guardar partidas en Google Drive.',
        );
      }
      return authorization.accessToken;
    }

    throw UnsupportedError(
      'Google Drive todavía no está configurado para esta plataforma.',
    );
  }

  RetroHubUser _userFromMobileAccount(mobile.GoogleSignInAccount account) {
    return RetroHubUser.fromGoogleJson({
      'id': account.id,
      'email': account.email,
      'name': account.displayName ?? account.email,
      'picture': account.photoUrl,
    });
  }

  Future<RetroHubUser> _loadUserWithDesktopClient(dynamic client) async {
    final response = await client.get(
      Uri.parse('https://www.googleapis.com/oauth2/v2/userinfo'),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Google userinfo respondió ${response.statusCode}: ${response.body}',
      );
    }

    return RetroHubUser.fromGoogleJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
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

class _BearerHttpClient extends http.BaseClient {
  final String accessToken;
  final http.Client _inner = http.Client();

  _BearerHttpClient(this.accessToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers[HttpHeaders.authorizationHeader] = 'Bearer $accessToken';
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
