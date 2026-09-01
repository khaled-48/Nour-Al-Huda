/// نطاق آيات متتالية من سورة واحدة ضمن صفحة مصحف واحدة (الصفحة الواحدة قد
/// تحوي أكثر من نطاق إذا بدأت سورة جديدة وسطها).
class PageAyahRange {
  const PageAyahRange({
    required this.surahId,
    required this.fromAyah,
    required this.toAyah,
  });

  final int surahId;
  final int fromAyah;
  final int toAyah;

  factory PageAyahRange.fromJson(Map<String, Object?> json) => PageAyahRange(
        surahId: json['surah_id']! as int,
        fromAyah: json['from_ayah']! as int,
        toAyah: json['to_ayah']! as int,
      );
}

/// مدخل فهرس صفحة واحدة من صفحات مصحف المدينة المطبعي القياسي الـ 604:
/// رقم الجزء الذي تبدأ به الصفحة، ونطاقات الآيات (من سورة واحدة أو أكثر
/// إذا بدأت سورة جديدة وسط الصفحة) التي تُشكِّل محتواها بالترتيب.
class MushafPageIndexEntry {
  const MushafPageIndexEntry({
    required this.page,
    required this.juz,
    required this.ranges,
  });

  final int page;
  final int juz;
  final List<PageAyahRange> ranges;

  factory MushafPageIndexEntry.fromJson(Map<String, Object?> json) =>
      MushafPageIndexEntry(
        page: json['page']! as int,
        juz: json['juz']! as int,
        ranges: (json['ranges']! as List<Object?>)
            .map((e) => PageAyahRange.fromJson(e! as Map<String, Object?>))
            .toList(growable: false),
      );
}
