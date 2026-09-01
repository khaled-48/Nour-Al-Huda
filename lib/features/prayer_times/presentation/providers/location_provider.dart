import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/location_service.dart';

final _locationServiceProvider = Provider((ref) => const LocationService());

/// موقع المستخدم الحالي. يُعاد تحميله عند استدعاء [refresh] (مثلاً من زر
/// "إعادة المحاولة" في الواجهة عند رفض الإذن).
class LocationNotifier extends AsyncNotifier<Position> {
  @override
  Future<Position> build() async {
    final service = ref.read(_locationServiceProvider);
    final cached = await service.getCachedCoordinatesOrNull();
    if (cached != null) {
      // نعرض آخر موقع معروف فوراً بلا انتظار تحديد GPS دقيق (قد يستغرق
      // ثوانٍ)، ثم نحدّثه بصمت في الخلفية بلا حجب الواجهة بمؤشر تحميل.
      unawaited(_refreshSilently());
      return cached;
    }
    return service.getCurrentCoordinates();
  }

  Future<void> _refreshSilently() async {
    try {
      final fresh = await ref.read(_locationServiceProvider).getCurrentCoordinates();
      state = AsyncValue.data(fresh);
    } catch (_) {
      // نتجاهل الخطأ بصمت: الموقع المخزَّن مؤقتاً يبقى معروضاً وصالحاً.
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(_locationServiceProvider).getCurrentCoordinates(),
    );
  }
}

final locationProvider = AsyncNotifierProvider<LocationNotifier, Position>(
  LocationNotifier.new,
);
