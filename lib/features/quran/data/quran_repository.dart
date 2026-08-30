import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/arabic_normalizer.dart';
import '../domain/ayah.dart';
import '../domain/ayah_search_result.dart';
import '../domain/juz_start.dart';
import '../domain/quran_search_results.dart';
import '../domain/surah.dart';

/// كل الوصول لبيانات القرآن الكريم (نص + تفسير ميسر) يمرّ من هنا. البيانات
/// ملفات JSON محلية مرفقة ضمن الـ assets ولا شيء غيرها — لا قاعدة بيانات
/// ولا حزمة خارجية ولا أي اتصال بالإنترنت.
///
/// كل ملف يُقرأ مرة واحدة فقط ويُخزَّن في الذاكرة (Cache) لبقية الجلسة:
/// - `surahs.json` (فهرس السور، صغير) يُحمَّل عند أول طلب لقائمة السور.
/// - `ayahs/<رقم السورة>.json` و `tafsir/<رقم السورة>.json` يُحمَّلان فقط
///   عند فتح تلك السورة تحديداً (تحميل كسول)، فلا يُقرأ القرآن كله دفعة واحدة.
/// - `search_index.json` (نسخة مسطّحة لكل الآيات لأغراض البحث فقط) يُحمَّل
///   مرة واحدة عند أول عملية بحث.
class QuranRepository {
  QuranRepository();

  List<Surah>? _surahsCache;
  final Map<int, List<Ayah>> _ayahsCache = {};
  final Map<int, Map<int, String>> _tafsirCache = {};
  List<(String searchText, AyahSearchResult result)>? _searchIndexCache;
  List<JuzStart>? _juzIndexCache;

  Future<List<Surah>> getAllSurahs() async {
    final cached = _surahsCache;
    if (cached != null) return cached;

    final raw = await rootBundle.loadString(AppConstants.quranSurahsAssetPath);
    final surahs = (jsonDecode(raw) as List<Object?>)
        .map((e) => Surah.fromJson(e! as Map<String, Object?>))
        .toList(growable: false);

    _surahsCache = surahs;
    return surahs;
  }

  Future<List<Ayah>> getAyahsForSurah(int surahId) async {
    final cached = _ayahsCache[surahId];
    if (cached != null) return cached;

    final raw = await rootBundle.loadString(AppConstants.quranAyahsAssetPath(surahId));
    final json = jsonDecode(raw) as Map<String, Object?>;
    final ayahs = (json['ayahs']! as List<Object?>)
        .map((e) => Ayah.fromJson(surahId, e! as Map<String, Object?>))
        .toList(growable: false);

    _ayahsCache[surahId] = ayahs;
    return ayahs;
  }

  /// تفسير سورة كاملة، كخريطة (رقم الآية -> نص التفسير)، حتى تُحمَّل السورة
  /// دفعة واحدة عند فتحها بدلاً من قراءة ملف مستقل لكل آية على حدة.
  Future<Map<int, String>> getTafsirForSurah(int surahId) async {
    final cached = _tafsirCache[surahId];
    if (cached != null) return cached;

    final raw = await rootBundle.loadString(AppConstants.quranTafsirAssetPath(surahId));
    final json = jsonDecode(raw) as Map<String, Object?>;
    final map = <int, String>{
      for (final entry in (json['tafsir']! as List<Object?>).cast<Map<String, Object?>>())
        entry['ayah_number']! as int: entry['text']! as String,
    };

    _tafsirCache[surahId] = map;
    return map;
  }

  Future<List<AyahSearchResult>> search(String query) async {
    final normalized = normalizeArabic(query);
    if (normalized.isEmpty) return const [];

    final index = await _loadSearchIndex();
    return index
        .where((entry) => entry.$1.contains(normalized))
        .map((entry) => entry.$2)
        .take(200)
        .toList(growable: false);
  }

  Future<List<JuzStart>> getJuzIndex() async {
    final cached = _juzIndexCache;
    if (cached != null) return cached;

    final raw = await rootBundle.loadString(AppConstants.quranJuzIndexAssetPath);
    final list = (jsonDecode(raw) as List<Object?>)
        .map((e) => JuzStart.fromJson(e! as Map<String, Object?>))
        .toList(growable: false);

    _juzIndexCache = list;
    return list;
  }

  /// بحث شامل منظّم: يطابق اسم السورة أو رقمها، رقم الجزء (1-30)، ونص
  /// الآيات معاً، ويعيد كل فئة منفصلة عن الأخرى بدل قائمة واحدة مبهمة.
  Future<QuranSearchResults> searchAll(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return QuranSearchResults.empty;

    final asNumber = int.tryParse(trimmed);
    final normalizedQuery = normalizeArabic(trimmed);

    final surahs = await getAllSurahs();
    final matchedSurahs = surahs
        .where(
          (s) =>
              (normalizedQuery.isNotEmpty && normalizeArabic(s.nameAr).contains(normalizedQuery)) ||
              (asNumber != null && asNumber == s.id),
        )
        .toList(growable: false);

    var juzMatches = const <JuzStart>[];
    if (asNumber != null && asNumber >= 1 && asNumber <= 30) {
      final juzIndex = await getJuzIndex();
      juzMatches = juzIndex.where((j) => j.juz == asNumber).toList(growable: false);
    }

    final ayahs = await search(trimmed);

    return QuranSearchResults(surahs: matchedSurahs, juzMatches: juzMatches, ayahs: ayahs);
  }

  Future<List<(String, AyahSearchResult)>> _loadSearchIndex() async {
    final cached = _searchIndexCache;
    if (cached != null) return cached;

    final raw = await rootBundle.loadString(AppConstants.quranSearchIndexAssetPath);
    final entries = (jsonDecode(raw) as List<Object?>).map((e) {
      final map = e! as Map<String, Object?>;
      final result = AyahSearchResult(
        surahId: map['surah_id']! as int,
        surahNameAr: map['surah_name_ar']! as String,
        ayahNumber: map['ayah_number']! as int,
        textUthmani: map['text_uthmani']! as String,
      );
      return (map['text_search']! as String, result);
    }).toList(growable: false);

    _searchIndexCache = entries;
    return entries;
  }
}
