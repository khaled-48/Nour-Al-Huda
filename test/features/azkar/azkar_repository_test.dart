import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/features/azkar/data/azkar_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const repository = AzkarRepository();

  test('يحمّل كل أبواب الأذكار بمعرّفات مطابقة لمفاتيحها', () async {
    final categories = await repository.getAllCategories();

    expect(categories, isNotEmpty);
    for (final entry in categories.entries) {
      expect(entry.value.id, entry.key);
    }
  });

  test('كل باب يحتوي عنواناً وعنصراً واحداً على الأقل', () async {
    final categories = await repository.getAllCategories();

    for (final category in categories.values) {
      expect(category.title, isNotEmpty);
      expect(category.items, isNotEmpty);
    }
  });

  test('الباب الأول هو المقدمة', () async {
    final categories = await repository.getAllCategories();
    expect(categories[1]?.title, 'المقدمة');
  });
}
