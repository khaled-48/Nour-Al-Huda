import 'package:flutter/material.dart';

/// زرّ أيقونة ناعم بخلفية دائرية ذهبية شفافة خفيفة، بديلاً عن أيقونة
/// مسطّحة عادية، للأزرار الدقيقة في أشرطة العناوين المزخرفة.
class GoldIconButton extends StatelessWidget {
  const GoldIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color = Colors.white,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: color.withValues(alpha: 0.16),
        shape: const CircleBorder(),
        child: IconButton(
          icon: Icon(icon, size: 20, color: color),
          tooltip: tooltip,
          onPressed: onPressed,
        ),
      ),
    );
  }
}
