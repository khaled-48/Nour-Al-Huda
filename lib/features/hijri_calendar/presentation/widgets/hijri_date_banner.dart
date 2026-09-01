import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/settings/custom_color_settings_provider.dart';
import '../../../../core/settings/numeral_style_provider.dart';
import '../../../../core/utils/numeral_formatter.dart';
import '../../domain/islamic_occasion.dart';

/// يعرض التاريخ الهجري لليوم الحالي (وموازيه الميلادي)، مع تمييز أي مناسبة
/// دينية توافق هذا اليوم - كل ذلك محسوب محلياً بدون إنترنت.
class HijriDateBanner extends ConsumerWidget {
  const HijriDateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final hijri = HijriCalendar.fromDate(now);
    final occasion = findOccasionFor(
      hijriMonth: hijri.hMonth,
      hijriDay: hijri.hDay,
    );
    final scheme = Theme.of(context).colorScheme;
    final numeralStyle = ref.watch(numeralStyleProvider);
    final customColors = ref.watch(customColorSettingsProvider);
    final dateColor = customColors.enabled ? customColors.dateColor : null;

    // نبني التاريخ الميلادي يدوياً (بدل الاعتماد على أرقام لغة intl 'ar'
    // التي تفرض الأرقام العربية دائماً) حتى يحترم نظام الأرقام الذي
    // يختاره المستخدم، تماماً كبقية التطبيق.
    final gregorianMonthName = intl.DateFormat('MMMM', 'ar').format(now);
    final gregorianRaw = '${now.day} $gregorianMonthName ${now.year}';
    final hijriRaw =
        '${hijri.hDay} ${hijri.getLongMonthName()} ${hijri.hYear} هـ';

    final gregorianLabel = formatNumerals(gregorianRaw, numeralStyle);
    final hijriLabel = formatNumerals(hijriRaw, numeralStyle);

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_month_outlined,
                size: 16.sp,
                color: dateColor ?? scheme.onSurfaceVariant,
              ),
              SizedBox(width: 6.w),
              Text(
                '$hijriLabel - $gregorianLabel',
                style: TextStyle(
                  fontSize: 12.5.sp,
                  color: dateColor ?? scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          if (occasion != null) ...[
            SizedBox(height: 10.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                occasion.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
