import '../settings/numeral_style.dart';

const _arabicIndicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

/// يحوّل أي أرقام إنجليزية (0-9) داخل [input] إلى أرقام عربية هندية
/// (٠-٩) حسب تفضيل المستخدم، أو يُبقيها كما هي.
String formatNumerals(String input, NumeralStyle style) {
  if (style == NumeralStyle.western) return input;

  final buffer = StringBuffer();
  for (final rune in input.runes) {
    if (rune >= 0x30 && rune <= 0x39) {
      buffer.write(_arabicIndicDigits[rune - 0x30]);
    } else {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString();
}
