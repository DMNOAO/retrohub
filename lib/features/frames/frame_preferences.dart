import 'package:shared_preferences/shared_preferences.dart';

class FramePreferences {
  static String _key(int gameId) => 'game_frame_$gameId';

  static Future<String?> load(int gameId) async {
    final storage = await SharedPreferences.getInstance();
    return storage.getString(_key(gameId));
  }

  static Future<void> save(int gameId, String? frameId) async {
    final storage = await SharedPreferences.getInstance();
    if (frameId == null) {
      await storage.remove(_key(gameId));
    } else {
      await storage.setString(_key(gameId), frameId);
    }
  }
}
