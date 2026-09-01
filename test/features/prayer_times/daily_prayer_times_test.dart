import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/features/prayer_times/domain/daily_prayer_times.dart';

DailyPrayerTimes _sample() {
  final date = DateTime(2026, 1, 1);
  return DailyPrayerTimes(
    date: date,
    times: {
      PrayerName.fajr: DateTime(2026, 1, 1, 5, 0),
      PrayerName.sunrise: DateTime(2026, 1, 1, 6, 20),
      PrayerName.dhuhr: DateTime(2026, 1, 1, 12, 0),
      PrayerName.asr: DateTime(2026, 1, 1, 15, 0),
      PrayerName.maghrib: DateTime(2026, 1, 1, 17, 40),
      PrayerName.isha: DateTime(2026, 1, 1, 19, 0),
    },
    yesterdayIsha: DateTime(2025, 12, 31, 19, 0),
    tomorrowFajr: DateTime(2026, 1, 2, 5, 0),
  );
}

void main() {
  test('الشروق فقط بلا إقامة، وباقي الصلوات لها إقامة', () {
    expect(PrayerName.sunrise.hasIqamah, isFalse);
    for (final p in PrayerName.values.where((p) => p != PrayerName.sunrise)) {
      expect(p.hasIqamah, isTrue, reason: p.name);
    }
  });

  group('nextPrayer', () {
    test('قبل الفجر: الصلاة القادمة هي فجر اليوم', () {
      final times = _sample();
      final (name, time) = times.nextPrayer(DateTime(2026, 1, 1, 4, 0));
      expect(name, PrayerName.fajr);
      expect(time, DateTime(2026, 1, 1, 5, 0));
    });

    test('بين الفجر والشروق: الصلاة القادمة هي الشروق', () {
      final times = _sample();
      final (name, _) = times.nextPrayer(DateTime(2026, 1, 1, 5, 30));
      expect(name, PrayerName.sunrise);
    });

    test('بعد العشاء: الصلاة القادمة هي فجر الغد', () {
      final times = _sample();
      final (name, time) = times.nextPrayer(DateTime(2026, 1, 1, 20, 0));
      expect(name, PrayerName.fajr);
      expect(time, DateTime(2026, 1, 2, 5, 0));
    });
  });

  group('currentPrayer', () {
    test('قبل فجر اليوم: الصلاة الحالية هي عشاء الأمس', () {
      final times = _sample();
      final (name, time) = times.currentPrayer(DateTime(2026, 1, 1, 4, 0));
      expect(name, PrayerName.isha);
      expect(time, DateTime(2025, 12, 31, 19, 0));
    });

    test('بعد الفجر مباشرة: الصلاة الحالية هي فجر اليوم', () {
      final times = _sample();
      final (name, time) = times.currentPrayer(DateTime(2026, 1, 1, 5, 30));
      expect(name, PrayerName.fajr);
      expect(time, DateTime(2026, 1, 1, 5, 0));
    });

    test('بين الشروق والظهر: الصلاة الحالية تبقى الفجر، لا الشروق', () {
      final times = _sample();
      final (name, time) = times.currentPrayer(DateTime(2026, 1, 1, 9, 0));
      expect(name, PrayerName.fajr);
      expect(time, DateTime(2026, 1, 1, 5, 0));
    });

    test('بعد عشاء اليوم: الصلاة الحالية هي عشاء اليوم نفسه', () {
      final times = _sample();
      final (name, time) = times.currentPrayer(DateTime(2026, 1, 1, 20, 0));
      expect(name, PrayerName.isha);
      expect(time, DateTime(2026, 1, 1, 19, 0));
    });
  });

  group('withAdjustments', () {
    test('يضيف الدقائق للصلاة المحدَّدة فقط ويترك البقية كما هي', () {
      final adjusted = _sample().withAdjustments({
        PrayerName.fajr: 5,
        PrayerName.isha: -10,
      });

      expect(adjusted.timeOf(PrayerName.fajr), DateTime(2026, 1, 1, 5, 5));
      expect(adjusted.timeOf(PrayerName.dhuhr), DateTime(2026, 1, 1, 12, 0));
      expect(adjusted.timeOf(PrayerName.isha), DateTime(2026, 1, 1, 18, 50));
    });

    test('يطبّق نفس تعديل العشاء/الفجر على عشاء الأمس وفجر الغد', () {
      final adjusted = _sample().withAdjustments({
        PrayerName.fajr: 5,
        PrayerName.isha: -10,
      });

      expect(adjusted.yesterdayIsha, DateTime(2025, 12, 31, 18, 50));
      expect(adjusted.tomorrowFajr, DateTime(2026, 1, 2, 5, 5));
    });
  });
}
