import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/core/settings/numeral_style.dart';
import 'package:islamic_app/core/settings/time_format_option.dart';
import 'package:islamic_app/core/utils/time_formatters.dart';

void main() {
  group('TimeFormatters.time', () {
    test('h24 يعرض الساعة والدقيقة بصيغة 24 ساعة', () {
      final time = DateTime(2026, 1, 1, 17, 32);
      expect(TimeFormatters.time(time, TimeFormatOption.h24), '17:32');
    });

    test('h12 قبل الظهر يعرض "ص"', () {
      final time = DateTime(2026, 1, 1, 5, 32);
      expect(TimeFormatters.time(time, TimeFormatOption.h12), '05:32 ص');
    });

    test('h12 بعد الظهر يعرض "م"', () {
      final time = DateTime(2026, 1, 1, 17, 32);
      expect(TimeFormatters.time(time, TimeFormatOption.h12), '05:32 م');
    });

    test('h12 عند منتصف الليل يعرض 12 صباحاً', () {
      final time = DateTime(2026, 1, 1, 0, 5);
      expect(TimeFormatters.time(time, TimeFormatOption.h12), '12:05 ص');
    });

    test('h12 عند الظهر تماماً يعرض 12 مساءً', () {
      final time = DateTime(2026, 1, 1, 12, 0);
      expect(TimeFormatters.time(time, TimeFormatOption.h12), '12:00 م');
    });

    test('يحوّل الأرقام إلى عربية هندية عند طلب ذلك', () {
      final time = DateTime(2026, 1, 1, 17, 32);
      expect(
        TimeFormatters.time(time, TimeFormatOption.h24, NumeralStyle.arabic),
        '١٧:٣٢',
      );
    });
  });

  group('TimeFormatters.countdown', () {
    test('يحذف الساعات عندما تكون صفراً', () {
      expect(
        TimeFormatters.countdown(const Duration(minutes: 5, seconds: 9)),
        '05:09',
      );
    });

    test('يعرض الساعات عند وجودها', () {
      expect(
        TimeFormatters.countdown(
          const Duration(hours: 1, minutes: 2, seconds: 3),
        ),
        '01:02:03',
      );
    });

    test('مدة سالبة تُعامَل كصفر', () {
      expect(TimeFormatters.countdown(const Duration(seconds: -5)), '00:00');
    });
  });
}
