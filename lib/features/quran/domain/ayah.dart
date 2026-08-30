/// آية واحدة برسمها العثماني ضمن سورتها، مع موضعها في الجزء والصفحة.
/// (رقم السورة + رقم الآية) هو المعرّف الطبيعي لها؛ لا حاجة لمعرّف عام.
class Ayah {
  const Ayah({
    required this.surahId,
    required this.ayahNumber,
    required this.textUthmani,
    required this.juz,
    required this.page,
  });

  final int surahId;
  final int ayahNumber;
  final String textUthmani;
  final int juz;
  final int page;

  factory Ayah.fromJson(int surahId, Map<String, Object?> json) => Ayah(
        surahId: surahId,
        ayahNumber: json['ayah_number']! as int,
        textUthmani: json['text_uthmani']! as String,
        juz: json['juz']! as int,
        page: json['page']! as int,
      );
}
