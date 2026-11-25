import 'package:shared_preferences/shared_preferences.dart';

/// Stores the best star score (0–3) per activity level on the device only.
/// Nothing is synced or sent anywhere.
class ProgressService {
  static const _prefix = 'stars:';

  static String _key(String activity, int level) => '$_prefix$activity:$level';

  static Future<int> stars(String activity, int level) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key(activity, level)) ?? 0;
  }

  /// Best stars for levels 1..[count] of [activity].
  static Future<List<int>> starsForLevels(String activity, int count) async {
    final prefs = await SharedPreferences.getInstance();
    return [
      for (var l = 1; l <= count; l++) prefs.getInt(_key(activity, l)) ?? 0,
    ];
  }

  /// Saves [stars] for a level, keeping the best score ever reached.
  static Future<void> saveStars(String activity, int level, int stars) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _key(activity, level);
    final best = prefs.getInt(key) ?? 0;
    if (stars > best) await prefs.setInt(key, stars);
  }

  static Future<int> totalStars() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs
        .getKeys()
        .where((k) => k.startsWith(_prefix))
        .fold<int>(0, (sum, k) => sum + (prefs.getInt(k) ?? 0));
  }

  /// Level 1 is always open; each later level opens once the previous
  /// level has been completed (earned at least one star).
  static bool isUnlocked(List<int> stars, int index) =>
      index == 0 || stars[index - 1] > 0;

  /// 3 stars with no mistakes, 2 with up to two, otherwise 1.
  static int starsForMistakes(int mistakes) =>
      mistakes == 0 ? 3 : (mistakes <= 2 ? 2 : 1);
}
