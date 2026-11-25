import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../models/learning_content.dart';
import '../services/content_engine.dart';
import '../services/progress_service.dart';
import '../services/tts_service.dart';
import 'activities/drag_match_screen.dart';
import 'animal_screen.dart';
import 'learn/abc_screen.dart';
import 'learn/color_screen.dart';
import 'learn/story_screen.dart';
import 'levels_screen.dart';

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
  int _totalStars = 0;

  @override
  void initState() {
    super.initState();
    _refreshStars();
  }

  Future<void> _refreshStars() async {
    final total = await ProgressService.totalStars();
    if (mounted) setState(() => _totalStars = total);
  }

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

  Future<void> _handleAbc() => _open((c) => LevelsScreen(
        activityKey: 'abc',
        title: 'ABC Rhymes',
        levels: [
          for (final l in c.abcLevels)
            LevelInfo(title: l.title, emoji: l.emoji),
        ],
        buildLevel: (_, i, onComplete) => AbcLevelScreen(
          level: c.abcLevels[i],
          letters: c.abc,
          onComplete: onComplete,
        ),
      ));

  Future<void> _handleColors() => _open((c) => LevelsScreen(
        activityKey: 'colors',
        title: 'Color Game',
        levels: [
          for (final l in c.colorLevels)
            LevelInfo(title: l.title, emoji: l.emoji),
        ],
        buildLevel: (_, i, onComplete) => ColorLevelScreen(
          level: c.colorLevels[i],
          content: c,
          onComplete: onComplete,
        ),
      ));

  Future<void> _openMatchingGame() async {
    final activities = await ContentEngine().loadForAge(_childAge);
    final matches = activities.where((a) => a.type == 'drag_match').toList()
      ..sort((a, b) => a.level.compareTo(b.level));
    if (!mounted || matches.isEmpty) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LevelsScreen(
          activityKey: 'matching',
          title: 'Matching Game',
          levels: [
            for (final a in matches)
              LevelInfo(
                  title: _languageCode == 'ar' ? a.titleAr : a.titleEn,
                  emoji: '🧩'),
          ],
          buildLevel: (_, i, onComplete) => DragMatchScreen(
            activity: matches[i],
            languageCode: _languageCode,
            speed: _speed,
            onComplete: onComplete,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LittleHands'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 32),
              const SizedBox(width: 4),
              Text('$_totalStars',
                  key: const ValueKey('total_stars'),
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
            ]),
          ),
        ],
      ),
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
              _refreshStars();
            }
          },
        ),
      ),
    );
  }
}
