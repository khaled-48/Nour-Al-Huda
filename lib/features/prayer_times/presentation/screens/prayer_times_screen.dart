import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/settings/custom_color_settings_provider.dart';
import '../../../../core/settings/numeral_style.dart';
import '../../../../core/settings/numeral_style_provider.dart';
import '../../../../core/settings/time_format_option.dart';
import '../../../../core/settings/time_format_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/tv/tv_mode.dart';
import '../../../../core/utils/time_formatters.dart';
import '../../../../core/widgets/islamic_pattern_background.dart';
import '../../../../core/widgets/tv_focusable.dart';
import '../../../hijri_calendar/presentation/widgets/hijri_date_banner.dart';
import '../../domain/daily_prayer_times.dart';
import '../providers/location_labels_provider.dart';
import '../providers/location_provider.dart';
import '../providers/prayer_countdown_provider.dart';
import '../providers/prayer_settings_provider.dart';
import '../providers/prayer_times_provider.dart';
import '../widgets/edit_iqamah_offset_dialog.dart';
import '../widgets/edit_prayer_time_dialog.dart';
import '../widgets/next_prayer_card.dart';
import '../widgets/prayer_countdown_ring.dart';
import '../widgets/prayer_time_tile.dart';
import 'qibla_compass_screen.dart';

