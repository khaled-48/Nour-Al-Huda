import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/quran_repository.dart';
import '../../domain/ayah.dart';
import '../../domain/mushaf_page_index.dart';
import '../../domain/qpc_page_layout.dart';
import '../../domain/quran_search_results.dart';
import '../../domain/surah.dart';

final quranRepositoryProvider = Provider<QuranRepository>(
  (ref) => QuranRepository(),
);

final surahListProvider = FutureProvider<List<Surah>>((ref) {
  return ref.watch(quranRepositoryProvider).getAllSurahs();
});

final ayahsForSurahProvider = FutureProvider.family<List<Ayah>, int>((
  ref,
  surahId,
) {
  return ref.watch(quranRepositoryProvider).getAyahsForSurah(surahId);
});

/// تفسير سورة كاملة كخريطة (رقم الآية -> النص)، تُحمَّل دفعة واحدة عند
/// فتح السورة بدلاً من طلب مستقل لكل آية.
final tafsirForSurahProvider = FutureProvider.family<Map<int, String>, int>((
  ref,
  surahId,
) {
  return ref.watch(quranRepositoryProvider).getTafsirForSurah(surahId);
});

/// فهرس صفحات مصحف المدينة المطبعي القياسي الـ 604 (صغير، يُحمَّل مرّة
/// واحدة ويبقى في الذاكرة).
final pageIndexProvider = FutureProvider<List<MushafPageIndexEntry>>((ref) {
  return ref.watch(quranRepositoryProvider).getPageIndex();
});

/// آيات صفحة مصحف واحدة (1-604)، بالترتيب - قد تمتد عبر أكثر من سورة.
final ayahsForPageProvider = FutureProvider.family<List<Ayah>, int>((
  ref,
  page,
) {
  return ref.watch(quranRepositoryProvider).getAyahsForPage(page);
});

/// تخطيط صفحة مصحف واحدة (1-604) مطابق حرفياً لطباعة مجمع الملك فهد (QPC v2).
final qpcPageLayoutProvider = FutureProvider.family<QpcPageLayout, int>((
  ref,
  page,
) {
  return ref.watch(quranRepositoryProvider).getQpcPageLayout(page);
});

/// النص الحالي في مربّع البحث القرآني.
final quranSearchQueryProvider = StateProvider<String>((ref) => '');

final quranSearchResultsProvider = FutureProvider<QuranSearchResults>((ref) {
  final query = ref.watch(quranSearchQueryProvider);
  if (query.trim().isEmpty) return Future.value(QuranSearchResults.empty);
  return ref.watch(quranRepositoryProvider).searchAll(query);
});
