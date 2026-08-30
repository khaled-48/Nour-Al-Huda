import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:islamic_app/main.dart';

void main() {
  testWidgets('التطبيق يُقلع ويعرض شاشة القرآن', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: IslamicApp()));
    // لا نستخدم pumpAndSettle لأن عدّاد مواقيت الصلاة ينبض كل ثانية باستمرار
    // حتى لو لم تكن شاشته الحالية معروضة (يُحمَّل بشكل كسول في تبويبه).
    await tester.pump();
    await tester.pump();

    expect(find.text('القرآن الكريم'), findsOneWidget);
  });
}
