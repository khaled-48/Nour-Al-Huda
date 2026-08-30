import 'package:flutter/material.dart';

/// خلفية بنقش هندسي إسلامي هادئ ومكرَّر (شبكة معينات صغيرة بنقطة مركزية)،
/// بدرجة شفافية منخفضة حتى لا يُشتّت عن المحتوى فوقها. مرسوم بالكامل
/// برمجياً (CustomPainter) دون أي صورة خارجية، فيبقى خفيفاً وغير مكلف
/// لإعادة الرسم (لا يعتمد على أي Listenable يتغيّر كل إطار).
class IslamicPatternBackground extends StatelessWidget {
  const IslamicPatternBackground({
    super.key,
    required this.child,
    required this.backgroundColor,
    required this.patternColor,
    this.opacity = 0.06,
    this.tileSize = 44,
  });

  final Widget child;
  final Color backgroundColor;
  final Color patternColor;
  final double opacity;
  final double tileSize;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: CustomPaint(
        painter: _IslamicPatternPainter(
          color: patternColor.withValues(alpha: opacity),
          tileSize: tileSize,
        ),
        child: child,
      ),
    );
  }
}

class _IslamicPatternPainter extends CustomPainter {
  _IslamicPatternPainter({required this.color, required this.tileSize});

  final Color color;
  final double tileSize;

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final cols = (size.width / tileSize).ceil() + 1;
    final rows = (size.height / tileSize).ceil() + 1;
    final r = tileSize * 0.32;

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final center = Offset(col * tileSize, row * tileSize);
        final path = Path()
          ..moveTo(center.dx, center.dy - r)
          ..lineTo(center.dx + r, center.dy)
          ..lineTo(center.dx, center.dy + r)
          ..lineTo(center.dx - r, center.dy)
          ..close();
        canvas.drawPath(path, strokePaint);
        canvas.drawCircle(center, r * 0.18, fillPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _IslamicPatternPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.tileSize != tileSize;
}
