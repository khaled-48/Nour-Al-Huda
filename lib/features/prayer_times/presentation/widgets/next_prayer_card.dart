import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/settings/numeral_style.dart';
import '../../../../core/settings/time_format_option.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_formatters.dart';
import '../../domain/daily_prayer_times.dart';
import '../providers/prayer_countdown_provider.dart';

/// البطاقة الرئيسية أعلى الشاشة: تعرض إما العدّاد التنازلي نحو أذان الصلاة
/// القادمة، أو - إن كنا في نافذة انتظار الإقامة - العدّاد التنازلي للإقامة.
class NextPrayerCard extends StatelessWidget {
  const NextPrayerCard({
    super.key,
    required this.snapshot,
    required this.timeFormat,
    required this.numeralStyle,
  });

  final PrayerCountdownSnapshot snapshot;
  final TimeFormatOption timeFormat;
  final NumeralStyle numeralStyle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isIqamah = snapshot.isWaitingForIqamah;

    final title = isIqamah
        ? 'الإقامة لصلاة ${snapshot.iqamahPrayer!.arabicLabel}'
        : 'الصلاة القادمة: ${snapshot.nextPrayer.arabicLabel}';
    final countdown = isIqamah ? snapshot.timeUntilIqamah! : snapshot.timeUntilNextPrayer;
    final targetTime = isIqamah ? snapshot.iqamahTime! : snapshot.nextPrayerTime;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.primary.withValues(alpha: 0.75)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(color: scheme.onPrimary, fontSize: 15.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12.h),
          Text(
            TimeFormatters.countdown(countdown, numeralStyle),
            style: TextStyle(
              color: scheme.onPrimary,
              fontSize: 44.sp,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'عند الساعة ${TimeFormatters.time(targetTime, timeFormat, numeralStyle)}',
            style: TextStyle(color: scheme.onPrimary.withValues(alpha: 0.9), fontSize: 13.sp),
          ),
        ],
      ),
    );
  }
}
