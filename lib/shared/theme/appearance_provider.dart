import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_appearance.dart';

const _appearanceKey = 'selected_app_appearance';

final appearanceProvider =
    AsyncNotifierProvider<AppearanceController, AppAppearance>(
  AppearanceController.new,
);

class AppearanceController extends AsyncNotifier<AppAppearance> {
  @override
  Future<AppAppearance> build() async {
    final preferences = await SharedPreferences.getInstance();
    return AppAppearance.fromName(preferences.getString(_appearanceKey));
  }

  Future<void> select(AppAppearance appearance) async {
    state = AsyncData(appearance);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_appearanceKey, appearance.name);
  }
}
