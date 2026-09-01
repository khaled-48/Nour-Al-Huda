import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/features/prayer_times/data/prayer_times_repository.dart';
import 'package:islamic_app/features/prayer_times/domain/daily_prayer_times.dart';
import 'package:islamic_app/features/prayer_times/domain/prayer_calculation_settings.dart';

void main() {
  const repository = PrayerTimesRepository();

  group('calculateForDate', () {
    test('يُرتّب أوقات الصلاة زمنياً: الفجر < الشروق < الظهر < العصر < المغرب < العشاء', () {
      final result = repository.calculateForDate(
        date: DateTime(2026, 6, 15),
        latitude: 21.4225, // مكة المكرمة
        longitude: 39.8262,
        settings: const PrayerCalculationSettings(),
      );

      final fajr = result.timeOf(PrayerName.fajr);
      final sunrise = result.timeOf(PrayerName.sunrise);
      final dhuhr = result.timeOf(PrayerName.dhuhr);
      final asr = result.timeOf(PrayerName.asr);
      final maghrib = result.timeOf(PrayerName.maghrib);
      final isha = result.timeOf(PrayerName.isha);

      expect(fajr.isBefore(sunrise), isTrue);
      expect(sunrise.isBefore(dhuhr), isTrue);
      expect(dhuhr.isBefore(asr), isTrue);
      expect(asr.isBefore(maghrib), isTrue);
      expect(maghrib.isBefore(isha), isTrue);
    });

    test('عشاء الأمس قبل فجر اليوم، وفجر الغد بعد عشاء اليوم', () {
      final result = repository.calculateForDate(
        date: DateTime(2026, 6, 15),
        latitude: 21.4225,
        longitude: 39.8262,
        settings: const PrayerCalculationSettings(),
      );

      expect(
        result.yesterdayIsha.isBefore(result.timeOf(PrayerName.fajr)),
        isTrue,
      );
      expect(
        result.tomorrowFajr.isAfter(result.timeOf(PrayerName.isha)),
        isTrue,
      );
    });
  });

  group('distanceToMeccaKm', () {
    test('المسافة من الكعبة نفسها تقارب الصفر', () {
      final distance = repository.distanceToMeccaKm(
        latitude: 21.4225241,
        longitude: 39.8261818,
      );
      expect(distance, closeTo(0, 0.01));
    });

    test('المسافة من الرياض معقولة (بضع مئات من الكيلومترات)', () {
      final distance = repository.distanceToMeccaKm(
        latitude: 24.7136,
        longitude: 46.6753,
      );
      expect(distance, greaterThan(700));
      expect(distance, lessThan(950));
    });
  });

  group('qiblaDirection', () {
    test('يُعيد زاوية ضمن المدى الصحيح [0, 360)', () {
      final direction = repository.qiblaDirection(
        latitude: 24.7136,
        longitude: 46.6753,
      );
      expect(direction, greaterThanOrEqualTo(0));
      expect(direction, lessThan(360));
    });
  });
}
