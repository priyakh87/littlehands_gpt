import 'dart:math';

import 'package:flutter/material.dart';

/// Simple flat, thick-outlined shapes for toddler activities.
class ShapeView extends StatelessWidget {
  final String shape; // circle, square, triangle, star, heart
  final Color color;

  const ShapeView({super.key, required this.shape, required this.color});

  @override
  Widget build(BuildContext context) => CustomPaint(
      painter: _ShapePainter(shape, color), child: const SizedBox.expand());
}

class _ShapePainter extends CustomPainter {
  final String shape;
  final Color color;

  _ShapePainter(this.shape, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final side = min(size.width, size.height);
    final offset = Offset((size.width - side) / 2, (size.height - side) / 2);
    final path = shapePath(shape, side).shift(offset);
    canvas.drawShadow(path, Colors.black, 4, false);
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black26
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ShapePainter old) =>
      old.shape != shape || old.color != color;
}

/// Path for [shape] inside a [s] x [s] square.
Path shapePath(String shape, double s) {
  final p = Path();
  switch (shape) {
    case 'square':
      return p
        ..addRRect(RRect.fromRectAndRadius(
            Rect.fromLTWH(s * 0.1, s * 0.1, s * 0.8, s * 0.8),
            Radius.circular(s * 0.08)));
    case 'triangle':
      return p
        ..moveTo(s * 0.5, s * 0.08)
        ..lineTo(s * 0.94, s * 0.88)
        ..lineTo(s * 0.06, s * 0.88)
        ..close();
    case 'star':
      final c = Offset(s / 2, s * 0.53);
      final outer = s * 0.48, inner = outer * 0.45;
      for (var i = 0; i < 10; i++) {
        final r = i.isEven ? outer : inner;
        final a = -pi / 2 + i * pi / 5;
        final pt = c + Offset(cos(a) * r, sin(a) * r);
        i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
      }
      return p..close();
    case 'heart':
      return p
        ..moveTo(s * 0.5, s * 0.88)
        ..cubicTo(s * 0.1, s * 0.62, s * 0.02, s * 0.36, s * 0.2, s * 0.2)
        ..cubicTo(s * 0.34, s * 0.08, s * 0.47, s * 0.16, s * 0.5, s * 0.3)
        ..cubicTo(s * 0.53, s * 0.16, s * 0.66, s * 0.08, s * 0.8, s * 0.2)
        ..cubicTo(s * 0.98, s * 0.36, s * 0.9, s * 0.62, s * 0.5, s * 0.88)
        ..close();
    case 'circle':
    default:
      return p..addOval(Rect.fromLTWH(s * 0.06, s * 0.06, s * 0.88, s * 0.88));
  }
}
