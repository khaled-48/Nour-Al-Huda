import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

import 'hijri_calendar_day_cell.dart';

/// شبكة أيام شهر هجري واحد (٧ أعمدة، الأسبوع يبدأ سبتاً كما هو معتاد
/// إسلامياً)، مع خانات فارغة قبل اليوم الأول بعدد أيام الأسبوع السابقة له.
class HijriCalendarGrid extends StatelessWidget {
  const HijriCalendarGrid({super.key, required this.year, required this.month});

  final int year;
  final int month;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = HijriCalendar().getDaysInMonth(year, month);
    final firstWeekday = HijriCalendar()
        .hijriToGregorian(year, month, 1)
        .weekday;
    // DateTime.weekday: الاثنين=1..الأحد=7. الأسبوع الهجري يبدأ سبتاً
    // (DateTime.saturday=6)، فنحسب الإزاحة نسبةً إليه.
    final leadingBlanks = (firstWeekday - DateTime.saturday + 7) % 7;

    const weekdayLabels = [
      'سبت',
      'أحد',
      'اثنين',
      'ثلاثاء',
      'أربعاء',
      'خميس',
      'جمعة',
    ];

    return Column(
      children: [
        Row(
          children: [
            for (final label in weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.9,
          children: [
            for (var i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
            for (var day = 1; day <= daysInMonth; day++)
              HijriCalendarDayCell(year: year, month: month, day: day),
          ],
        ),
      ],
    );
  }
}
