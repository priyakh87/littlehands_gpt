import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../models/activity.dart';
import '../models/learning_content.dart';
import '../services/content_engine.dart';
import '../services/tts_service.dart';
import 'activities/drag_match_screen.dart';
import 'animal_screen.dart';
import 'learn/abc_screen.dart';
import 'learn/color_screen.dart';
import 'learn/story_screen.dart';

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

  /// True while a button's page is open, so a double tap can't open it twice.
  bool _busy = false;

  Future<void> _open(Widget Function(LearningContent content) build) async {
    final content = await LearningContent.load();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => build(content)),
    );
  }

  Future<void> _handleStoryTime() =>
      _open((c) => StoryListScreen(stories: c.stories));

  Future<void> _handleAbc() => _open((c) => AbcScreen(letters: c.abc));

  Future<void> _handleColors() =>
      _open((c) => ColorGameScreen(colors: c.colors));

  Future<void> _openMatchingGame() async {
    final activities = await ContentEngine().loadForAge(_childAge);
    final matches = activities.where((a) => a.type == 'drag_match').toList();
    if (!mounted || matches.isEmpty) return;
    if (matches.length == 1) {
      await _startActivity(matches.first);
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

  Future<void> _startActivity(Activity activity) {
    return Navigator.push(
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
              _buildActionButton(
                  'Matching Game', Icons.extension, _openMatchingGame),
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
            if (_busy) return;
            _busy = true;
            try {
              await onPressed();
            } catch (e) {
              debugPrint('Error in $label button: $e');
            } finally {
              _busy = false;
            }
          },
        ),
      ),
    );
  }
}
