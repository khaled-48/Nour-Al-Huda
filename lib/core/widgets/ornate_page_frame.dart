import 'dart:math' as math;

import 'package:flutter/material.dart';

/// إطار زخرفي خفيف يُرسَم كطبقة عُلوية شفافة للنقر (IgnorePointer) فوق حواف
/// بطاقة الصفحة: خط رفيع واحد بزوايا دائرية، مع لمسة معينة صغيرة في كل
/// زاوية. يُستخدم دوماً داخل Stack إلى جانب المحتوى الأصلي بلا أي Padding
/// إضافي حوله، فلا يُغيَّر حجم أو قيود المحتوى تحته إطلاقاً - مجرد رسم فوقي
/// لا يُزيح شيئاً.
class OrnatePageFrame extends StatelessWidget {
  const OrnatePageFrame({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _OrnatePageFramePainter(color: color),
      ),
    );
  }
}

class _OrnatePageFramePainter extends CustomPainter {
  _OrnatePageFramePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 12 || size.height <= 12) return;

    const margin = 3.0;
    final outer = Rect.fromLTWH(
      margin,
      margin,
      size.width - margin * 2,
      size.height - margin * 2,
    );

    final outerPaint = Paint()
      ..color = color.withValues(alpha: 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRRect(
      RRect.fromRectAndRadius(outer, const Radius.circular(12)),
      outerPaint,
    );

    for (final corner in [
      outer.topLeft,
      outer.topRight,
      outer.bottomLeft,
      outer.bottomRight,
    ]) {
      _drawCornerDiamond(canvas, corner, color);
    }
  }

  void _drawCornerDiamond(Canvas canvas, Offset corner, Color color) {
    final fillPaint = Paint()..color = color.withValues(alpha: 0.55);
    const r = 3.5;
    final path = Path()
      ..moveTo(corner.dx, corner.dy - r)
      ..lineTo(corner.dx + r, corner.dy)
      ..lineTo(corner.dx, corner.dy + r)
      ..lineTo(corner.dx - r, corner.dy)
      ..close();
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _OrnatePageFramePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// مسار نجمة ثمانية الرؤوس (تبادل نصف قطر خارجي/داخلي كل 16 زاوية) - نمط
/// زخرفي إسلامي تقليدي، يُستخدم في طرفي شارة عنوان السورة ([QpcMushafPage]).
Path eightPointStarPath({
  required Offset center,
  required double outerRadius,
  required double innerRadius,
}) {
  final path = Path();
  for (var i = 0; i < 16; i++) {
    final angle = (math.pi / 8) * i;
    final r = i.isEven ? outerRadius : innerRadius;
    final point = Offset(
      center.dx + r * math.cos(angle),
      center.dy + r * math.sin(angle),
    );
    if (i == 0) {
      path.moveTo(point.dx, point.dy);
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }
  path.close();
  return path;
}
