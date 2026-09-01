import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// تفعيل/تعطيل إشعار دائم يعرض الصلاة القادمة (معطَّل افتراضياً، بخلاف
/// تنبيه الأذان، لأنه أكثر تطفّلاً - يبقى مثبّتاً في شريط الإشعارات دوماً).
class OngoingPrayerNotificationNotifier extends StateNotifier<bool> {
  OngoingPrayerNotificationNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state =
        prefs.getBool(AppConstants.prefOngoingPrayerNotificationEnabled) ??
        false;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      AppConstants.prefOngoingPrayerNotificationEnabled,
      enabled,
    );
  }
}

final ongoingPrayerNotificationEnabledProvider =
    StateNotifierProvider<OngoingPrayerNotificationNotifier, bool>((ref) {
      return OngoingPrayerNotificationNotifier();
    });
