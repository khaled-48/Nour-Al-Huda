import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/quran_repository.dart';
import '../../domain/ayah.dart';
import '../../domain/quran_search_results.dart';
import '../../domain/surah.dart';

final quranRepositoryProvider = Provider<QuranRepository>((ref) => QuranRepository());

final surahListProvider = FutureProvider<List<Surah>>((ref) {
  return ref.watch(quranRepositoryProvider).getAllSurahs();
});

final ayahsForSurahProvider = FutureProvider.family<List<Ayah>, int>((ref, surahId) {
  return ref.watch(quranRepositoryProvider).getAyahsForSurah(surahId);
});

/// تفسير سورة كاملة كخريطة (رقم الآية -> النص)، تُحمَّل دفعة واحدة عند
/// فتح السورة بدلاً من طلب مستقل لكل آية.
final tafsirForSurahProvider = FutureProvider.family<Map<int, String>, int>((ref, surahId) {
  return ref.watch(quranRepositoryProvider).getTafsirForSurah(surahId);
});

/// النص الحالي في مربّع البحث القرآني.
final quranSearchQueryProvider = StateProvider<String>((ref) => '');

final quranSearchResultsProvider = FutureProvider<QuranSearchResults>((ref) {
  final query = ref.watch(quranSearchQueryProvider);
  if (query.trim().isEmpty) return Future.value(QuranSearchResults.empty);
  return ref.watch(quranRepositoryProvider).searchAll(query);
});
