import 'package:flutter/material.dart';

/// شريط زخرفي (خط رفيع مع سلسلة معينات ذهبية صغيرة متصلة) يُستخدم كإطار
/// علوي أو سفلي هندسي إسلامي لصفحات القراءة، بديلاً عن خط حدود بسيط.
class OrnateDivider extends StatelessWidget {
  const OrnateDivider({super.key, required this.color, this.height = 18});

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(painter: _OrnateDividerPainter(color: color)),
    );
  }
}

class _OrnateDividerPainter extends CustomPainter {
  _OrnateDividerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const spacing = 26.0;
    final diamondR = size.height * 0.34;

    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), strokePaint);

    var x = spacing / 2;
    while (x < size.width) {
      final center = Offset(x, midY);
      final path = Path()
        ..moveTo(center.dx, center.dy - diamondR)
        ..lineTo(center.dx + diamondR, center.dy)
        ..lineTo(center.dx, center.dy + diamondR)
        ..lineTo(center.dx - diamondR, center.dy)
        ..close();
      canvas.drawPath(path, strokePaint);
      canvas.drawCircle(center, diamondR * 0.22, fillPaint);
      x += spacing;
    }
  }

  @override
  bool shouldRepaint(covariant _OrnateDividerPainter oldDelegate) => oldDelegate.color != color;
}