class PrayerTimesScreen extends ConsumerWidget {
  const PrayerTimesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countdownAsync = ref.watch(prayerCountdownProvider);
    final todayAsync = ref.watch(dailyPrayerTimesProvider);
    final rawTodayAsync = ref.watch(rawDailyPrayerTimesProvider);
    final timeFormat = ref.watch(timeFormatProvider);
    final numeralStyle = ref.watch(numeralStyleProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tvOverride = ref.watch(tvModeOverrideProvider);
    final tv = isTvMode(context, tvOverride);

    return Scaffold(
      appBar: tv
          ? null
          : AppBar(
              title: const Text('مواقيت الصلاة'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.explore_outlined),
                  tooltip: 'اتجاه القبلة',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const QiblaCompassScreen(),
                    ),
                  ),
                ),
              ],
            ),
      body: IslamicPatternBackground(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        patternColor: AppColors.gold,
        child: SafeArea(
          child: countdownAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _LocationErrorView(message: error.toString()),
            data: (snapshot) {
              final today = todayAsync.value;
              final rawToday = rawTodayAsync.value;
              if (today == null || rawToday == null) {
                return const Center(child: CircularProgressIndicator());
              }

              if (tv) {
                return Column(
                  children: [
                    const _LocationLabelHeader(),
                    Expanded(
                      child: _TvPrayerLayout(
                        today: today,
                        rawToday: rawToday,
                        snapshot: snapshot,
                        timeFormat: timeFormat,
                        numeralStyle: numeralStyle,
                      ),
                    ),
                  ],
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWideScreen = constraints.maxWidth >= 700;
                  final list = _PrayerTimesList(
                    today: today,
                    rawToday: rawToday,
                    snapshot: snapshot,
                    timeFormat: timeFormat,
                    numeralStyle: numeralStyle,
                  );
                  final card = Padding(
                    padding: EdgeInsets.all(16.w),
                    child: NextPrayerCard(
                      snapshot: snapshot,
                      timeFormat: timeFormat,
                      numeralStyle: numeralStyle,
                    ),
                  );

                  if (isWideScreen) {
                    return Column(
                      children: [
                        const _LocationLabelHeader(),
                        const HijriDateBanner(),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: card),
                              Expanded(
                                child: SingleChildScrollView(child: list),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView(
                    children: [
                      const _LocationLabelHeader(),
                      const HijriDateBanner(),
                      card,
                      list,
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

/// يعرض اسم المدينة واسم المسجد أعلى الشاشة إن أدخلهما المستخدم يدوياً في
/// الإعدادات (حساب المواقيت نفسه يبقى بالإحداثيات دائماً بلا علاقة بهذا
/// العرض)؛ لا يظهر شيء إطلاقاً إن لم يُدخل أياً منهما.
class _LocationLabelHeader extends ConsumerWidget {
  const _LocationLabelHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labels = ref.watch(locationLabelsProvider);
    if (labels.isEmpty) return const SizedBox.shrink();

    final customColors = ref.watch(customColorSettingsProvider);
    final color = customColors.enabled ? customColors.dateColor : null;
    final effectiveColor = color ?? AppColors.goldLight;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (labels.mosqueName != null) ...[
            Icon(Icons.mosque, size: 15.sp, color: effectiveColor),
            SizedBox(width: 6.w),
            Text(
              labels.mosqueName!,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: effectiveColor,
              ),
            ),
          ],
          if (labels.mosqueName != null && labels.cityName != null) ...[
            SizedBox(width: 8.w),
            Text(
              '-',
              style: TextStyle(color: effectiveColor.withValues(alpha: 0.6)),
            ),
            SizedBox(width: 8.w),
          ],
          if (labels.cityName != null) ...[
            if (labels.mosqueName == null)
              Icon(Icons.location_city, size: 15.sp, color: effectiveColor),
            if (labels.mosqueName == null) SizedBox(width: 6.w),
            Text(
              labels.cityName!,
              style: TextStyle(
                fontSize: 12.5.sp,
                color: effectiveColor.withValues(alpha: 0.85),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// تصميم مخصّص لشاشات التلفاز: الدائرة التنازلية كبيرة في منتصف الشاشة،
/// وقائمة أوقات الصلوات الست بجانبها بخطوط عريضة واضحة تُقرأ من غرفة
/// المعيشة، وكل صفّ/بطاقة قابل للتركيز عبر D-pad (لا تمرير باللمس هنا،
/// فالمحتوى كله يظهر دفعة واحدة بلا سكرول).
class _TvPrayerLayout extends ConsumerWidget {
  const _TvPrayerLayout({
    required this.today,
    required this.rawToday,
    required this.snapshot,
    required this.timeFormat,
    required this.numeralStyle,
  });

  final DailyPrayerTimes today;
  final DailyPrayerTimes rawToday;
  final PrayerCountdownSnapshot snapshot;
  final TimeFormatOption timeFormat;
  final NumeralStyle numeralStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iqamahOffsets = ref.watch(iqamahOffsetsProvider);
    final adjustments = ref.watch(prayerAdjustmentsProvider);
    final isIqamah = snapshot.isWaitingForIqamah;
    final label = isIqamah ? 'الإقامة لصلاة' : 'الصلاة القادمة';
    final prayerLabel = isIqamah
        ? snapshot.iqamahPrayer!.arabicLabel
        : snapshot.nextPrayer.arabicLabel;
    final countdown = isIqamah
        ? snapshot.timeUntilIqamah!
        : snapshot.timeUntilNextPrayer;
    final progress = snapshot.progressFraction(DateTime.now());
    final customColors = ref.watch(customColorSettingsProvider);
    final textColor = customColors.enabled ? customColors.textColor : null;
    final clockColor = customColors.enabled ? customColors.clockColor : null;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1300),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    for (final prayer in PrayerName.values) ...[
                      if (prayer != PrayerName.values.first)
                        const SizedBox(height: 10),
                      PrayerTimeTile(
                        prayer: prayer,
                        time: today.timeOf(prayer),
                        isCurrent: prayer == (snapshot.iqamahPrayer ?? snapshot.nextPrayer),
                        iqamahOffsetMinutes: iqamahOffsets[prayer],
                        timeFormat: timeFormat,
                        numeralStyle: numeralStyle,
                        isTimeAdjusted: (adjustments[prayer] ?? 0) != 0,
                        large: true,
                        autofocus: prayer == PrayerName.values.first,
                        onEditTime: () async {
                          final newOffset = await showEditPrayerTimeDialog(
                            context: context,
                            prayerLabel: prayer.arabicLabel,
                            currentAdjustedTime: today.timeOf(prayer),
                            rawCalculatedTime: rawToday.timeOf(prayer),
                          );
                          if (newOffset != null) {
                            ref
                                .read(prayerAdjustmentsProvider.notifier)
                                .setAdjustment(prayer, newOffset);
                          }
                        },
                        onEditIqamah: null,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 48),
              Expanded(
                flex: 5,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PrayerCountdownRing(progress: progress, size: 280),
                    const SizedBox(height: 28),
                    Text(
                      label,
                      style: TextStyle(
                        color:
                            textColor?.withValues(alpha: 0.85) ??
                            AppColors.goldLight.withValues(alpha: 0.85),
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      prayerLabel,
                      style: TextStyle(
                        color: clockColor ?? AppColors.goldLight,
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${TimeFormatters.countdown(countdown, numeralStyle)} متبقٍ',
                      style: TextStyle(
                        color:
                            clockColor?.withValues(alpha: 0.85) ??
                            Colors.white70,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TvFocusable(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const QiblaCompassScreen(),
                        ),
                      ),
                      borderRadius: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.explore_outlined,
                              color: AppColors.goldLight,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'اتجاه القبلة',
                              style: TextStyle(
                                color: AppColors.goldLight,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrayerTimesList extends ConsumerWidget {
  const _PrayerTimesList({
    required this.today,
    required this.rawToday,
    required this.snapshot,
    required this.timeFormat,
    required this.numeralStyle,
  });

  final DailyPrayerTimes today;
  final DailyPrayerTimes rawToday;
  final PrayerCountdownSnapshot snapshot;
  final TimeFormatOption timeFormat;
  final NumeralStyle numeralStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iqamahOffsets = ref.watch(iqamahOffsetsProvider);
    final adjustments = ref.watch(prayerAdjustmentsProvider);
    final customColors = ref.watch(customColorSettingsProvider);
    final cardBackground = customColors.enabled
        ? customColors.backgroundColor
        : null;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: cardBackground,
          gradient: cardBackground == null
              ? const LinearGradient(
                  colors: [Color(0xFF10241E), Color(0xFF18332B)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                )
              : null,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            for (final prayer in PrayerName.values) ...[
              if (prayer != PrayerName.values.first)
                Container(
                  height: 1,
                  margin: EdgeInsets.symmetric(horizontal: 14.w),
                  color: AppColors.gold.withValues(alpha: 0.12),
                ),
              PrayerTimeTile(
                prayer: prayer,
                time: today.timeOf(prayer),
                isCurrent: prayer == (snapshot.iqamahPrayer ?? snapshot.nextPrayer),
                iqamahOffsetMinutes: iqamahOffsets[prayer],
                timeFormat: timeFormat,
                numeralStyle: numeralStyle,
                isTimeAdjusted: (adjustments[prayer] ?? 0) != 0,
                onEditTime: () async {
                  final newOffset = await showEditPrayerTimeDialog(
                    context: context,
                    prayerLabel: prayer.arabicLabel,
                    currentAdjustedTime: today.timeOf(prayer),
                    rawCalculatedTime: rawToday.timeOf(prayer),
                  );
                  if (newOffset != null) {
                    ref
                        .read(prayerAdjustmentsProvider.notifier)
                        .setAdjustment(prayer, newOffset);
                  }
                },
                onEditIqamah: prayer.hasIqamah
                    ? () async {
                        final newValue = await showEditIqamahOffsetDialog(
                          context: context,
                          prayer: prayer,
                          currentMinutes: iqamahOffsets[prayer] ?? 0,
                        );
                        if (newValue != null) {
                          ref
                              .read(iqamahOffsetsProvider.notifier)
                              .setOffset(prayer, newValue);
                        }
                      }
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LocationErrorView extends ConsumerWidget {
  const _LocationErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_off_outlined,
              size: 56.sp,
              color: Theme.of(context).colorScheme.error,
            ),
            SizedBox(height: 16.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp),
            ),
            SizedBox(height: 20.h),
            FilledButton.icon(
              onPressed: () => ref.read(locationProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
