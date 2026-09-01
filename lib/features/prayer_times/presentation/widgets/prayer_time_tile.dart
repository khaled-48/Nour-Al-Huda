import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/settings/custom_color_settings_provider.dart';
import '../../../../core/settings/numeral_style.dart';
import '../../../../core/settings/time_format_option.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_formatters.dart';
import '../../../../core/widgets/tv_focusable.dart';
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

/// صفّ واحد ضمن قائمة مواقيت الصلاة المتصلة: أيقونة الصلاة داخل دائرة
/// ذهبية خافتة على اليمين، الوقت على اليسار (فاصل رأسي ذهبي رفيع بينهما)،
/// بلا حدود أو خلفية خاصة به - فقط الصلاة المُستهدَفة الآن ([isCurrent])
/// تُبرَز بتوهّج ذهبي خفيف وشريط جانبي، لتبدو القائمة كبطاقة متصلة واحدة
/// كما في تصاميم مواقيت الصلاة الفاخرة بدل سلسلة بطاقات منفصلة. الجهة
/// المستدعية (PrayerTimesScreen) تُمرّر هنا صلاة الإقامة الجارية إن
/// وُجدت، وإلا الصلاة القادمة - فيتحرّك الإبراز تلقائياً مع تقدّم اليوم
/// بدل أن يبقى عالقاً على صلاة فاتت. في وضع التلفاز ([large]) تكبر كل
/// الخطوط والأيقونات للقراءة من بعيد، ويصبح الصفّ كاملاً قابلاً للتركيز
/// عبر D-pad (اختياره بزر الإدخال يفتح تعديل الوقت).
class PrayerTimeTile extends ConsumerWidget {
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
    this.large = false,
    this.autofocus = false,
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

  /// تكبير الخطوط والأيقونات لقراءة مريحة من بعيد (واجهة التلفاز)، وجعل
  /// الصفّ كاملاً هدفاً واحداً للتركيز بدل مناطق لمس دقيقة صغيرة.
  final bool large;
  final bool autofocus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeSize = large ? 30.sp : 16.sp;
    final labelSize = large ? 22.sp : 15.sp;
    final iconBoxSize = large ? 52.w : 34.w;
    final iconSize = large ? 26.sp : 18.sp;

    final customColors = ref.watch(customColorSettingsProvider);
    final custom = customColors.enabled;
    final textColor = custom ? customColors.textColor : null;
    final clockColor = custom ? customColors.clockColor : null;

    final row = Container(
      decoration: BoxDecoration(
        color: isCurrent
            ? AppColors.gold.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
        border: isCurrent
            ? Border.all(color: AppColors.gold.withValues(alpha: 0.5))
            : null,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 14.w,
        vertical: large ? 18.h : 12.h,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: large ? null : onEditTime,
            child: Row(
              children: [
                if (isTimeAdjusted)
                  Padding(
                    padding: EdgeInsets.only(left: 4.w),
                    child: Icon(
                      Icons.edit_calendar_outlined,
                      size: 13.sp,
                      color: AppColors.goldLight.withValues(alpha: 0.7),
                    ),
                  ),
                Text(
                  TimeFormatters.time(time, timeFormat, numeralStyle),
                  style: TextStyle(
                    fontSize: timeSize,
                    fontWeight: FontWeight.bold,
                    color:
                        clockColor ??
                        (isCurrent ? AppColors.goldLight : Colors.white70),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Container(
            width: 1,
            height: (large ? 30 : 22).h,
            color: AppColors.gold.withValues(alpha: 0.25),
          ),
          const Spacer(),
          if (!large && prayer.hasIqamah && iqamahOffsetMinutes != null)
            GestureDetector(
              onTap: onEditIqamah,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      size: 14.sp,
                      color: Colors.white38,
                    ),
                    SizedBox(width: 4.w),
                    // نصان منفصلان بدل نص واحد مُلحَق برقم ("إقامة +15د"):
                    // إلحاق حرف عربي واحد مباشرة بعد رقم بلا فاصل يُربك
                    // خوارزمية Unicode Bidi فيُزيح الحرف بصرياً فوق النص
                    // المجاور (مشكلة موثّقة في فلاتر). الفصل هنا يعزل كل
                    // نص في فقرة اتجاه مستقلة فيمنع أي إعادة ترتيب بينها.
                    Text(
                      'إقامة',
                      style: TextStyle(fontSize: 11.sp, color: Colors.white38),
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      '+$iqamahOffsetMinutes',
                      style: TextStyle(fontSize: 11.sp, color: Colors.white38),
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      'د',
                      style: TextStyle(fontSize: 11.sp, color: Colors.white38),
                    ),
                  ],
                ),
              ),
            ),
          Flexible(
            child: Text(
              prayer.arabicLabel,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: labelSize,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                color:
                    textColor ??
                    (isCurrent
                        ? AppColors.goldLight
                        : Colors.white.withValues(alpha: 0.9)),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Container(
            width: iconBoxSize,
            height: iconBoxSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withValues(alpha: isCurrent ? 0.22 : 0.12),
            ),
            child: Icon(
              _iconFor(prayer),
              size: iconSize,
              color: isCurrent
                  ? AppColors.goldLight
                  : AppColors.gold.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );

    if (!large) return row;
    return TvFocusable(
      autofocus: autofocus,
      borderRadius: 12,
      onTap: onEditTime ?? () {},
      child: row,
    );
  }
}
