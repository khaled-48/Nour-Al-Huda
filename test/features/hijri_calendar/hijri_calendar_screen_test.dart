import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:islamic_app/features/hijri_calendar/presentation/screens/hijri_calendar_screen.dart';

void main() {
  Future<void> pumpScreen(WidgetTester tester) async {
    // سطح الاختبار الافتراضي (800×600) أقصر من أي هاتف حقيقي، فتفيض شبكة
    // الأشهر (٦ أسابيع) خارج الشاشة فيه فقط - لا خلل في الودجت نفسها
    // (تحقّقنا يدوياً أنها تعمل بلا فيض على جهاز حقيقي). نحاكي هنا ارتفاع
    // هاتف واقعياً بدل تغيير تصميم الشاشة لأجل بيئة الاختبار فقط.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        home: HijriCalendarScreen(),
      ),
    );
    await tester.pump();
  }

  testWidgets('يفتح على الشهر الهجري الحالي ويعرض أسماء أيام الأسبوع', (
    tester,
  ) async {
    await pumpScreen(tester);

    final now = HijriCalendar.now();
    final monthName = (HijriCalendar()..hMonth = now.hMonth).getLongMonthName();

    expect(find.textContaining(monthName), findsOneWidget);
    expect(find.text('سبت'), findsOneWidget);
    expect(find.text('جمعة'), findsOneWidget);
  });

  testWidgets('السهم التالي يتقدّم شهراً هجرياً، والسابق يرجع للأصلي', (
    tester,
  ) async {
    await pumpScreen(tester);

    final now = HijriCalendar.now();
    final currentMonthName = (HijriCalendar()..hMonth = now.hMonth)
        .getLongMonthName();

    await tester.tap(find.byTooltip('الشهر التالي'));
    await tester.pump();

    expect(find.textContaining(currentMonthName), findsNothing);

    await tester.tap(find.byTooltip('الشهر السابق'));
    await tester.pump();

    expect(find.textContaining(currentMonthName), findsOneWidget);
  });
}
