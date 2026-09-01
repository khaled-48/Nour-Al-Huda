import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/features/hijri_calendar/domain/islamic_occasion.dart';

void main() {
  test('يجد المناسبة المطابقة للشهر واليوم الهجريين', () {
    final occasion = findOccasionFor(hijriMonth: 10, hijriDay: 1);
    expect(occasion?.name, 'عيد الفطر المبارك');
  });

  test('يعيد null ليوم لا يوافق أي مناسبة معروفة', () {
    final occasion = findOccasionFor(hijriMonth: 2, hijriDay: 15);
    expect(occasion, isNull);
  });

  test('كل مناسبة لها شهر هجري ضمن 1-12 ويوم ضمن 1-30', () {
    for (final occasion in islamicOccasions) {
      expect(occasion.hijriMonth, inInclusiveRange(1, 12));
      expect(occasion.hijriDay, inInclusiveRange(1, 30));
      expect(occasion.name, isNotEmpty);
    }
  });
}
