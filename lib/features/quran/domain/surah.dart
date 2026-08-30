/// بيانات سورة واحدة من سور القرآن الكريم.
class Surah {
  const Surah({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.translationEn,
    required this.revelationType,
    required this.ayahCount,
  });

  final int id;
  final String nameAr;
  final String nameEn;
  final String translationEn;
  final String revelationType; // Meccan / Medinan
  final int ayahCount;

  bool get isMeccan => revelationType == 'Meccan';

  factory Surah.fromJson(Map<String, Object?> json) => Surah(
        id: json['id']! as int,
        nameAr: json['name_ar']! as String,
        nameEn: json['name_en']! as String,
        translationEn: json['translation_en']! as String,
        revelationType: json['revelation_type']! as String,
        ayahCount: json['ayah_count']! as int,
      );
}
