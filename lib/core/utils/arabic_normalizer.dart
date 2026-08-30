/// يبسّط نص عربي للمقارنة عند البحث: يحذف التشكيل وعلامات الوقف القرآنية
/// الصغيرة والتطويل، ويوحّد صور الألف والياء والتاء المربوطة، بحيث يجد
/// المستخدم الآية حتى لو كتب بحثه بدون همزات أو تشكيل.
///
/// يعمل على رموز Unicode (code points) مباشرة بدل نمط Regex يحتوي علامات
/// تشكيل تراكبية حرفية داخل الكود (يصعب التحقق منها بالعين المجرّدة).
/// النطاقات مأخوذة من مسح فعلي لكل رمز يظهر في نص تنزيل (Tanzil) العثماني
/// الكامل، ويجب أن تطابق سكربت بناء ملفات القرآن (rebuild_quran_assets.js)
/// حتى تتطابق نتائج البحث الحيّة مع الفهرسة المخزّنة مسبقاً.
String normalizeArabic(String text) {
  final buffer = StringBuffer();
  var lastWasSpace = false;

  for (final rune in text.trim().runes) {
    if (_isDiacritic(rune)) continue;

    final mapped = switch (rune) {
      0x0623 || 0x0625 || 0x0622 || 0x0671 => 0x0627, // أ إ آ ٱ -> ا
      0x0649 => 0x064A, // ى -> ي
      0x0629 => 0x0647, // ة -> ه
      _ => rune,
    };

    final isSpace = mapped == 0x0020;
    if (isSpace && lastWasSpace) continue;
    buffer.writeCharCode(mapped);
    lastWasSpace = isSpace;
  }

  return buffer.toString().trim();
}

bool _isDiacritic(int rune) {
  // الحركات والهمزات (فتحة..همزة تحت) + الألف الخنجرية
  if (rune >= 0x064B && rune <= 0x0655) return true;
  if (rune == 0x0670) return true;
  // علامات الوقف القرآنية الصغيرة
  if (rune >= 0x06D6 && rune <= 0x06ED) return true;
  // التطويل
  if (rune == 0x0640) return true;
  return false;
}
