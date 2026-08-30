import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../../core/constants/app_constants.dart';
import '../domain/azkar_category.dart';

/// يحمّل مكتبة الأذكار والأدعية (حصن المسلم) من ملف JSON مرفق محلياً ضمن
/// الـ assets، فلا حاجة لأي إنترنت.
///
/// الملف مبني كخريطة بيانات (Map) حقيقية — `{"categories": {"1": {...},
/// "2": {...}}}` — وليس مصفوفة، فمعرّف كل باب مفتاح فريد في JSON نفسه؛
/// هذا يمنع بنيوياً أي تكرار لمعرّف باب عند بناء الملف، بعكس مصفوفة قد
/// تحتوي عنصرين بنفس المعرّف دون أن يشتكي أي شيء.
class AzkarRepository {
  const AzkarRepository();

  Future<Map<int, AzkarCategory>> getAllCategories() async {
    final raw = await rootBundle.loadString(AppConstants.azkarAssetPath);
    final json = jsonDecode(raw) as Map<String, Object?>;
    final categoriesJson = json['categories']! as Map<String, Object?>;

    final result = <int, AzkarCategory>{};
    for (final entry in categoriesJson.entries) {
      final id = int.parse(entry.key);
      result[id] = AzkarCategory.fromJson(id, entry.value! as Map<String, Object?>);
    }
    return result;
  }
}
