/// علامة مرجعية على آية معيّنة، ليتابع المستخدم القراءة من حيث توقف.
class QuranBookmark {
  const QuranBookmark({required this.surahId, required this.ayahNumber, required this.surahNameAr});

  final int surahId;
  final int ayahNumber;
  final String surahNameAr;

  Map<String, Object?> toJson() => {
        'surah_id': surahId,
        'ayah_number': ayahNumber,
        'surah_name_ar': surahNameAr,
      };

  factory QuranBookmark.fromJson(Map<String, Object?> json) => QuranBookmark(
        surahId: json['surah_id']! as int,
        ayahNumber: json['ayah_number']! as int,
        surahNameAr: json['surah_name_ar']! as String,
      );
}
