import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/features/tasbih/presentation/screens/tasbih_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> pumpScreen(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('ar'),
          home: TasbihScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
  }

  testWidgets('يعرض العدّاد صفراً والهدف الافتراضي 33 عند الفتح', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('0'), findsOneWidget);
    expect(find.text('الهدف: 33'), findsOneWidget);
    expect(find.text('سبحان الله'), findsWidgets);
  });

  testWidgets('النقر على الدائرة يزيد العدّاد', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('0'));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.text('1'));
    await tester.pump();
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('اختيار عبارة أخرى يبدّل الشريحة المُختارة', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, 'الله أكبر'));
    await tester.pump();

    final chip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'الله أكبر'),
    );
    expect(chip.selected, isTrue);
  });

  testWidgets('زر إعادة التصفير يُعيد العدّاد للصفر', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('0'));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byTooltip('إعادة تصفير'));
    await tester.pump();
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('تغيير الهدف يفتح حواراً ويطبّق القيمة المختارة', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.text('تغيير الهدف'));
    await tester.pumpAndSettle();

    expect(find.text('هدف التسبيح'), findsOneWidget);

    await tester.tap(find.text('99'));
    await tester.pumpAndSettle();

    expect(find.text('الهدف: 99'), findsOneWidget);
  });
}
