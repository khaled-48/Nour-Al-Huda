/// كلمة واحدة داخل سطر مصحفي، برمز حرفها الخاص بخط الصفحة (QPC v2) - هذا
/// الرمز لا يُقرأ بصرياً بخط عادي، بل فقط عبر خط تلك الصفحة تحديداً (خط
/// مختلف بالكامل لكل صفحة من صفحات المصحف الـ 604)، وهو ما يجعل موضع كل
/// كلمة وتشكيلها مطابقاً حرفياً لطباعة مجمع الملك فهد. آخر "كلمة" في كل
/// آية هي رمز زخرفة نهاية الآية (الدائرة المزخرفة برقمها) وليست كلمة قرآنية
/// حقيقية - جزء أصيل من تصميم الخط نفسه.
class QpcWord {
  const QpcWord({
    required this.surahId,
    required this.ayahNumber,
    required this.wordIndex,
    required this.text,
  });

  final int surahId;
  final int ayahNumber;
  final int wordIndex;
  final String text;

  factory QpcWord.fromJson(Map<String, Object?> json) => QpcWord(
    surahId: json['surah']! as int,
    ayahNumber: json['ayah']! as int,
    wordIndex: json['word']! as int,
    text: json['text']! as String,
  );
}

/// سطر واحد من أسطر الصفحة الخمسة عشر: إمّا اسم سورة، أو بسملة، أو سطر
/// آيات (قد يمتد عبر أكثر من آية أو حتى أكثر من سورة، تماماً كالمطبوع).
class QpcLine {
  const QpcLine({
    required this.lineNumber,
    required this.type,
    required this.centered,
    required this.surahId,
    required this.words,
  });

  final int lineNumber;

  /// 'surah_name' أو 'basmala' أو 'ayah'.
  final String type;
  final bool centered;

  /// رقم السورة لسطر من نوع 'surah_name' فقط، وإلا فـ null.
  final int? surahId;
  final List<QpcWord> words;

  factory QpcLine.fromJson(Map<String, Object?> json) => QpcLine(
    lineNumber: json['line']! as int,
    type: json['type']! as String,
    centered: json['centered']! as bool,
    surahId: json['surah'] as int?,
    words: (json['words']! as List<Object?>)
        .map((w) => QpcWord.fromJson(w! as Map<String, Object?>))
        .toList(growable: false),
  );
}

class QpcPageLayout {
  const QpcPageLayout({required this.page, required this.lines});

  final int page;
  final List<QpcLine> lines;

  factory QpcPageLayout.fromJson(Map<String, Object?> json) => QpcPageLayout(
    page: json['page']! as int,
    lines: (json['lines']! as List<Object?>)
        .map((l) => QpcLine.fromJson(l! as Map<String, Object?>))
        .toList(growable: false),
  );
}
