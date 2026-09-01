/// عبارات التسبيح الشائعة التي يمكن عدّها، بالترتيب المعروض في الشاشة.
const List<String> tasbihPhrases = [
  'سبحان الله',
  'الحمد لله',
  'الله أكبر',
  'لا إله إلا الله',
  'أستغفر الله',
];

/// حالة عدّاد التسبيح: العدد الحالي، العبارة المختارة (فهرس ضمن
/// [tasbihPhrases])، والهدف الذي يهتزّ الجهاز بوصوله (33/99/100/مخصّص).
class TasbihState {
  const TasbihState({this.count = 0, this.phraseIndex = 0, this.target = 33});

  final int count;
  final int phraseIndex;
  final int target;

  String get phrase => tasbihPhrases[phraseIndex];

  TasbihState copyWith({int? count, int? phraseIndex, int? target}) {
    return TasbihState(
      count: count ?? this.count,
      phraseIndex: phraseIndex ?? this.phraseIndex,
      target: target ?? this.target,
    );
  }
}
