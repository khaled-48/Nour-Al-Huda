import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/prayer_times_repository.dart';
import '../../domain/daily_prayer_times.dart';
import 'location_provider.dart';
import 'prayer_settings_provider.dart';

final _prayerTimesRepositoryProvider = Provider((ref) => const PrayerTimesRepository());

/// المواقيت المحسوبة فلكياً كما هي، بلا أي تعديل يدوي — تُستخدم كمرجع
/// عند حساب التعديل الجديد حين يغيّر المستخدم وقت صلاة يدوياً.
final rawDailyPrayerTimesProvider = Provider<AsyncValue<DailyPrayerTimes>>((ref) {
  final locationAsync = ref.watch(locationProvider);
  final settings = ref.watch(prayerSettingsProvider);
  final repository = ref.watch(_prayerTimesRepositoryProvider);

  return locationAsync.whenData((position) {
    return repository.calculateForDate(
      date: DateTime.now(),
      latitude: position.latitude,
      longitude: position.longitude,
      settings: settings,
    );
  });
});

/// مواقيت الصلاة الفعلية المعروضة للمستخدم: المحسوبة فلكياً بعد تطبيق أي
/// تعديل يدوي (بالدقائق) أضافه لمعايرة وقت صلاة معيّنة.
final dailyPrayerTimesProvider = Provider<AsyncValue<DailyPrayerTimes>>((ref) {
  final rawAsync = ref.watch(rawDailyPrayerTimesProvider);
  final adjustments = ref.watch(prayerAdjustmentsProvider);

  return rawAsync.whenData((raw) => raw.withAdjustments(adjustments));
});

/// عدد الأيام القادمة التي تُحسب وتُجدوَل لها إشعارات الأذان مسبقاً، حتى لا
/// تتوقف الإشعارات إن لم يُفتح التطبيق يومياً (تُمدَّد تلقائياً في كل مرة
/// يُفتح فيها التطبيق أو يتغيّر الموقع/الإعدادات).
const int prayerNotificationLookaheadDays = 7;

/// مواقيت الصلاة للأيام السبعة القادمة (بعد تطبيق التعديل اليدوي)، تُستخدم
/// فقط لجدولة إشعارات الأذان مقدَّماً.
final upcomingPrayerTimesProvider = Provider<AsyncValue<List<DailyPrayerTimes>>>((ref) {
  final locationAsync = ref.watch(locationProvider);
  final settings = ref.watch(prayerSettingsProvider);
  final adjustments = ref.watch(prayerAdjustmentsProvider);
  final repository = ref.watch(_prayerTimesRepositoryProvider);

  return locationAsync.whenData((position) {
    final today = DateTime.now();
    return List.generate(prayerNotificationLookaheadDays, (offset) {
      final date = DateTime(today.year, today.month, today.day).add(Duration(days: offset));
      final raw = repository.calculateForDate(
        date: date,
        latitude: position.latitude,
        longitude: position.longitude,
        settings: settings,
      );
      return raw.withAdjustments(adjustments);
    });
  });
});
