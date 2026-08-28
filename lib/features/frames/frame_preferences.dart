import 'package:shared_preferences/shared_preferences.dart';

class FramePreferences {
  static String _key(String gameId) => 'game_frame_$gameId';

  static Future<String?> load(String gameId) async {
    final storage = await SharedPreferences.getInstance();
    return storage.getString(_key(gameId));
  }

  static Future<void> save(String gameId, String? frameId) async {
    final storage = await SharedPreferences.getInstance();
    if (frameId == null) {
      await storage.remove(_key(gameId));
    } else {
      await storage.setString(_key(gameId), frameId);
    }
  }
}
