import 'ayah_search_result.dart';
import 'juz_start.dart';
import 'surah.dart';

/// نتائج بحث منظّمة في ثلاث فئات واضحة: سور مطابقة بالاسم أو الرقم،
/// أجزاء مطابقة بالرقم، وآيات مطابقة نصياً — بدل قائمة واحدة مبهمة.
class QuranSearchResults {
  const QuranSearchResults({
    required this.surahs,
    required this.juzMatches,
    required this.ayahs,
  });

  final List<Surah> surahs;
  final List<JuzStart> juzMatches;
  final List<AyahSearchResult> ayahs;

  static const empty = QuranSearchResults(surahs: [], juzMatches: [], ayahs: []);

  bool get isEmpty => surahs.isEmpty && juzMatches.isEmpty && ayahs.isEmpty;
}
