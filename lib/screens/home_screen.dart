import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:lottie/lottie.dart';

import '../models/activity.dart';
import '../services/content_engine.dart';
import '../services/tts_service.dart';
import 'activities/drag_match_screen.dart';
import 'animal_screen.dart';

/// Home screen of LittleHands.
///
/// Fully offline: no microphone, no network, no API keys. All content is
/// bundled in the app and narrated with the device's own TTS engine.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // TODO: replace with the active child profile's settings once profiles land.
  static const int _childAge = 3;
  static const String _languageCode = 'en';
  static const NarrationSpeed _speed = NarrationSpeed.normal;

  Map<String, dynamic> _offlineData = {};

  @override
  void initState() {
    super.initState();
    _loadOfflineData();
  }

  Future<void> _loadOfflineData() async {
    final data =
        await rootBundle.loadString('assets/data/offline_prompts.json');
    if (!mounted) return;
    setState(() => _offlineData = jsonDecode(data) as Map<String, dynamic>);
  }

  Future<void> _speak(String text) =>
      TtsService().speak(text, locale: 'en-US', speed: _speed);

  Future<void> _handleStoryTime() async {
    final stories = _offlineData['stories'] as Map<String, dynamic>?;
    await _speak(stories?.values.first as String? ?? 'Once upon a time...');
  }

  Future<void> _handleAbc() async {
    final abc = _offlineData['abc'] as Map<String, dynamic>?;
    await _speak(
        abc?.values.first as String? ?? 'A is for apple. B is for ball.');
  }

  Future<void> _handleColors() async {
    final colors = _offlineData['colors'] as Map<String, dynamic>?;
    final entry = colors?.entries.first;
    if (entry != null) {
      await _speak('Can you find something that is ${entry.key}? ${entry.value}');
    } else {
      await _speak("Let's play a color game next time.");
    }
  }

  Future<void> _openMatchingGame() async {
    final activities = await ContentEngine().loadForAge(_childAge);
    final matches = activities.where((a) => a.type == 'drag_match').toList();
    if (!mounted || matches.isEmpty) return;
    if (matches.length == 1) {
      _startActivity(matches.first);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => ListView(
        shrinkWrap: true,
        children: matches
            .map((a) => ListTile(
                  leading: const Icon(Icons.extension),
                  title: Text(_languageCode == 'ar' ? a.titleAr : a.titleEn),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _startActivity(a);
                  },
                ))
            .toList(),
      ),
    );
  }

  void _startActivity(Activity activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // fullscreenDialog disables the iOS swipe-back gesture, which would
        // otherwise steal sideways drags and close the game mid-activity.
        fullscreenDialog: true,
        builder: (routeContext) => DragMatchScreen(
          activity: activity,
          languageCode: _languageCode,
          speed: _speed,
          onComplete: (stars) {
            // TODO: persist stars via shared_preferences.
            Navigator.pop(routeContext);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LittleHands')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 200,
                child: Lottie.asset('assets/animations/mascot.json',
                    fit: BoxFit.contain),
              ),
              const SizedBox(height: 16),
              _buildActionButton('Matching Game', Icons.extension,
                  _openMatchingGame),
              _buildActionButton('Animal Sounds', Icons.pets, () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AnimalScreen()),
                );
              }),
              _buildActionButton('Story Time', Icons.book, _handleStoryTime),
              _buildActionButton('ABC Rhymes', Icons.sort_by_alpha, _handleAbc),
              _buildActionButton('Color Game', Icons.color_lens, _handleColors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, Future<void> Function() onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: Icon(icon, size: 28),
          label: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text(label, style: const TextStyle(fontSize: 18)),
          ),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () async {
            try {
              await onPressed();
            } catch (e) {
              debugPrint('Error in $label button: $e');
            }
          },
        ),
      ),
    );
  }
}
