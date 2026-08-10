import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'google_auth_service.dart';
import 'retrohub_user.dart';

final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  return GoogleAuthService();
});

final authUserProvider = FutureProvider<RetroHubUser?>((ref) async {
  final service = ref.watch(googleAuthServiceProvider);
  return service.restoreSession();
});
