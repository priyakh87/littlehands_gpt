import 'package:flutter/material.dart';

import '../../models/learning_content.dart';
import '../../services/tts_service.dart';

/// A–Z grid. Tapping a letter shows it big with its picture word and
/// says "A is for Apple".
class AbcScreen extends StatefulWidget {
  final List<AbcEntry> letters;

  const AbcScreen({super.key, required this.letters});

  @override
  State<AbcScreen> createState() => _AbcScreenState();
}

class _AbcScreenState extends State<AbcScreen> {
  static const _tileColors = [
    Color(0xFFFFCDD2),
    Color(0xFFBBDEFB),
    Color(0xFFFFF9C4),
    Color(0xFFC8E6C9),
    Color(0xFFFFE0B2),
    Color(0xFFE1BEE7),
  ];

  late AbcEntry _selected = widget.letters.first;

  @override
  void dispose() {
    TtsService().stop();
    super.dispose();
  }

  void _select(AbcEntry entry) {
    setState(() => _selected = entry);
    TtsService().speak('${entry.letter} is for ${entry.word}',
        speed: NarrationSpeed.slow);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ABC Rhymes')),
      body: SafeArea(
        child: Column(
          children: [
            // Big display of the selected letter.
            GestureDetector(
              onTap: () => _select(_selected),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
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
          alignment: Alignment.center,
          child: Text(entry.letter,
              style:
                  const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
