/// موضع بداية جزء واحد من أجزاء القرآن الثلاثين.
class JuzStart {
  const JuzStart({required this.juz, required this.surahId, required this.ayahNumber});

  final int juz;
  final int surahId;
  final int ayahNumber;

  factory JuzStart.fromJson(Map<String, Object?> json) => JuzStart(
        juz: json['juz']! as int,
        surahId: json['surah_id']! as int,
        ayahNumber: json['ayah_number']! as int,
      );
}
