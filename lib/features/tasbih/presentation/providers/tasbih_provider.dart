import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/tasbih_state.dart';

/// عدّاد التسبيح: مستقل عن أي نص محدَّد، محفوظ محلياً حتى لا يُفقَد التقدّم
/// عند إغلاق التطبيق. زيادة العدّاد وحدها لا تُعيد قراءة كل الحالة، بل تكتب
/// المفتاح المتغيّر فقط.
class TasbihNotifier extends StateNotifier<TasbihState> {
  TasbihNotifier() : super(const TasbihState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = TasbihState(
      count: prefs.getInt(AppConstants.prefTasbihCount) ?? 0,
      phraseIndex: prefs.getInt(AppConstants.prefTasbihPhraseIndex) ?? 0,
      target: prefs.getInt(AppConstants.prefTasbihTarget) ?? 33,
    );
  }

  Future<void> increment() async {
    state = state.copyWith(count: state.count + 1);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.prefTasbihCount, state.count);
  }

  Future<void> reset() async {
    state = state.copyWith(count: 0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.prefTasbihCount, 0);
  }

  Future<void> setPhraseIndex(int index) async {
    state = state.copyWith(phraseIndex: index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.prefTasbihPhraseIndex, index);
  }

  Future<void> setTarget(int target) async {
    state = state.copyWith(target: target);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.prefTasbihTarget, target);
  }
}

final tasbihProvider = StateNotifierProvider<TasbihNotifier, TasbihState>((ref) {
  return TasbihNotifier();
});
