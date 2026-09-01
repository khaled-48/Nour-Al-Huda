import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:islamic_app/main.dart';

void main() {
  testWidgets('التطبيق يُقلع ويعرض شاشة مواقيت الصلاة', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: IslamicApp()));
    // لا نستخدم pumpAndSettle لأن عدّاد مواقيت الصلاة ينبض كل ثانية باستمرار
    // حتى لو لم تكن شاشته الحالية معروضة (يُحمَّل بشكل كسول في تبويبه).
    await tester.pump();
    await tester.pump();

    // تُقلع الشاشة الرئيسية على مواقيت الصلاة لا القرآن (أكثر ما يحتاجه
    // المستخدم فوراً عند فتح التطبيق).
    expect(find.text('مواقيت الصلاة'), findsOneWidget);
  });
}
