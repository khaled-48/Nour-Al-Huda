import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/features/tasbih/domain/tasbih_state.dart';

void main() {
  test('القيم الافتراضية: عدّاد صفر، العبارة الأولى، هدف 33', () {
    const state = TasbihState();
    expect(state.count, 0);
    expect(state.phrase, tasbihPhrases[0]);
    expect(state.target, 33);
  });

  test('phrase يعكس phraseIndex الحالي', () {
    const state = TasbihState(phraseIndex: 2);
    expect(state.phrase, tasbihPhrases[2]);
  });

  test('copyWith يغيّر الحقل المحدَّد فقط ويُبقي الباقي', () {
    const state = TasbihState(count: 5, phraseIndex: 1, target: 99);

    final incremented = state.copyWith(count: 6);
    expect(incremented.count, 6);
    expect(incremented.phraseIndex, 1);
    expect(incremented.target, 99);

    final retargeted = state.copyWith(target: 100);
    expect(retargeted.count, 5);
    expect(retargeted.target, 100);
  });
}
