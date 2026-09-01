import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// دائرة تنازلية كبيرة تُظهر بصرياً نسبة الوقت المنقضي من الفترة بين
/// الصلاة الحالية والصلاة القادمة، بقوس متدرّج اللون (فيروزي إلى ذهبي)
/// ونقطة لامعة عند رأس التقدّم، مع أيقونة زخرفية ثابتة في المنتصف.
/// رسمها بالكامل عبر CustomPainter يبقيها خفيفة رغم نبضها كل ثانية.
class PrayerCountdownRing extends StatelessWidget {
  const PrayerCountdownRing({
    super.key,
    required this.progress,
    this.size = 150,
  });

  /// من 0 إلى 1: نسبة الوقت المنقضي منذ آخر أذان حتى الأذان القادم.
  final double progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(progress: progress.clamp(0, 1)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.nights_stay, color: AppColors.goldLight, size: size * 0.16),
              SizedBox(height: size * 0.03),
              Icon(Icons.mosque, color: AppColors.goldLight.withValues(alpha: 0.85), size: size * 0.22),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress});

  final double progress;

  static const _trackColor = Color(0xFF12332C);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - _strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = _trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, trackPaint);

    if (progress > 0) {
      final sweep = 2 * math.pi * progress;
      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: -math.pi / 2 + sweep,
          colors: const [Color(0xFF1E8A73), AppColors.goldLight, AppColors.gold],
        ).createShader(rect);
      canvas.drawArc(rect, -math.pi / 2, sweep, false, progressPaint);

      final headAngle = -math.pi / 2 + sweep;
      final headCenter = Offset(
        center.dx + radius * math.cos(headAngle),
        center.dy + radius * math.sin(headAngle),
      );
      final headPaint = Paint()..color = AppColors.goldLight;
      canvas.drawCircle(headCenter, _strokeWidth * 0.65, headPaint);
      canvas.drawCircle(
        headCenter,
        _strokeWidth * 0.65,
        Paint()
          ..color = AppColors.goldLight.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
  }

  static const _strokeWidth = 9.0;

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.progress != progress;
}
