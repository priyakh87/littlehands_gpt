import 'dart:math';

import 'package:flutter/material.dart';

import '../services/tts_service.dart';

enum CelebrationAction { next, replay, exit }

const _wowMessages = [
  'Wow!',
  'Amazing!',
  'Super star!',
  'You did it!',
  'Fantastic!',
  'Hooray!',
  'Brilliant!',
];

/// Full-screen "wow" moment shown when a level or story is finished:
/// falling confetti, stars popping in one by one and a spoken cheer.
Future<CelebrationAction> showCelebration(
  BuildContext context, {
  required int stars,
  required String subtitle,
  bool hasNext = false,
  bool canReplay = true,
}) async {
  final result = await showGeneralDialog<CelebrationAction>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 450),
    pageBuilder: (_, __, ___) => CelebrationView(
      stars: stars,
      subtitle: subtitle,
      hasNext: hasNext,
      canReplay: canReplay,
    ),
    transitionBuilder: (_, animation, __, child) => ScaleTransition(
      scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
      child: child,
    ),
  );
  return result ?? CelebrationAction.exit;
}

class CelebrationView extends StatefulWidget {
  final int stars;
  final String subtitle;
  final bool hasNext;
  final bool canReplay;

  const CelebrationView({
    super.key,
    required this.stars,
    required this.subtitle,
    required this.hasNext,
    required this.canReplay,
  });

  @override
  State<CelebrationView> createState() => _CelebrationViewState();
}

class _CelebrationViewState extends State<CelebrationView>
    with TickerProviderStateMixin {
  late final AnimationController _confetti = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();
  late final AnimationController _starsIn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();
  late final String _wow = _wowMessages[Random().nextInt(_wowMessages.length)];

  @override
  void initState() {
    super.initState();
    TtsService().speak('$_wow ${widget.subtitle}');
  }

  @override
  void dispose() {
    _confetti.dispose();
    _starsIn.dispose();
    super.dispose();
  }

  void _close(CelebrationAction action) => Navigator.pop(context, action);

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _ConfettiPainter(_confetti)),
            ),
          ),
          Center(
            child: Container(
              key: const ValueKey('celebration'),
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 72)),
                  Text(
                    _wow,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < 3; i++)
                        ScaleTransition(
                          scale: CurvedAnimation(
                            parent: _starsIn,
                            curve: Interval(i * 0.25, 0.5 + i * 0.25,
                                curve: Curves.elasticOut),
                          ),
                          child: Icon(
                            Icons.star_rounded,
                            size: 72,
                            color: i < widget.stars
                                ? Colors.amber
                                : Colors.grey.shade300,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.canReplay)
                        _roundButton(
                          key: 'celebration_replay',
                          icon: Icons.replay_rounded,
                          label: 'Again',
                          onTap: () => _close(CelebrationAction.replay),
                        ),
                      _roundButton(
                        key: 'celebration_exit',
                        icon: widget.hasNext
                            ? Icons.grid_view_rounded
                            : Icons.check_rounded,
                        label: widget.hasNext ? 'Levels' : 'Done',
                        onTap: () => _close(CelebrationAction.exit),
                      ),
                      if (widget.hasNext)
                        _roundButton(
                          key: 'celebration_next',
                          icon: Icons.arrow_forward_rounded,
                          label: 'Next',
                          primary: true,
                          onTap: () => _close(CelebrationAction.next),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundButton({
    required String key,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          primary
              ? IconButton.filled(
                  key: ValueKey(key),
                  iconSize: 44,
                  icon: Icon(icon),
                  onPressed: onTap)
              : IconButton.filledTonal(
                  key: ValueKey(key),
                  iconSize: 36,
                  icon: Icon(icon),
                  onPressed: onTap),
          Text(label, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

class _Particle {
  final double x, speed, phase, size, spin;
  final Color color;
  _Particle(Random r)
      : x = r.nextDouble(),
        speed = 0.6 + r.nextDouble() * 0.8,
        phase = r.nextDouble(),
        size = 6 + r.nextDouble() * 8,
        spin = r.nextDouble() * 2 * pi,
        color = _colors[r.nextInt(_colors.length)];

  static const _colors = [
    Colors.red,
    Colors.amber,
    Colors.green,
    Colors.blue,
    Colors.pink,
    Colors.purple,
    Colors.orange,
  ];
}

class _ConfettiPainter extends CustomPainter {
  final Animation<double> animation;
  final List<_Particle> _particles;

  _ConfettiPainter(this.animation)
      : _particles = List.generate(70, (_) => _Particle(Random())),
        super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final paint = Paint();
    for (final p in _particles) {
      final progress = (t * p.speed + p.phase) % 1.0;
      final y = progress * (size.height + 40) - 20;
      final x = p.x * size.width + sin((t + p.phase) * 2 * pi) * 24;
      paint.color = p.color;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin + t * 2 * pi * p.speed);
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset.zero, width: p.size, height: p.size * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => false;
}
