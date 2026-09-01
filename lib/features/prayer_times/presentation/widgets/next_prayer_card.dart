import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/settings/custom_color_settings_provider.dart';
import '../../../../core/settings/numeral_style.dart';
import '../../../../core/settings/time_format_option.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_formatters.dart';
import '../../../quran/presentation/screens/surah_list_screen.dart';
import '../../domain/daily_prayer_times.dart';
import '../providers/prayer_countdown_provider.dart';
import 'prayer_countdown_ring.dart';

/// البطاقة الرئيسية أعلى الشاشة: عدّاد تنازلي نحو أذان الصلاة القادمة (أو
/// الإقامة إن كنا في نافذتها) بجانب دائرة تقدّم فنية كبيرة، مطابقة لتصميم
/// تطبيقات المواقيت الفاخرة: كتلة نص على جهة، ودائرة زخرفية على الأخرى -
/// نفرض هنا اتجاهاً من اليسار لليمين خصيصاً لهذه البطاقة (بصرف النظر عن
/// اتجاه التطبيق العام RTL) لأن هذا هو الترتيب البصري المطلوب: النص يسار
/// والدائرة يمين.
class NextPrayerCard extends ConsumerWidget {
  const NextPrayerCard({
    super.key,
    required this.timeFormat,
    required this.numeralStyle,
  });

  final TimeFormatOption timeFormat;
  final NumeralStyle numeralStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // يراقب العدّاد النابض كل ثانية هنا فقط - بطاقة واحدة صغيرة تُعاد بناؤها
    // كل ثانية بدل الشاشة كلها (انظر توثيق highlightedPrayerProvider).
    final snapshot = ref.watch(prayerCountdownProvider).valueOrNull;
    if (snapshot == null) return const SizedBox.shrink();
    final isIqamah = snapshot.isWaitingForIqamah;

    final label = isIqamah ? 'الإقامة لصلاة' : 'الصلاة القادمة';
    final prayerLabel = isIqamah
        ? snapshot.iqamahPrayer!.arabicLabel
        : snapshot.nextPrayer.arabicLabel;
    final countdown = isIqamah
        ? snapshot.timeUntilIqamah!
        : snapshot.timeUntilNextPrayer;
    final targetTime = isIqamah
        ? snapshot.iqamahTime!
        : snapshot.nextPrayerTime;
    final progress = snapshot.progressFraction(DateTime.now());

    final customColors = ref.watch(customColorSettingsProvider);
    final custom = customColors.enabled;
    final textColor = custom ? customColors.textColor : null;
    final clockColor = custom ? customColors.clockColor : null;
    final cardBackground = custom ? customColors.backgroundColor : null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: cardBackground,
        gradient: cardBackground == null
            ? const LinearGradient(
                colors: [Color(0xFF10241E), Color(0xFF18332B)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              )
            : null,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.55),
          width: 1.4,
        ),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            Expanded(
              flex: 6,
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color:
                            textColor?.withValues(alpha: 0.85) ??
                            AppColors.goldLight.withValues(alpha: 0.85),
                        fontSize: 13.sp,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.mosque,
                          color: clockColor ?? AppColors.goldLight,
                          size: 18.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          prayerLabel,
                          style: TextStyle(
                            color: clockColor ?? AppColors.goldLight,
                            fontSize: 26.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      '${TimeFormatters.countdown(countdown, numeralStyle)} متبقٍ',
                      style: TextStyle(
                        color:
                            clockColor?.withValues(alpha: 0.85) ??
                            Colors.white70,
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'عند الساعة ${TimeFormatters.time(targetTime, timeFormat, numeralStyle)}',
                      style: TextStyle(
                        color:
                            textColor?.withValues(alpha: 0.7) ?? Colors.white38,
                        fontSize: 11.sp,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Container(
                      height: 1,
                      color: AppColors.gold.withValues(alpha: 0.25),
                    ),
                    SizedBox(height: 14.h),
                    Material(
                      color: AppColors.gold.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12.r),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12.r),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SurahListScreen(),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 9.h,
                          ),
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.menu_book,
                                  color: AppColors.goldLight,
                                  size: 16.sp,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'القرآن',
                                  style: TextStyle(
                                    color: AppColors.goldLight,
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Center(
                child: PrayerCountdownRing(progress: progress, size: 130.w),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
