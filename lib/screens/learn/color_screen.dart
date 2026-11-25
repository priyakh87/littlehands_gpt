import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/learning_content.dart';
import '../../services/progress_service.dart';
import '../../services/tts_service.dart';
import '../../widgets/shape_view.dart';

class _Choice {
  final ColorEntry color;
  final String shape;
  const _Choice(this.color, this.shape);

  String get id => '${color.name}_$shape';
}

/// One level of the Color Game.
/// - colour levels: "Can you find red?" with coloured circles
/// - shape levels: "Can you find the red star?" with shape + colour combos
/// Gentle feedback on a wrong tap; after [ColorLevel.rounds] correct
/// answers it calls [onComplete] with 1–3 stars.
class ColorLevelScreen extends StatefulWidget {
  final ColorLevel level;
  final LearningContent content;
  final void Function(int stars) onComplete;
  final Random? random;

  const ColorLevelScreen({
    super.key,
    required this.level,
    required this.content,
    required this.onComplete,
    this.random,
  });

  @override
  State<ColorLevelScreen> createState() => _ColorLevelScreenState();
}

class _ColorLevelScreenState extends State<ColorLevelScreen> {
  late final Random _random = widget.random ?? Random();
  late final List<ColorEntry> _palette =
      widget.level.colors.map(widget.content.color).toList();
  late _Choice _target;
  late List<_Choice> _choices;
  int _done = 0;
  int _mistakes = 0;
  String? _message;
  bool _celebrating = false; // ignore taps while feedback plays

  ColorLevel get _level => widget.level;

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

  String _describe(_Choice c, {bool withArticle = false}) {
    final name = c.color.name.toLowerCase();
    if (!_level.usesShapes) return name;
    final phrase = '$name ${c.shape}';
    if (!withArticle) return phrase;
    return '${'aeiou'.contains(name[0]) ? 'an' : 'a'} $phrase';
  }

  String get _question => _level.usesShapes
      ? 'Can you find the ${_describe(_target)}?'
      : 'Can you find ${_describe(_target)}?';

  void _nextRound({bool first = false}) {
    if (_level.usesShapes) {
      _buildShapeRound(first);
    } else {
      _buildColorRound(first);
    }
    _message = null;
    _celebrating = false;
    TtsService().speak(_question, speed: NarrationSpeed.slow);
  }

  void _buildColorRound(bool first) {
    final pool = List.of(_palette);
    if (!first) pool.removeWhere((c) => c.name == _target.color.name);
    final target = _Choice(pool[_random.nextInt(pool.length)], 'circle');
    final others = _palette.where((c) => c.name != target.color.name).toList()
      ..shuffle(_random);
    final count = min(_level.choices, _palette.length);
    _target = target;
    _choices = [
      target,
      ...others.take(count - 1).map((c) => _Choice(c, 'circle')),
    ]..shuffle(_random);
  }

  void _buildShapeRound(bool first) {
    final shapes = _level.shapes;
    _Choice pick() => _Choice(_palette[_random.nextInt(_palette.length)],
        shapes[_random.nextInt(shapes.length)]);

    var target = pick();
    while (!first && target.id == _target.id) {
      target = pick();
    }
    final choices = <String, _Choice>{target.id: target};
    // Tricky distractors first: same shape other colour, same colour
    // other shape — so the child has to check both.
    final sameShape = _palette
        .where((c) => c.name != target.color.name)
        .map((c) => _Choice(c, target.shape))
        .toList()
      ..shuffle(_random);
    final sameColor = shapes
        .where((s) => s != target.shape)
        .map((s) => _Choice(target.color, s))
        .toList()
      ..shuffle(_random);
    for (final c in [...sameShape.take(2), ...sameColor.take(2)]) {
      choices.putIfAbsent(c.id, () => c);
    }
    var guard = 0;
    while (choices.length < _level.choices && guard++ < 100) {
      final c = pick();
      choices.putIfAbsent(c.id, () => c);
    }
    _target = target;
    _choices = choices.values.toList()..shuffle(_random);
  }

  void _onTap(_Choice tapped) {
    if (_celebrating) return;
    if (tapped.id == _target.id) {
      _celebrating = true;
      final message = _level.usesShapes
          ? 'Yes! ${_describe(_target, withArticle: true)}!'
          : '${_target.color.name}! ${_target.color.fact}';
      setState(() {
        _done++;
        _message = message;
      });
      TtsService().speak(message, speed: NarrationSpeed.slow);
      final finished = _done >= _level.rounds;
      Future.delayed(Duration(milliseconds: _level.usesShapes ? 2200 : 3500),
          () {
        if (!mounted) return;
        if (finished) {
          widget.onComplete(ProgressService.starsForMistakes(_mistakes));
        } else {
          setState(_nextRound);
        }
      });
    } else {
      _mistakes++;
      final message = _level.usesShapes
          ? "That's ${_describe(tapped, withArticle: true)}. "
              "Let's find the ${_describe(_target)}!"
          : "That's ${_describe(tapped)}. Let's find ${_describe(_target)}!";
      setState(() => _message = message);
      TtsService().speak(message, speed: NarrationSpeed.slow);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prompt = _level.usesShapes
        ? 'Find the ${_target.color.name} ${_target.shape}!'
        : 'Find ${_target.color.name}!';
    final columns = _choices.length > 6 ? 3 : 2;
    return Scaffold(
      appBar: AppBar(title: Text('Level ${_level.level}: ${_level.title}')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _ProgressDots(done: _done, total: _level.rounds),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () =>
                    TtsService().speak(_question, speed: NarrationSpeed.slow),
                child: Text(
                  prompt,
                  key: const ValueKey('color_prompt'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                height: 64,
                child: Center(
                  child: Text(
                    _message ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) => GridView.count(
                    // Size cells so every choice fits without scrolling.
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: columns,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    padding: const EdgeInsets.all(8),
                    childAspectRatio: _aspect(box, columns, _choices.length),
                    children: _choices
                        .map((c) => GestureDetector(
                              key: ValueKey('choice_${c.id}'),
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _onTap(c),
                              child: ShapeView(
                                  shape: c.shape, color: Color(c.color.argb)),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Width/height ratio that makes [count] cells in [columns] columns fill
/// the available box exactly (16 spacing, 8 padding).
double _aspect(BoxConstraints box, int columns, int count) {
  final rows = (count / columns).ceil();
  final w = (box.maxWidth - 16 - 16 * (columns - 1)) / columns;
  final h = (box.maxHeight - 16 - 16 * (rows - 1)) / rows;
  if (w <= 0 || h <= 0) return 1;
  return w / h;
}

class _ProgressDots extends StatelessWidget {
  final int done;
  final int total;

  const _ProgressDots({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < total; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Icon(
              i < done ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 28,
              color: i < done ? Colors.amber : Colors.grey.shade400,
            ),
          ),
      ],
    );
  }
}
