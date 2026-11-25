import 'package:flutter/material.dart';

import '../../models/learning_content.dart';
import '../../services/tts_service.dart';

/// Lists the bundled stories; tapping one opens a page-by-page reader.
class StoryListScreen extends StatelessWidget {
  final List<Story> stories;

  const StoryListScreen({super.key, required this.stories});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Story Time')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: stories
            .map((story) => Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading:
                        Text(story.emoji, style: const TextStyle(fontSize: 48)),
                    title: Text(story.title,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w600)),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => StoryReaderScreen(story: story)),
                    ),
                  ),
                ))
            .toList(),
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
                        ? () => Navigator.pop(context)
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
