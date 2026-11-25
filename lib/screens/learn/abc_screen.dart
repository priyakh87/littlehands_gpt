import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/learning_content.dart';
import '../../services/progress_service.dart';
import '../../services/tts_service.dart';

const _tileColors = [
  Color(0xFFFFCDD2),
  Color(0xFFBBDEFB),
  Color(0xFFFFF9C4),
  Color(0xFFC8E6C9),
  Color(0xFFFFE0B2),
  Color(0xFFE1BEE7),
];

/// One ABC level: either "explore" (tap every letter in a range and hear
/// "A is for Apple") or "quiz" ("Find the letter B!").
class AbcLevelScreen extends StatelessWidget {
  final AbcLevel level;
  final List<AbcEntry> letters;
  final void Function(int stars) onComplete;
  final Random? random;

  const AbcLevelScreen({
    super.key,
    required this.level,
    required this.letters,
    required this.onComplete,
    this.random,
  });

  @override
  Widget build(BuildContext context) {
    if (level.isQuiz) {
      return _AbcQuiz(
          level: level,
          letters: letters,
          onComplete: onComplete,
          random: random);
    }
    final from = letters.indexWhere((l) => l.letter == level.from);
    final to = letters.indexWhere((l) => l.letter == level.to);
    return AbcExploreScreen(
      title: 'Level ${level.level}: ${level.title}',
      letters: letters.sublist(from, to + 1),
      onComplete: onComplete,
    );
  }
}

/// Tap-to-learn grid. Each tapped letter gets a tick; once every letter
/// has been tapped the level is complete.
class AbcExploreScreen extends StatefulWidget {
  final String title;
  final List<AbcEntry> letters;
  final void Function(int stars) onComplete;

  const AbcExploreScreen({
    super.key,
    required this.title,
    required this.letters,
    required this.onComplete,
  });

  @override
  State<AbcExploreScreen> createState() => _AbcExploreScreenState();
}

class _AbcExploreScreenState extends State<AbcExploreScreen> {
  late AbcEntry _selected = widget.letters.first;
  final Set<String> _visited = {};
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    TtsService().speak('Tap every letter!', speed: NarrationSpeed.slow);
  }

  @override
  void dispose() {
    TtsService().stop();
    super.dispose();
  }

  void _select(AbcEntry entry) {
    setState(() {
      _selected = entry;
      _visited.add(entry.letter);
    });
    TtsService().speak('${entry.letter} is for ${entry.word}',
        speed: NarrationSpeed.slow);
    if (!_finished && _visited.length == widget.letters.length) {
      _finished = true;
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) widget.onComplete(3);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _select(_selected),
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${_selected.letter}${_selected.letter.toLowerCase()}',
                      key: const ValueKey('abc_selected_letter'),
                      style: const TextStyle(
                          fontSize: 72, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      children: [
                        Text(_selected.emoji,
                            style: const TextStyle(fontSize: 64)),
                        Text(_selected.word,
                            style: const TextStyle(fontSize: 22)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Text(
              '${_visited.length} / ${widget.letters.length}',
              key: const ValueKey('abc_progress'),
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 4,
                padding: const EdgeInsets.all(12),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  for (var i = 0; i < widget.letters.length; i++)
                    _letterTile(
                        widget.letters[i], _tileColors[i % _tileColors.length]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _letterTile(AbcEntry entry, Color color) {
    final isSelected = entry.letter == _selected.letter;
    final visited = _visited.contains(entry.letter);
    return Material(
      key: ValueKey('abc_${entry.letter}'),
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _select(entry),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(color: Colors.deepPurple, width: 3)
                : null,
          ),
          child: Stack(
            children: [
              Center(
                child: Text(entry.letter,
                    style: const TextStyle(
                        fontSize: 36, fontWeight: FontWeight.bold)),
              ),
              if (visited)
                const Positioned(
                  right: 6,
                  top: 6,
                  child: Icon(Icons.check_circle_rounded,
                      size: 20, color: Colors.green),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AbcQuiz extends StatefulWidget {
  final AbcLevel level;
  final List<AbcEntry> letters;
  final void Function(int stars) onComplete;
  final Random? random;

  const _AbcQuiz({
    required this.level,
    required this.letters,
    required this.onComplete,
    this.random,
  });

  @override
  State<_AbcQuiz> createState() => _AbcQuizState();
}

class _AbcQuizState extends State<_AbcQuiz> {
  late final Random _random = widget.random ?? Random();
  late AbcEntry _target;
  late List<AbcEntry> _choices;
  int _done = 0;
  int _mistakes = 0;
  String? _message;
  bool _waiting = false;

  @override
  void initState() {
    super.initState();
    _nextRound(first: true);
  }

  @override
  void dispose() {
    TtsService().stop();
    super.dispose();
  }

  void _nextRound({bool first = false}) {
    final pool = List.of(widget.letters);
    if (!first) pool.remove(_target);
    _target = pool[_random.nextInt(pool.length)];
    final others = widget.letters.where((l) => l != _target).toList()
      ..shuffle(_random);
    _choices = [_target, ...others.take(widget.level.choices - 1)]
      ..shuffle(_random);
    _message = null;
    _waiting = false;
    TtsService().speak('Can you find the letter ${_target.letter}?',
        speed: NarrationSpeed.slow);
  }

  void _onTap(AbcEntry tapped) {
    if (_waiting) return;
    if (tapped == _target) {
      _waiting = true;
      final message = 'Yes! ${_target.letter} is for ${_target.word}!';
      setState(() {
        _done++;
        _message = '$message ${_target.emoji}';
      });
      TtsService().speak(message, speed: NarrationSpeed.slow);
      final finished = _done >= widget.level.rounds;
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (!mounted) return;
        if (finished) {
          widget.onComplete(ProgressService.starsForMistakes(_mistakes));
        } else {
          setState(_nextRound);
        }
      });
    } else {
      _mistakes++;
      final message = "That's ${tapped.letter}. Let's find ${_target.letter}!";
      setState(() => _message = message);
      TtsService().speak(message, speed: NarrationSpeed.slow);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Level ${widget.level.level}: ${widget.level.title}')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < widget.level.rounds; i++)
                    Icon(
                      i < _done
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 28,
                      color: i < _done ? Colors.amber : Colors.grey.shade400,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Find ${_target.letter}!',
                key: const ValueKey('abc_prompt'),
                style:
                    const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: 64,
                child: Center(
                  child: Text(_message ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20)),
                ),
              ),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  children: [
                    for (var i = 0; i < _choices.length; i++)
                      Material(
                        key: ValueKey('quiz_${_choices[i].letter}'),
                        color: _tileColors[i % _tileColors.length],
                        borderRadius: BorderRadius.circular(24),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => _onTap(_choices[i]),
                          child: Center(
                            child: Text(_choices[i].letter,
                                style: const TextStyle(
                                    fontSize: 72, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
