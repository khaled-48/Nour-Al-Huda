import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/core/utils/arabic_normalizer.dart';

void main() {
  group('normalizeArabic', () {
    test('يحذف التشكيل (الحركات)', () {
      expect(normalizeArabic('بِسْمِ اللَّهِ'), 'بسم الله');
    });

    test('يوحّد صور الألف (أ إ آ ٱ) إلى ألف عادية', () {
      expect(normalizeArabic('أإآٱ'), 'اااا');
    });

    test('يحوّل الألف المقصورة (ى) إلى ياء', () {
      expect(normalizeArabic('موسى'), 'موسي');
    });

    test('يحوّل التاء المربوطة (ة) إلى هاء', () {
      expect(normalizeArabic('رحمة'), 'رحمه');
    });

    test('يحذف التطويل (ـ)', () {
      expect(normalizeArabic('اللـــه'), 'الله');
    });

    test('يحذف علامات الوقف القرآنية الصغيرة', () {
      // ۘ (U+06D8) علامة وقف قرآنية صغيرة ضمن مدى الحذف.
      expect(normalizeArabic('شيءۘ'), 'شيء');
    });

    test('يوحّد المسافات المتكررة إلى مسافة واحدة ويقصّ الأطراف', () {
      expect(normalizeArabic('  الحمد    لله  '), 'الحمد لله');
    });

    test('نص فارغ أو بياض فقط يُعيد نصاً فارغاً', () {
      expect(normalizeArabic(''), '');
      expect(normalizeArabic('   '), '');
    });

    test('نص إنجليزي أو أرقام يمر بلا تغيير', () {
      expect(normalizeArabic('Surah 112'), 'Surah 112');
    });
  });
}
