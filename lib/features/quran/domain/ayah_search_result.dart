/// نتيجة بحث واحدة: آية مع اسم سورتها، لعرضها في قائمة نتائج البحث.
class AyahSearchResult {
  const AyahSearchResult({
    required this.surahId,
    required this.surahNameAr,
    required this.ayahNumber,
    required this.textUthmani,
  });

  final int surahId;
  final String surahNameAr;
  final int ayahNumber;
  final String textUthmani;
}
