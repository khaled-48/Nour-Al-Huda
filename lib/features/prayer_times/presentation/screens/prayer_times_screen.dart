import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/settings/numeral_style.dart';
import '../../../../core/settings/numeral_style_provider.dart';
import '../../../../core/settings/time_format_option.dart';
import '../../../../core/settings/time_format_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/islamic_pattern_background.dart';
import '../../../hijri_calendar/presentation/widgets/hijri_date_banner.dart';
import '../../domain/daily_prayer_times.dart';
import '../providers/location_provider.dart';
import '../providers/prayer_countdown_provider.dart';
import '../providers/prayer_settings_provider.dart';
import '../providers/prayer_times_provider.dart';
import '../widgets/edit_iqamah_offset_dialog.dart';
import '../widgets/edit_prayer_time_dialog.dart';
import '../widgets/next_prayer_card.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('مواقيت الصلاة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.explore_outlined),
            tooltip: 'اتجاه القبلة',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const QiblaCompassScreen()),
            ),
          ),
        ],
      ),
      body: IslamicPatternBackground(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
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
                        const HijriDateBanner(),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: card),
                              Expanded(child: SingleChildScrollView(child: list)),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView(
                    children: [const HijriDateBanner(), card, list],
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

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: PrayerName.values.map((prayer) {
          return PrayerTimeTile(
            prayer: prayer,
            time: today.timeOf(prayer),
            isCurrent: prayer == snapshot.currentPrayer,
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
                ref.read(prayerAdjustmentsProvider.notifier).setAdjustment(prayer, newOffset);
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
                      ref.read(iqamahOffsetsProvider.notifier).setOffset(prayer, newValue);
                    }
                  }
                : null,
          );
        }).toList(),
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
            Icon(Icons.location_off_outlined, size: 56.sp, color: Theme.of(context).colorScheme.error),
            SizedBox(height: 16.h),
            Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 14.sp)),
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
