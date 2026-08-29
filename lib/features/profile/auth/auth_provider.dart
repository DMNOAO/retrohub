import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'google_auth_service.dart';
import 'retrohub_user.dart';

final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  return GoogleAuthService();
});

final authUserProvider = FutureProvider<RetroHubUser?>((ref) async {
  final service = ref.watch(googleAuthServiceProvider);
  final results = await Future.wait<Object?>([
    service.restoreSession(),
    // Evita un destello de la pantalla principal en dispositivos rápidos y
    // deja que la pantalla de arranque comunique que RetroHub está listo.
    Future<void>.delayed(const Duration(milliseconds: 650)),
  ]);
  return results.first as RetroHubUser?;
});
