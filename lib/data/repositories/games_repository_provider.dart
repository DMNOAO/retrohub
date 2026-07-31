import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database_provider.dart';
import 'games_repository.dart';

final gamesRepositoryProvider = Provider<GamesRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return GamesRepository(database);
});