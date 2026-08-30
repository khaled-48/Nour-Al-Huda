import 'package:flutter/material.dart';

/// إطار بتدرّج ذهبي هادئ حول محتوى الصفحة: طبقة خارجية بتدرّج لوني ذهبي،
/// وطبقة داخلية بلون خلفية الصفحة، فيظهر كحدّ متدرّج ناعم بدل خط مصمت.
class GoldGradientFrame extends StatelessWidget {
  const GoldGradientFrame({
    super.key,
    required this.child,
    required this.backgroundColor,
    required this.goldColor,
    this.borderWidth = 2.5,
    this.borderRadius = 6,
  });

  final Widget child;
  final Color backgroundColor;
  final Color goldColor;
  final double borderWidth;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            goldColor.withValues(alpha: 0.15),
            goldColor.withValues(alpha: 0.65),
            goldColor.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      padding: EdgeInsets.all(borderWidth),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular((borderRadius - borderWidth).clamp(0, borderRadius)),
        ),
        child: child,
      ),
    );
  }
}
