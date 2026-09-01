import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/daily_prayer_times.dart';
import 'prayer_settings_provider.dart';
import 'prayer_times_provider.dart';

/// ينبض كل ثانية لإعادة حساب العدّادات التنازلية بدون إعادة طلب الموقع
/// أو إعادة حساب مواقيت الصلاة (تلك تُحسب مرة واحدة فقط ما لم يتغيّر الموقع).
final _clockTickProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});

/// لقطة كاملة عن حالة "متابعة الصلاة" اللحظية: الصلاة القادمة ووقتها،
/// والوقت المتبقي لها، وإن كنا حالياً في فترة انتظار الإقامة بعد أذان صلاة
/// تُقام جماعة.
class PrayerCountdownSnapshot {
  const PrayerCountdownSnapshot({
    required this.currentPrayer,
    required this.currentPrayerTime,
    required this.nextPrayer,
    required this.nextPrayerTime,
    required this.timeUntilNextPrayer,
    this.iqamahPrayer,
    this.iqamahTime,
    this.timeUntilIqamah,
  });

  final PrayerName currentPrayer;
  final DateTime currentPrayerTime;
  final PrayerName nextPrayer;
  final DateTime nextPrayerTime;
  final Duration timeUntilNextPrayer;

  /// نسبة الوقت المنقضي من الفترة بين أذان الصلاة الحالية والصلاة القادمة،
  /// تُستخدم لملء القوس في الدائرة التنازلية.
  double progressFraction(DateTime now) {
    final total = nextPrayerTime.difference(currentPrayerTime).inSeconds;
    if (total <= 0) return 0;
    final elapsed = now.difference(currentPrayerTime).inSeconds;
    return (elapsed / total).clamp(0, 1).toDouble();
  }

  /// غير فارغة فقط أثناء نافذة انتظار الإقامة (بعد الأذان وقبل انقضاء مدة الإقامة).
  final PrayerName? iqamahPrayer;
  final DateTime? iqamahTime;
  final Duration? timeUntilIqamah;

  bool get isWaitingForIqamah => iqamahPrayer != null;
}

final prayerCountdownProvider = Provider<AsyncValue<PrayerCountdownSnapshot>>((ref) {
  final todayAsync = ref.watch(dailyPrayerTimesProvider);
  final tickAsync = ref.watch(_clockTickProvider);
  final iqamahOffsets = ref.watch(iqamahOffsetsProvider);

  if (todayAsync.isLoading || tickAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (todayAsync.hasError) {
    return AsyncValue.error(todayAsync.error!, todayAsync.stackTrace!);
  }
  if (tickAsync.hasError) {
    return AsyncValue.error(tickAsync.error!, tickAsync.stackTrace!);
  }

  final today = todayAsync.value!;
  final now = tickAsync.value ?? DateTime.now();

  final (nextPrayer, nextPrayerTime) = today.nextPrayer(now);
  final (currentPrayer, currentPrayerAdhanTime) = today.currentPrayer(now);

  PrayerName? iqamahPrayer;
  DateTime? iqamahTime;
  Duration? timeUntilIqamah;

  if (currentPrayer.hasIqamah) {
    final offsetMinutes = iqamahOffsets[currentPrayer] ?? 0;
    final candidateIqamahTime = currentPrayerAdhanTime.add(Duration(minutes: offsetMinutes));
    if (now.isBefore(candidateIqamahTime)) {
      iqamahPrayer = currentPrayer;
      iqamahTime = candidateIqamahTime;
      timeUntilIqamah = candidateIqamahTime.difference(now);
    }
  }

  return AsyncValue.data(PrayerCountdownSnapshot(
    currentPrayer: currentPrayer,
    currentPrayerTime: currentPrayerAdhanTime,
    nextPrayer: nextPrayer,
    nextPrayerTime: nextPrayerTime,
    timeUntilNextPrayer: nextPrayerTime.difference(now),
    iqamahPrayer: iqamahPrayer,
    iqamahTime: iqamahTime,
    timeUntilIqamah: timeUntilIqamah,
  ));
});
