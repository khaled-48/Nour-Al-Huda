import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// وضع كشف واجهة التلفاز: تلقائي (يعتمد على `navigationMode` التي يضبطها
/// نظام أندرويد تلفاز/فاير تي في نفسه عند غياب شاشة لمس)، أو فرض التفعيل/
/// التعطيل يدوياً - مفيد لتجربة واجهة التلفاز واختبارها على هاتف عادي دون
/// جهاز تلفاز فعلي متاح.
enum TvModeOverride { auto, forceOn, forceOff }

class TvModeNotifier extends StateNotifier<TvModeOverride> {
  TvModeNotifier() : super(TvModeOverride.auto) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AppConstants.prefTvModeOverride);
    state = TvModeOverride.values.firstWhere(
      (o) => o.name == saved,
      orElse: () => TvModeOverride.auto,
    );
  }

  Future<void> setOverride(TvModeOverride value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefTvModeOverride, value.name);
  }
}

final tvModeOverrideProvider = StateNotifierProvider<TvModeNotifier, TvModeOverride>((ref) {
  return TvModeNotifier();
});

/// يُحدِّد إن كانت الواجهة الحالية يجب أن تُعرض بتصميم التلفاز: إمّا بالفرض
/// اليدوي، أو تلقائياً عبر `MediaQuery.navigationMode` (يضبطها نظام
/// أندرويد تلفاز نفسه إلى [NavigationMode.directional] عند عدم وجود شاشة
/// لمس ووجود ريموت/D-pad فقط).
bool isTvMode(BuildContext context, TvModeOverride override) {
  switch (override) {
    case TvModeOverride.forceOn:
      return true;
    case TvModeOverride.forceOff:
      return false;
    case TvModeOverride.auto:
      return MediaQuery.of(context).navigationMode == NavigationMode.directional;
  }
}
