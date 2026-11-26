import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/child_profile.dart';
import 'profile_service.dart';

/// Counts today's play time for the active child (only while the app is
/// in the foreground) and raises [timeUp] once the daily limit is reached.
/// Grown-ups can grant extra minutes for today from the time-up screen.
class PlayTimeService with WidgetsBindingObserver {
  PlayTimeService._();
  static final PlayTimeService instance = PlayTimeService._();

  static const tickSeconds = 10;

  final ValueNotifier<bool> timeUp = ValueNotifier(false);
  Timer? _timer;
  bool _foreground = true;
  int _pauses = 0;

  void start() {
    if (_timer != null) return;
    WidgetsBinding.instance.addObserver(this);
    ProfileService.active.addListener(check);
    _timer = Timer.periodic(
        const Duration(seconds: tickSeconds), (_) => tick(tickSeconds));
    check();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
  }

  /// Stop counting while grown-ups are in the parent area.
  void pause() => _pauses++;
  void resume() => _pauses = max(0, _pauses - 1);

  static String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  static String _playKey(String id) => 'play:$id:${_today()}';
  static String _bonusKey(String id) => 'bonus:$id:${_today()}';

  Future<void> tick(int seconds) async {
    final profile = ProfileService.active.value;
    if (!_foreground || _pauses > 0 || timeUp.value || profile == null) return;
    final prefs = await SharedPreferences.getInstance();
    final key = _playKey(profile.id);
    await prefs.setInt(key, (prefs.getInt(key) ?? 0) + seconds);
    await check();
  }

  Future<int> playedSecondsToday(ChildProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_playKey(profile.id)) ?? 0;
  }

  Future<void> check() async {
    final profile = ProfileService.active.value;
    if (profile == null || profile.dailyLimitMinutes == 0) {
      timeUp.value = false;
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final played = prefs.getInt(_playKey(profile.id)) ?? 0;
    final bonus = prefs.getInt(_bonusKey(profile.id)) ?? 0;
    timeUp.value = played >= (profile.dailyLimitMinutes + bonus) * 60;
  }

  /// Extra minutes for the active child, today only.
  Future<void> grantExtra(int minutes) async {
    final profile = ProfileService.active.value;
    if (profile == null) return;
    final prefs = await SharedPreferences.getInstance();
    final key = _bonusKey(profile.id);
    final prefsPlayed = prefs.getInt(_playKey(profile.id)) ?? 0;
    // Extra time starts from now, even if the child was well over the limit.
    final usedBeyond =
        max(0, prefsPlayed - (profile.dailyLimitMinutes * 60)) ~/ 60;
    final current = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, max(current, usedBeyond) + minutes);
    await check();
  }
}
