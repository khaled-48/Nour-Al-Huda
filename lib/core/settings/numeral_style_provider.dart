import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import 'numeral_style.dart';

class NumeralStyleNotifier extends StateNotifier<NumeralStyle> {
  NumeralStyleNotifier() : super(NumeralStyle.western) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AppConstants.prefNumeralStyle);
    state = NumeralStyle.values.firstWhere(
      (option) => option.name == saved,
      orElse: () => NumeralStyle.western,
    );
  }

  Future<void> setStyle(NumeralStyle style) async {
    state = style;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefNumeralStyle, style.name);
  }
}

final numeralStyleProvider = StateNotifierProvider<NumeralStyleNotifier, NumeralStyle>((ref) {
  return NumeralStyleNotifier();
});
