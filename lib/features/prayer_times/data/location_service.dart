import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';

/// استثناء يوضّح للواجهة سبب تعذّر الحصول على الموقع حتى تعرض رسالة مناسبة.
class LocationFailure implements Exception {
  const LocationFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// يوفّر إحداثيات المستخدم (خط العرض/الطول) اللازمة لحساب مواقيت الصلاة.
/// يعمل بالكامل محلياً عبر GPS/الشبكة على الجهاز، ويحفظ آخر إحداثيات معروفة
/// في SharedPreferences لاستخدامها كنسخة احتياطية عند تعذّر تحديد الموقع.
class LocationService {
  const LocationService();

  /// آخر إحداثيات محفوظة محلياً بلا أي استدعاء لـ GPS، أو null إن لم يسبق
  /// تحديد الموقع من قبل على هذا الجهاز.
  Future<Position?> getCachedCoordinatesOrNull() => _cachedPosition();

  Future<Position> getCurrentCoordinates() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      final cached = await _cachedPosition();
      if (cached != null) return cached;
      throw const LocationFailure('خدمة الموقع غير مفعّلة على الجهاز. يرجى تفعيلها من الإعدادات.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      final cached = await _cachedPosition();
      if (cached != null) return cached;
      throw const LocationFailure('تم رفض إذن الوصول إلى الموقع، وهو ضروري لحساب مواقيت الصلاة.');
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      await _cachePosition(position);
      return position;
    } catch (_) {
      final cached = await _cachedPosition();
      if (cached != null) return cached;
      throw const LocationFailure('تعذّر تحديد الموقع الحالي. تأكد من تفعيل GPS وحاول مجدداً.');
    }
  }

  Future<void> _cachePosition(Position position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppConstants.prefLastLatitude, position.latitude);
    await prefs.setDouble(AppConstants.prefLastLongitude, position.longitude);
  }

  Future<Position?> _cachedPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(AppConstants.prefLastLatitude);
    final lng = prefs.getDouble(AppConstants.prefLastLongitude);
    if (lat == null || lng == null) return null;
    return Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}
