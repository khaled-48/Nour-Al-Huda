/// مناسبة دينية ثابتة التاريخ في التقويم الهجري (شهر/يوم)، تُحسب محلياً
/// بدون إنترنت. ملاحظة: بعض المناسبات (كبداية رمضان والعيدين) قد تختلف
/// عملياً بيوم حسب رؤية الهلال في كل بلد؛ هذا التاريخ حسابي تقريبي.
class IslamicOccasion {
  const IslamicOccasion({
    required this.hijriMonth,
    required this.hijriDay,
    required this.name,
  });

  final int hijriMonth;
  final int hijriDay;
  final String name;
}

const List<IslamicOccasion> islamicOccasions = [
  IslamicOccasion(hijriMonth: 1, hijriDay: 1, name: 'رأس السنة الهجرية'),
  IslamicOccasion(hijriMonth: 1, hijriDay: 10, name: 'يوم عاشوراء'),
  IslamicOccasion(hijriMonth: 3, hijriDay: 12, name: 'المولد النبوي الشريف'),
  IslamicOccasion(hijriMonth: 7, hijriDay: 27, name: 'ليلة الإسراء والمعراج'),
  IslamicOccasion(hijriMonth: 8, hijriDay: 15, name: 'ليلة النصف من شعبان'),
  IslamicOccasion(hijriMonth: 9, hijriDay: 1, name: 'بداية شهر رمضان المبارك'),
  IslamicOccasion(
    hijriMonth: 9,
    hijriDay: 27,
    name: 'ليلة القدر (الأشهر عند كثير من العلماء)',
  ),
  IslamicOccasion(hijriMonth: 10, hijriDay: 1, name: 'عيد الفطر المبارك'),
  IslamicOccasion(hijriMonth: 12, hijriDay: 9, name: 'يوم عرفة'),
  IslamicOccasion(hijriMonth: 12, hijriDay: 10, name: 'عيد الأضحى المبارك'),
  IslamicOccasion(hijriMonth: 12, hijriDay: 11, name: 'أول أيام التشريق'),
  IslamicOccasion(hijriMonth: 12, hijriDay: 12, name: 'ثاني أيام التشريق'),
  IslamicOccasion(hijriMonth: 12, hijriDay: 13, name: 'ثالث أيام التشريق'),
];

/// يعيد المناسبة المطابقة لهذا اليوم الهجري إن وُجدت.
IslamicOccasion? findOccasionFor({
  required int hijriMonth,
  required int hijriDay,
}) {
  for (final occasion in islamicOccasions) {
    if (occasion.hijriMonth == hijriMonth && occasion.hijriDay == hijriDay) {
      return occasion;
    }
  }
  return null;
}
