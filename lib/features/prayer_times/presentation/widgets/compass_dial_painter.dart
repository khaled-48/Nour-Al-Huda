import 'dart:math' as math;

import 'package:flutter/material.dart';

/// يرسم قرص بوصلة هندسي هادئ: دائرة، علامات تدريج كل ٣٠ درجة (أطول عند
/// الاتجاهات الرئيسية)، بلون ذهبي مكتوم يناسب هوية التطبيق.
class CompassDialPainter extends CustomPainter {
  CompassDialPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, ringPaint);
    canvas.drawCircle(center, radius - 14, ringPaint..strokeWidth = 1);

    final tickPaint = Paint()
      ..color = color
      ..strokeWidth = 2;

    for (var degree = 0; degree < 360; degree += 30) {
      final isMajor = degree % 90 == 0;
      final angle = degree * math.pi / 180;
      final outer = Offset(
        center.dx + radius * math.sin(angle),
        center.dy - radius * math.cos(angle),
      );
      final innerRadius = radius - (isMajor ? 22 : 12);
      final inner = Offset(
        center.dx + innerRadius * math.sin(angle),
        center.dy - innerRadius * math.cos(angle),
      );
      canvas.drawLine(inner, outer, tickPaint..strokeWidth = isMajor ? 3 : 1.5);
    }
  }

  @override
  bool shouldRepaint(covariant CompassDialPainter oldDelegate) => oldDelegate.color != color;
}
