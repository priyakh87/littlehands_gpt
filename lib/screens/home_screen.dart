import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../models/child_profile.dart';
import '../models/learning_content.dart';
import '../services/content_engine.dart';
import '../services/profile_service.dart';
import '../services/progress_service.dart';
import '../services/tts_service.dart';
import 'activities/drag_match_screen.dart';
import 'animal_screen.dart';
import 'learn/abc_screen.dart';
import 'learn/color_screen.dart';
import 'learn/story_screen.dart';
import 'levels_screen.dart';
import 'parent/parent_gate.dart';
import 'parent/parent_settings_screen.dart';

/// Home screen of LittleHands.
///
/// Fully offline: no microphone, no network, no API keys. All content is
/// bundled in the app and narrated with the device's own TTS engine.
class HomeScreen extends StatefulWidget {
  final ChildProfile profile;

  const HomeScreen({super.key, required this.profile});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  /// Kids can switch between existing children; adding or editing
  /// children needs the parent gate.
  Future<void> _switchChild() async {
    final profiles = ProfileService.profiles;
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text("Who's playing?",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            ),
            for (final p in profiles)
              ListTile(
                key: ValueKey('switch_${p.id}'),
                leading: Text(p.avatar, style: const TextStyle(fontSize: 36)),
                title: Text(p.name, style: const TextStyle(fontSize: 20)),
                trailing: p.id == widget.profile.id
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () {
                  Navigator.pop(sheetContext);
                  if (p.id != widget.profile.id) ProfileService.setActive(p.id);
                },
              ),
            ListTile(
              leading: const Icon(Icons.person_add_alt_1_rounded),
              title: const Text('Add a child (grown-ups)'),
              onTap: () {
                Navigator.pop(sheetContext);
                _openParentArea();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openParentArea() async {
    if (_busy) return;
    _busy = true;
    try {
      if (!await showParentGate(context) || !mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ParentSettingsScreen()),
      );
    } finally {
      _busy = false;
      _refreshStars();
    }
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
    final activities = await ContentEngine().loadForAge(widget.profile.age);
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
        leadingWidth: 180,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: TextButton(
            key: const ValueKey('profile_switcher'),
            onPressed: _switchChild,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.profile.avatar,
                    style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(widget.profile.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
        actions: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 30),
          const SizedBox(width: 4),
          Text('$_totalStars',
              key: const ValueKey('total_stars'),
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          IconButton(
            key: const ValueKey('parent_settings'),
            tooltip: 'Grown-ups',
            icon: const Icon(Icons.settings_rounded),
            onPressed: _openParentArea,
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
