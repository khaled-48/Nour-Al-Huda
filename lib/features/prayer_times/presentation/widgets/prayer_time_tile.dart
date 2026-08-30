import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/settings/numeral_style.dart';
import '../../../../core/settings/time_format_option.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_formatters.dart';
import '../../domain/daily_prayer_times.dart';

/// أيقونة مميزة لكل صلاة.
IconData _iconFor(PrayerName prayer) => switch (prayer) {
      PrayerName.fajr => Icons.nights_stay_outlined,
      PrayerName.sunrise => Icons.wb_twilight_outlined,
      PrayerName.dhuhr => Icons.wb_sunny_outlined,
      PrayerName.asr => Icons.sunny,
      PrayerName.maghrib => Icons.wb_twilight,
      PrayerName.isha => Icons.dark_mode_outlined,
    };

class PrayerTimeTile extends StatelessWidget {
  const PrayerTimeTile({
    super.key,
    required this.prayer,
    required this.time,
    required this.isCurrent,
    required this.iqamahOffsetMinutes,
    required this.onEditIqamah,
    required this.timeFormat,
    required this.numeralStyle,
    this.onEditTime,
    this.isTimeAdjusted = false,
  });

  final PrayerName prayer;
  final DateTime time;
  final bool isCurrent;
  final int? iqamahOffsetMinutes;
  final VoidCallback? onEditIqamah;
  final TimeFormatOption timeFormat;
  final NumeralStyle numeralStyle;

  /// يفتح منتقي وقت لمعايرة وقت هذه الصلاة يدوياً. null يعطّل التعديل
  /// (مثل الشروق، الذي يُعرض إعلامياً فقط).
  final VoidCallback? onEditTime;
  final bool isTimeAdjusted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isCurrent ? scheme.primaryContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.gold.withValues(alpha: isCurrent ? 0.6 : 0.25)),
      ),
      child: Row(
        children: [
          Icon(_iconFor(prayer), color: isCurrent ? scheme.onPrimaryContainer : scheme.primary),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              prayer.arabicLabel,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                color: isCurrent ? scheme.onPrimaryContainer : null,
              ),
            ),
          ),
          if (prayer.hasIqamah && iqamahOffsetMinutes != null)
            GestureDetector(
              onTap: onEditIqamah,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 14.sp, color: scheme.outline),
                    SizedBox(width: 4.w),
                    Text(
                      'إقامة +$iqamahOffsetMinutesد',
                      style: TextStyle(fontSize: 11.sp, color: scheme.outline),
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: onEditTime,
            child: Row(
              children: [
                if (isTimeAdjusted)
                  Padding(
                    padding: EdgeInsets.only(left: 4.w),
                    child: Icon(Icons.edit_calendar_outlined, size: 13.sp, color: scheme.outline),
                  ),
                Text(
                  TimeFormatters.time(time, timeFormat, numeralStyle),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: isCurrent ? scheme.onPrimaryContainer : scheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
