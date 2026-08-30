import 'dart:math' as math;

import 'package:adhan_dart/adhan_dart.dart';

import '../domain/daily_prayer_times.dart';
import '../domain/prayer_calculation_settings.dart';

/// إحداثيات الكعبة المشرّفة (نفس القيمة المعتمدة داخل حزمة adhan_dart
/// لحساب اتجاه القبلة)، لضمان اتساق حساب المسافة مع حساب الزاوية.
const _kaabaLatitude = 21.4225241;
const _kaabaLongitude = 39.8261818;
const _earthRadiusKm = 6371.0;

/// يحسب مواقيت الصلاة فلكياً بشكل محلي بالكامل (دون إنترنت) اعتماداً على
/// حزمة adhan_dart، ويحوّل النتيجة إلى نموذج [DailyPrayerTimes] المستقل عن
/// تفاصيل مكتبة الحساب.
class PrayerTimesRepository {
  const PrayerTimesRepository();

  DailyPrayerTimes calculateForDate({
    required DateTime date,
    required double latitude,
    required double longitude,
    required PrayerCalculationSettings settings,
  }) {
    final params = settings.method.toCalculationParameters()..madhab = settings.madhab;

    final adhanTimes = PrayerTimes(
      date: date,
      coordinates: Coordinates(latitude, longitude),
      calculationParameters: params,
    );

    return DailyPrayerTimes(
      date: date,
      times: {
        PrayerName.fajr: adhanTimes.fajr.toLocal(),
        PrayerName.sunrise: adhanTimes.sunrise.toLocal(),
        PrayerName.dhuhr: adhanTimes.dhuhr.toLocal(),
        PrayerName.asr: adhanTimes.asr.toLocal(),
        PrayerName.maghrib: adhanTimes.maghrib.toLocal(),
        PrayerName.isha: adhanTimes.isha.toLocal(),
      },
      // متوفرتان جاهزتين من adhan_dart، وتُستخدمان لحساب الصلاة/الإقامة
      // الصحيحة بين منتصف الليل وأذان الفجر.
      yesterdayIsha: adhanTimes.ishaBefore.toLocal(),
      tomorrowFajr: adhanTimes.fajrAfter.toLocal(),
    );
  }

  /// اتجاه القبلة بالدرجات من الشمال (لعرضه على بوصلة لاحقاً).
  double qiblaDirection({required double latitude, required double longitude}) {
    return Qibla.qibla(Coordinates(latitude, longitude));
  }

  /// المسافة الفلكية (بخط الدائرة العظمى) بالكيلومترات من موقع المستخدم
  /// إلى الكعبة المشرّفة، محسوبة محلياً بمعادلة Haversine دون إنترنت.
  double distanceToMeccaKm({required double latitude, required double longitude}) {
    final lat1 = latitude * math.pi / 180;
    final lat2 = _kaabaLatitude * math.pi / 180;
    final deltaLat = (_kaabaLatitude - latitude) * math.pi / 180;
    final deltaLng = (_kaabaLongitude - longitude) * math.pi / 180;

    final a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(deltaLng / 2) * math.sin(deltaLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _earthRadiusKm * c;
  }
}
