import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/child_profile.dart';

/// Child profiles and the currently active child, stored on the device.
class ProfileService {
  static const _profilesKey = 'profiles';
  static const _activeKey = 'active_profile';

  /// The child currently playing; null until one has been created.
  static final ValueNotifier<ChildProfile?> active = ValueNotifier(null);

  static List<ChildProfile> _profiles = [];

  static List<ChildProfile> get profiles => List.unmodifiable(_profiles);

  /// Id used to keep stars and play time separate per child.
  static String get activeId => active.value?.id ?? 'default';

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profilesKey);
    _profiles = raw == null
        ? []
        : (jsonDecode(raw) as List)
            .map((p) => ChildProfile.fromJson(p as Map<String, dynamic>))
            .toList();
    final activeId = prefs.getString(_activeKey);
    active.value = _profiles.where((p) => p.id == activeId).firstOrNull ??
        _profiles.firstOrNull;
  }

  static String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  /// Adds or updates [profile]. The first child created inherits any stars
  /// earned before profiles existed, and becomes the active child.
  static Future<void> save(ChildProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final isFirst = _profiles.isEmpty;
    final i = _profiles.indexWhere((p) => p.id == profile.id);
    if (i >= 0) {
      _profiles[i] = profile;
    } else {
      _profiles.add(profile);
    }
    await _persist(prefs);
    if (isFirst) await _migrateLegacyStars(prefs, profile.id);
    if (active.value == null || active.value!.id == profile.id) {
      await setActive(profile.id);
    }
  }

  static Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    _profiles.removeWhere((p) => p.id == id);
    await _persist(prefs);
    for (final key in prefs.getKeys().toList()) {
      if (key.startsWith('stars:$id:') ||
          key.startsWith('play:$id:') ||
          key.startsWith('bonus:$id:')) {
        await prefs.remove(key);
      }
    }
    if (active.value?.id == id) {
      final next = _profiles.firstOrNull;
      if (next == null) {
        await prefs.remove(_activeKey);
        active.value = null;
      } else {
        await setActive(next.id);
      }
    }
  }

  static Future<void> setActive(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeKey, id);
    active.value = _profiles.firstWhere((p) => p.id == id);
  }

  static Future<void> _persist(SharedPreferences prefs) => prefs.setString(
      _profilesKey, jsonEncode(_profiles.map((p) => p.toJson()).toList()));

  /// Stars saved before profiles existed used keys 'stars:<activity>:<level>'
  /// (or 'stars:default:...'). Move them to the first child.
  static Future<void> _migrateLegacyStars(
      SharedPreferences prefs, String id) async {
    for (final key in prefs.getKeys().toList()) {
      if (!key.startsWith('stars:')) continue;
      final parts = key.split(':');
      String? rest;
      if (parts.length == 3) rest = '${parts[1]}:${parts[2]}';
      if (parts.length == 4 && parts[1] == 'default') {
        rest = '${parts[2]}:${parts[3]}';
      }
      if (rest == null) continue;
      final value = prefs.getInt(key);
      await prefs.remove(key);
      if (value != null) await prefs.setInt('stars:$id:$rest', value);
    }
  }

  @visibleForTesting
  static void resetForTest() {
    _profiles = [];
    active.value = null;
  }
}
