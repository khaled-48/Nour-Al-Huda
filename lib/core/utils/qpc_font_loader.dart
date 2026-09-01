import 'package:flutter/services.dart' show FontLoader, rootBundle;

import '../constants/app_constants.dart';

/// يُحمِّل خط صفحة مصحف QPC v2 (خط منفصل تماماً لكل صفحة من صفحات المصحف
/// الـ 604) ديناميكياً فقط عند فتح تلك الصفحة، ويتذكّر ما سبق تحميله حتى لا
/// يُعاد تحميل نفس الخط مرتين - تسجيل الـ 604 خطاً مسبقاً ضمن pubspec.yaml
/// كان سيُحمِّلها كلها دفعة واحدة عند إقلاع التطبيق (~200 م.ب في الذاكرة).
class QpcFontLoader {
  QpcFontLoader._();

  static final Set<int> _loadedPages = {};

  static bool isLoaded(int page) => _loadedPages.contains(page);

  static Future<void> ensureLoaded(int page) async {
    if (_loadedPages.contains(page)) return;

    final data = await rootBundle.load(AppConstants.qpcPageFontAssetPath(page));
    final loader = FontLoader(AppConstants.qpcPageFontFamily(page));
    loader.addFont(Future.value(data));
    await loader.load();

    _loadedPages.add(page);
  }
}
