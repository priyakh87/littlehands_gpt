import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/learning_content.dart';
import '../../services/tts_service.dart';

/// "Can you find red?" — the child taps the matching colour bubble.
/// Gentle feedback on a wrong tap; a fun fact and a new colour on a right one.
class ColorGameScreen extends StatefulWidget {
  final List<ColorEntry> colors;

  const ColorGameScreen({super.key, required this.colors});

  @override
  State<ColorGameScreen> createState() => _ColorGameScreenState();
}

class _ColorGameScreenState extends State<ColorGameScreen> {
  final _random = Random();
  late ColorEntry _target;
  late List<ColorEntry> _choices;
  int _found = 0;
  String? _message;
  bool _celebrating = false; // ignore taps while the fun fact plays

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
    final pool = List.of(widget.colors);
    if (!first) pool.remove(_target); // don't ask the same colour twice
    _target = pool[_random.nextInt(pool.length)];
    _choices = List.of(widget.colors)..shuffle(_random);
    _message = null;
    _celebrating = false;
    TtsService().speak('Can you find ${_target.name.toLowerCase()}?',
        speed: NarrationSpeed.slow);
  }

  void _onTap(ColorEntry tapped) {
    if (_celebrating) return;
    if (tapped.name == _target.name) {
      setState(() {
        _found++;
        _celebrating = true;
        _message = '${_target.name}! ${_target.fact}';
      });
      TtsService().speak(_message!, speed: NarrationSpeed.slow);
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(_nextRound);
      });
    } else {
      setState(() => _message = "That's ${tapped.name.toLowerCase()}. "
          "Let's find ${_target.name.toLowerCase()}!");
      TtsService().speak(_message!, speed: NarrationSpeed.slow);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Color Game'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 32),
              Text('$_found', style: const TextStyle(fontSize: 22)),
            ]),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              GestureDetector(
                onTap: () => TtsService().speak(
                    'Can you find ${_target.name.toLowerCase()}?',
                    speed: NarrationSpeed.slow),
                child: Text(
                  'Find ${_target.name}!',
                  key: const ValueKey('color_prompt'),
                  style: const TextStyle(
                      fontSize: 36, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                height: 80,
                child: Center(
                  child: Text(
                    _message ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  padding: const EdgeInsets.all(8),
                  children: _choices
                      .map((c) => GestureDetector(
                            key: ValueKey('color_${c.name}'),
                            onTap: () => _onTap(c),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color(c.argb),
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(
                                      blurRadius: 6, color: Colors.black26),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
