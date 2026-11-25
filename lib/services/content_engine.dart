import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/activity.dart';

/// Loads activity definitions bundled inside the app (assets/data/activities/).
/// Everything here is local — no network call, no account, no child data
/// ever leaves the device. This fully replaces the old ai_service.dart.
class ContentEngine {
  static final ContentEngine _instance = ContentEngine._internal();
  factory ContentEngine() => _instance;
  ContentEngine._internal();

  List<Activity>? _cache;

  /// List every activity file in assets/data/activities/manifest.json,
  /// then load each one. Keeping a manifest avoids needing to scan
  /// the asset bundle at runtime (Flutter can't list a folder directly).
  Future<List<Activity>> loadAll() async {
    if (_cache != null) return _cache!;

    final manifestRaw =
        await rootBundle.loadString('assets/data/activities/manifest.json');
    final manifest = jsonDecode(manifestRaw) as Map<String, dynamic>;
    final files = (manifest['files'] as List).cast<String>();

    final activities = <Activity>[];
    for (final file in files) {
      final raw = await rootBundle.loadString('assets/data/activities/$file');
      activities
          .add(Activity.fromJson(jsonDecode(raw) as Map<String, dynamic>));
    }

    _cache = activities;
    return activities;
  }

  Future<List<Activity>> loadForAge(int age) async {
    final all = await loadAll();
    return all.where((a) => age >= a.minAge && age <= a.maxAge).toList();
  }
}
