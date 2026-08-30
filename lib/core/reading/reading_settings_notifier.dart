import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'reading_settings.dart';

/// يدير إعدادات قراءة شاشة واحدة ويحفظها محلياً. يُنشأ لكل شاشة قراءة
/// بمفتاح تخزين خاص بها (`prefKeyPrefix`) حتى تبقى تفضيلات القرآن مستقلة
/// عن تفضيلات الأذكار مثلاً، مع مشاركة نفس منطق الحفظ والاسترجاع.
class ReadingSettingsNotifier extends StateNotifier<ReadingSettings> {
  ReadingSettingsNotifier(this._prefKeyPrefix) : super(ReadingSettings.lightDefaults) {
    _load();
  }

  final String _prefKeyPrefix;

  String get _bgKey => '${_prefKeyPrefix}_bg_color';
  String get _textKey => '${_prefKeyPrefix}_text_color';
  String get _scaleKey => '${_prefKeyPrefix}_font_scale';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final bg = prefs.getInt(_bgKey);
    final text = prefs.getInt(_textKey);
    final scale = prefs.getDouble(_scaleKey);

    // الألوان مخصّصة فقط إن حفظ المستخدم كليهما صراحةً؛ غير ذلك تبقى
    // الحالة غير مخصّصة (isCustom: false) فتُحلّ لاحقاً حسب سطوع الثيم
    // الفعلي وقت العرض عبر resolveFor بدل تجميد لون فاتح دائماً.
    if (bg != null && text != null) {
      state = ReadingSettings(
        backgroundColor: Color(bg),
        textColor: Color(text),
        fontScale: scale ?? state.fontScale,
        isCustom: true,
      );
    } else if (scale != null) {
      state = state.copyWith(fontScale: scale);
    }
  }

  /// يضبط لونَي الخلفية والنص معاً (وليس أحدهما فقط) حتى لو غيّر المستخدم
  /// واحداً منهما فقط — لأن `isCustom` علم واحد يغطي الاثنين معاً؛ يمرّر
  /// المستدعي القيمة المُحلَّلة (resolveFor) الحالية للطرف غير المتغيّر
  /// حتى لا يُحفَظ لون افتراضي غير مناسب لسطوع الثيم وقت الحفظ.
  Future<void> setColors({required Color background, required Color text}) async {
    state = state.copyWith(backgroundColor: background, textColor: text, isCustom: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_bgKey, background.toARGB32());
    await prefs.setInt(_textKey, text.toARGB32());
  }

  Future<void> setFontScale(double scale) async {
    final clamped = scale.clamp(ReadingSettings.minFontScale, ReadingSettings.maxFontScale);
    state = state.copyWith(fontScale: clamped);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_scaleKey, clamped);
  }

  Future<void> applyPreset({required Color background, required Color text}) async {
    state = state.copyWith(backgroundColor: background, textColor: text, isCustom: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_bgKey, background.toARGB32());
    await prefs.setInt(_textKey, text.toARGB32());
  }

  Future<void> resetToDefaults() async {
    state = ReadingSettings.lightDefaults;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_bgKey);
    await prefs.remove(_textKey);
    await prefs.remove(_scaleKey);
  }
}
