import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/core/constants/app_constants.dart';
import 'package:islamic_app/features/tasbih/presentation/providers/tasbih_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ينشئ حاوية جديدة ويقرأ tasbihProvider فوراً (فهو كسول ولن يبدأ تحميل
/// الحالة من SharedPreferences إلا عند أول قراءة)، ثم ينتظر اكتمال ذلك
/// التحميل غير المتزامن قبل إعادة الحاوية.
Future<ProviderContainer> _readyContainer() async {
  final container = ProviderContainer();
  container.read(tasbihProvider);
  await Future<void>.delayed(const Duration(milliseconds: 20));
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    container = await _readyContainer();
    addTearDown(container.dispose);
  });

  test('الحالة الأولية بلا بيانات محفوظة: 0 / أول عبارة / هدف 33', () {
    final state = container.read(tasbihProvider);
    expect(state.count, 0);
    expect(state.phraseIndex, 0);
    expect(state.target, 33);
  });

  test('يحمّل قيماً محفوظة سابقاً عند الإقلاع', () async {
    SharedPreferences.setMockInitialValues({
      AppConstants.prefTasbihCount: 7,
      AppConstants.prefTasbihPhraseIndex: 2,
      AppConstants.prefTasbihTarget: 99,
    });
    final freshContainer = await _readyContainer();
    addTearDown(freshContainer.dispose);

    final state = freshContainer.read(tasbihProvider);
    expect(state.count, 7);
    expect(state.phraseIndex, 2);
    expect(state.target, 99);
  });

  test('increment يزيد العدّاد ويحفظه', () async {
    await container.read(tasbihProvider.notifier).increment();
    await container.read(tasbihProvider.notifier).increment();

    expect(container.read(tasbihProvider).count, 2);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(AppConstants.prefTasbihCount), 2);
  });

  test('reset يعيد العدّاد للصفر دون تغيير العبارة أو الهدف', () async {
    final notifier = container.read(tasbihProvider.notifier);
    await notifier.increment();
    await notifier.setPhraseIndex(3);
    await notifier.setTarget(100);

    await notifier.reset();

    final state = container.read(tasbihProvider);
    expect(state.count, 0);
    expect(state.phraseIndex, 3);
    expect(state.target, 100);
  });

  test('setPhraseIndex و setTarget يحفظان القيم الجديدة', () async {
    final notifier = container.read(tasbihProvider.notifier);
    await notifier.setPhraseIndex(4);
    await notifier.setTarget(7);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(AppConstants.prefTasbihPhraseIndex), 4);
    expect(prefs.getInt(AppConstants.prefTasbihTarget), 7);
  });
}
