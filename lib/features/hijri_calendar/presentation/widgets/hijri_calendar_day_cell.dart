import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/islamic_occasion.dart';

/// خانة يوم واحد ضمن شبكة التقويم الهجري: الرقم الهجري كبيراً، التاريخ
/// الميلادي الموازي صغيراً أسفله، تمييز ذهبي ليوم اليوم، ونقطة صغيرة إن
/// وافق هذا اليوم مناسبة دينية معروفة (اضغط لعرض اسمها).
class HijriCalendarDayCell extends StatelessWidget {
  const HijriCalendarDayCell({
    super.key,
    required this.year,
    required this.month,
    required this.day,
  });

  final int year;
  final int month;
  final int day;

  @override
  Widget build(BuildContext context) {
    final gregorian = HijriCalendar().hijriToGregorian(year, month, day);
    final today = HijriCalendar.fromDate(DateTime.now());
    final isToday =
        today.hYear == year && today.hMonth == month && today.hDay == day;
    final occasion = findOccasionFor(hijriMonth: month, hijriDay: day);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: occasion == null
          ? null
          : () => showModalBottomSheet<void>(
              context: context,
              builder: (context) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    occasion.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isToday ? AppColors.gold.withValues(alpha: 0.22) : null,
          border: isToday
              ? Border.all(color: AppColors.gold, width: 1.4)
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: isToday ? AppColors.goldLight : null,
                  ),
                ),
                Text(
                  '${gregorian.day}/${gregorian.month}',
                  style: TextStyle(
                    fontSize: 9,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
            if (occasion != null)
              Positioned(
                top: 4,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
