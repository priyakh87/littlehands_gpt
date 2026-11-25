import 'package:flutter/material.dart';

import '../services/progress_service.dart';
import '../widgets/celebration.dart';

class LevelInfo {
  final String title;
  final String emoji;

  const LevelInfo({required this.title, required this.emoji});
}

/// Builds the screen for one level. It must call [onComplete] with the
/// stars earned (1–3) when the child finishes the level.
typedef LevelBuilder = Widget Function(
    BuildContext context, int index, void Function(int stars) onComplete);

/// Shared level picker for every activity: shows each level's stars,
/// locks levels until the previous one is done, and runs the
/// celebration + "next level" flow after a level is completed.
class LevelsScreen extends StatefulWidget {
  final String activityKey;
  final String title;
  final List<LevelInfo> levels;
  final LevelBuilder buildLevel;

  const LevelsScreen({
    super.key,
    required this.activityKey,
    required this.title,
    required this.levels,
    required this.buildLevel,
  });

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {
  List<int>? _stars;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final stars = await ProgressService.starsForLevels(
        widget.activityKey, widget.levels.length);
    if (mounted) setState(() => _stars = stars);
  }

  Future<void> _play(int index) async {
    if (_playing) return;
    _playing = true;
    try {
      var current = index;
      while (true) {
        if (!mounted) break;
        final stars = await Navigator.push<int>(
          context,
          MaterialPageRoute(
            // No iOS swipe-back: it would steal drags inside activities.
            fullscreenDialog: true,
            builder: (routeContext) => widget.buildLevel(
              routeContext,
              current,
              (s) => Navigator.pop(routeContext, s),
            ),
          ),
        );
        if (stars == null || !mounted) break; // closed with the X
        await ProgressService.saveStars(widget.activityKey, current + 1, stars);
        await _refresh();
        if (!mounted) break;
        final hasNext = current + 1 < widget.levels.length;
        final action = await showCelebration(
          context,
          stars: stars,
          subtitle: 'Level ${current + 1} complete!',
          hasNext: hasNext,
        );
        if (action == CelebrationAction.next && hasNext) {
          current++;
        } else if (action != CelebrationAction.replay) {
          break;
        }
      }
    } finally {
      _playing = false;
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final stars = _stars;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: stars == null
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.levels.length,
              itemBuilder: (context, i) {
                final level = widget.levels[i];
                final unlocked = ProgressService.isUnlocked(stars, i);
                return Card(
                  key: ValueKey('level_${i + 1}'),
                  margin: const EdgeInsets.only(bottom: 16),
                  color: unlocked ? null : Colors.grey.shade200,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: unlocked ? () => _play(i) : null,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Opacity(
                            opacity: unlocked ? 1 : 0.35,
                            child: Text(level.emoji,
                                style: const TextStyle(fontSize: 48)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Level ${i + 1}',
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade600)),
                                Text(level.title,
                                    style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    for (var s = 0; s < 3; s++)
                                      Icon(
                                        Icons.star_rounded,
                                        size: 28,
                                        color: s < stars[i]
                                            ? Colors.amber
                                            : Colors.grey.shade300,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            unlocked
                                ? Icons.play_circle_fill_rounded
                                : Icons.lock_rounded,
                            size: 44,
                            color: unlocked
                                ? Colors.deepPurple
                                : Colors.grey.shade500,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
