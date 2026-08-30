/// نظام الأرقام المعروض في كل أنحاء التطبيق (الأوقات، العدّادات، أرقام
/// الآيات...).
enum NumeralStyle { arabic, western }

extension NumeralStyleLabel on NumeralStyle {
  String get arabicLabel => switch (this) {
        NumeralStyle.arabic => 'أرقام عربية (١٢٣)',
        NumeralStyle.western => 'أرقام إنجليزية (123)',
      };
}
