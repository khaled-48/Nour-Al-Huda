import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/daily_prayer_times.dart';
import '../../domain/prayer_calculation_settings.dart';

/// يدير إعدادات حساب مواقيت الصلاة (طريقة الحساب + المذهب) ويحفظها محلياً.
class PrayerSettingsNotifier extends StateNotifier<PrayerCalculationSettings> {
  PrayerSettingsNotifier() : super(const PrayerCalculationSettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final methodName = prefs.getString(AppConstants.prefCalculationMethod);
    final madhabName = prefs.getString(AppConstants.prefMadhab);

    final method = PrayerCalculationMethodOption.values.firstWhere(
      (m) => m.name == methodName,
      orElse: () => PrayerCalculationMethodOption.ummAlQura,
    );
    final madhab = Madhab.values.firstWhere(
      (m) => m.name == madhabName,
      orElse: () => Madhab.shafi,
    );

    state = PrayerCalculationSettings(method: method, madhab: madhab);
  }

  Future<void> setMethod(PrayerCalculationMethodOption method) async {
    state = state.copyWith(method: method);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefCalculationMethod, method.name);
  }

  Future<void> setMadhab(Madhab madhab) async {
    state = state.copyWith(madhab: madhab);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefMadhab, madhab.name);
  }
}

final prayerSettingsProvider =
    StateNotifierProvider<PrayerSettingsNotifier, PrayerCalculationSettings>((ref) {
  return PrayerSettingsNotifier();
});

/// مدد الإقامة بعد كل أذان (بالدقائق)، قابلة للتخصيص لكل صلاة على حدة.
class IqamahOffsetsNotifier extends StateNotifier<Map<PrayerName, int>> {
  IqamahOffsetsNotifier()
      : super({
          PrayerName.fajr: AppConstants.defaultIqamahOffsets['fajr']!,
          PrayerName.dhuhr: AppConstants.defaultIqamahOffsets['dhuhr']!,
          PrayerName.asr: AppConstants.defaultIqamahOffsets['asr']!,
          PrayerName.maghrib: AppConstants.defaultIqamahOffsets['maghrib']!,
          PrayerName.isha: AppConstants.defaultIqamahOffsets['isha']!,
        }) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final updated = {...state};
    for (final prayer in state.keys) {
      final saved = prefs.getInt('${AppConstants.prefIqamahOffsetPrefix}${prayer.name}');
      if (saved != null) updated[prayer] = saved;
    }
    state = updated;
  }

  Future<void> setOffset(PrayerName prayer, int minutes) async {
    state = {...state, prayer: minutes};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${AppConstants.prefIqamahOffsetPrefix}${prayer.name}', minutes);
  }
}

final iqamahOffsetsProvider =
    StateNotifierProvider<IqamahOffsetsNotifier, Map<PrayerName, int>>((ref) {
  return IqamahOffsetsNotifier();
});

/// تعديل يدوي (بالدقائق، موجب أو سالب) فوق وقت كل صلاة المحسوب فلكياً،
/// لمعايرة دقيقة حسب رؤية المستخدم المحلية.
class PrayerAdjustmentsNotifier extends StateNotifier<Map<PrayerName, int>> {
  PrayerAdjustmentsNotifier() : super({for (final p in PrayerName.values) p: 0}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final updated = {...state};
    for (final prayer in state.keys) {
      final saved = prefs.getInt('${AppConstants.prefPrayerAdjustmentPrefix}${prayer.name}');
      if (saved != null) updated[prayer] = saved;
    }
    state = updated;
  }

  Future<void> setAdjustment(PrayerName prayer, int minutes) async {
    state = {...state, prayer: minutes};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${AppConstants.prefPrayerAdjustmentPrefix}${prayer.name}', minutes);
  }
}

final prayerAdjustmentsProvider =
    StateNotifierProvider<PrayerAdjustmentsNotifier, Map<PrayerName, int>>((ref) {
  return PrayerAdjustmentsNotifier();
});
