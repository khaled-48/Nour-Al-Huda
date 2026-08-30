import 'package:flutter/material.dart';

/// لوحة ألوان التطبيق للوضعين الفاتح والداكن.
class AppColors {
  AppColors._();

  // الهوية اللونية الأساسية (أخضر إسلامي هادئ + ذهبي مزخرف للتفاصيل)
  static const Color primary = Color(0xFF0F6E5C);
  static const Color primaryDark = Color(0xFF0A4A3D);
  static const Color secondary = Color(0xFFC9A227);

  /// اسم أوضح لنفس اللون الذهبي، يُستخدم في العناصر الزخرفية (حدود
  /// البطاقات، الأطر، أرقام الآيات...).
  static const Color gold = secondary;
  static const Color goldLight = Color(0xFFE0C170);

  static const Color lightBackground = Color(0xFFF4ECD8);
  static const Color lightSurface = Color(0xFFFFFDF7);
  static const Color lightText = Color(0xFF1B1B1B);

  static const Color darkBackground = Color(0xFF0E1512);
  static const Color darkSurface = Color(0xFF16211D);
  static const Color darkText = Color(0xFFEDEDED);

  static const Color error = Color(0xFFB3261E);
}
