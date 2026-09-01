import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/core/settings/numeral_style.dart';
import 'package:islamic_app/core/utils/numeral_formatter.dart';

void main() {
  group('formatNumerals', () {
    test('western تُبقي الأرقام الإنجليزية كما هي', () {
      expect(formatNumerals('12:34', NumeralStyle.western), '12:34');
    });

    test('arabic يحوّل كل رقم إنجليزي إلى عربي هندي', () {
      expect(formatNumerals('0123456789', NumeralStyle.arabic), '٠١٢٣٤٥٦٧٨٩');
    });

    test('arabic يُبقي الأحرف غير الرقمية دون تغيير', () {
      expect(formatNumerals('12:34 ص', NumeralStyle.arabic), '١٢:٣٤ ص');
    });
  });
}
