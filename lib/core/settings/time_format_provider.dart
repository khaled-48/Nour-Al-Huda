import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import 'time_format_option.dart';

class TimeFormatNotifier extends StateNotifier<TimeFormatOption> {
  TimeFormatNotifier() : super(TimeFormatOption.h12) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AppConstants.prefTimeFormat);
    state = TimeFormatOption.values.firstWhere(
      (option) => option.name == saved,
      orElse: () => TimeFormatOption.h12,
    );
  }

  Future<void> setFormat(TimeFormatOption format) async {
    state = format;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefTimeFormat, format.name);
  }
}

final timeFormatProvider = StateNotifierProvider<TimeFormatNotifier, TimeFormatOption>((ref) {
  return TimeFormatNotifier();
});
