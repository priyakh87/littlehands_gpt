import 'package:flutter/material.dart';

import '../../models/activity.dart';
import '../../services/tts_service.dart';

/// Drag-and-drop matching: the child drags each picture onto its faded
/// "shadow" target. Fully offline; narration uses on-device TTS only.
class DragMatchScreen extends StatefulWidget {
  final Activity activity;
  final String languageCode; // 'en' or 'ar'
  final NarrationSpeed speed;
  final void Function(int starsEarned) onComplete;

  const DragMatchScreen({
    super.key,
    required this.activity,
    required this.languageCode,
    required this.speed,
    required this.onComplete,
  });

  @override
  State<DragMatchScreen> createState() => _DragMatchScreenState();
}

class _DragMatchScreenState extends State<DragMatchScreen> {
  final Set<String> _matched = {};
  int _wrongAttempts = 0;
  bool _completed = false;

  /// Pieces are shuffled once so their position doesn't give away the answer.
  late final List<ActivityItem> _shuffledPieces =
      List.of(widget.activity.items)..shuffle();

  bool get _isAr => widget.languageCode == 'ar';
  String get _locale => _isAr ? 'ar-AE' : 'en-US';
  bool get _isDone => _matched.length == widget.activity.items.length;

  @override
  void initState() {
    super.initState();
    _speak(_isAr ? widget.activity.titleAr : widget.activity.titleEn);
  }

  @override
  void dispose() {
    TtsService().stop();
    super.dispose();
  }

  void _speak(String text) {
    TtsService().speak(text, locale: _locale, speed: widget.speed);
  }

  void _onCorrectMatch(ActivityItem item) {
    setState(() => _matched.add(item.id));
    // Say the word on a correct match rather than "correct" every time.
    _speak(_isAr ? item.labelAr : item.labelEn);

    if (_isDone && !_completed) {
      _completed = true;
      final stars = _wrongAttempts == 0 ? 3 : (_wrongAttempts <= 2 ? 2 : 1);
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) widget.onComplete(stars);
      });
    }
  }

  void _onWrongMatch() {
    _wrongAttempts++;
    // Gentle, non-punitive feedback — no "wrong" sound.
    _speak(_isAr ? 'حاول مرة أخرى!' : "Let's try again!");
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.activity.items;
    return Directionality(
      textDirection: _isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isAr ? widget.activity.titleAr : widget.activity.titleEn),
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Drop targets: a faded "shadow" of each picture.
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 24,
                runSpacing: 24,
                children: items.map((item) {
                  final isFilled = _matched.contains(item.id);
                  return DragTarget<ActivityItem>(
                    key: ValueKey('target_${item.id}'),
                    onWillAcceptWithDetails: (details) =>
                        !isFilled && details.data.matchTargetId == item.id,
                    onAcceptWithDetails: (details) =>
                        _onCorrectMatch(details.data),
                    builder: (context, candidateData, rejectedData) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 110,
                        height: 110,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isFilled || candidateData.isNotEmpty
                                ? Colors.green
                                : Colors.grey.shade400,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          color: isFilled
                              ? Colors.green.shade50
                              : Colors.grey.shade100,
                        ),
                        child: Opacity(
                          opacity: isFilled ? 1.0 : 0.25,
                          child: Image.asset(item.imageAsset,
                              fit: BoxFit.contain),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
              const Spacer(),
              if (_isDone)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Icon(Icons.star_rounded,
                      size: 96, color: Colors.amber),
                ),
              // Draggable pieces
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 24,
                runSpacing: 24,
                children: _shuffledPieces
                    .where((item) => !_matched.contains(item.id))
                    .map((item) {
                  return Draggable<ActivityItem>(
                    key: ValueKey('piece_${item.id}'),
                    data: item,
                    feedback: _pieceWidget(item, dragging: true),
                    childWhenDragging:
                        Opacity(opacity: 0.3, child: _pieceWidget(item)),
                    onDraggableCanceled: (_, __) => _onWrongMatch(),
                    child: _pieceWidget(item),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pieceWidget(ActivityItem item, {bool dragging = false}) {
    return Container(
      width: 100,
      height: 100,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: dragging
            ? const [BoxShadow(blurRadius: 8, color: Colors.black26)]
            : const [],
      ),
      child: Image.asset(item.imageAsset, fit: BoxFit.contain),
    );
  }
}
