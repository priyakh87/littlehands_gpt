import 'package:flutter/material.dart';

import '../../models/learning_content.dart';
import '../../services/access_policy.dart';
import '../../services/progress_service.dart';
import '../../services/subscription_service.dart';
import '../../services/tts_service.dart';
import '../../widgets/celebration.dart';
import '../parent/paywall_screen.dart';

/// Lists the bundled stories; tapping one opens a page-by-page reader.
/// Finishing a story shows a celebration and marks it with stars.
class StoryListScreen extends StatefulWidget {
  final List<Story> stories;

  const StoryListScreen({super.key, required this.stories});

  @override
  State<StoryListScreen> createState() => _StoryListScreenState();
}

class _StoryListScreenState extends State<StoryListScreen> {
  Set<String> _finished = {};

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final done = <String>{};
    for (final s in widget.stories) {
      if (await ProgressService.stars('story_${s.id}', 1) > 0) done.add(s.id);
    }
    if (mounted) setState(() => _finished = done);
  }

  Future<void> _read(Story story) async {
    while (true) {
      if (!mounted) break;
      final finished = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => StoryReaderScreen(story: story)),
      );
      if (finished != true || !mounted) break;
      await ProgressService.saveStars('story_${story.id}', 1, 3);
      await _refresh();
      if (!mounted) break;
      final action = await showCelebration(
        context,
        stars: 3,
        subtitle: 'You finished ${story.title}!',
      );
      if (action != CelebrationAction.replay) break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Story Time')),
      body: ValueListenableBuilder<bool>(
        valueListenable: SubscriptionService.isPremium,
        builder: (context, _, __) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (var i = 0; i < widget.stories.length; i++)
              _storyCard(context, i),
          ],
        ),
      ),
    );
  }

  Widget _storyCard(BuildContext context, int i) {
    final story = widget.stories[i];
    final locked = !AccessPolicy.canReadStory(i);
    return Card(
      key: ValueKey('story_${story.id}'),
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Text(story.emoji, style: const TextStyle(fontSize: 48)),
        title: Text(story.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        subtitle: locked ? const Text('👑 Premium · ask a grown-up') : null,
        trailing: locked
            ? Icon(Icons.workspace_premium_rounded,
                color: Colors.amber.shade700, size: 36)
            : _finished.contains(story.id)
                ? const Icon(Icons.star_rounded, color: Colors.amber, size: 36)
                : null,
        onTap: locked ? () => openPremium(context) : () => _read(story),
      ),
    );
  }
}

/// Shows one page of a story at a time and reads it aloud.
class StoryReaderScreen extends StatefulWidget {
  final Story story;

  const StoryReaderScreen({super.key, required this.story});

  @override
  State<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _StoryReaderScreenState extends State<StoryReaderScreen> {
  int _page = 0;

  bool get _isLast => _page == widget.story.pages.length - 1;

  @override
  void initState() {
    super.initState();
    _read();
  }

  @override
  void dispose() {
    TtsService().stop();
    super.dispose();
  }

  void _read() =>
      TtsService().speak(widget.story.pages[_page], speed: NarrationSpeed.slow);

  void _goTo(int page) {
    setState(() => _page = page);
    _read();
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.story;
    return Scaffold(
      appBar: AppBar(title: Text(story.title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(story.emoji, style: const TextStyle(fontSize: 96)),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: Text(
                    story.pages[_page],
                    key: const ValueKey('story_page_text'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 26, height: 1.4),
                  ),
                ),
              ),
              Text('${_page + 1} / ${story.pages.length}',
                  style: const TextStyle(fontSize: 18, color: Colors.grey)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton.filledTonal(
                    iconSize: 40,
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: _page == 0 ? null : () => _goTo(_page - 1),
                  ),
                  IconButton.filledTonal(
                    iconSize: 40,
                    icon: const Icon(Icons.volume_up_rounded),
                    onPressed: _read,
                  ),
                  IconButton.filled(
                    key: const ValueKey('story_next'),
                    iconSize: 40,
                    icon: Icon(_isLast
                        ? Icons.check_rounded
                        : Icons.arrow_forward_rounded),
                    onPressed: _isLast
                        ? () => Navigator.pop(context, true)
                        : () => _goTo(_page + 1),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
