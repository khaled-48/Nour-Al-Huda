import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/location_service.dart';

final _locationServiceProvider = Provider((ref) => const LocationService());

/// موقع المستخدم الحالي. يُعاد تحميله عند استدعاء [refresh] (مثلاً من زر
/// "إعادة المحاولة" في الواجهة عند رفض الإذن).
class LocationNotifier extends AsyncNotifier<Position> {
  @override
  Future<Position> build() {
    return ref.read(_locationServiceProvider).getCurrentCoordinates();
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
