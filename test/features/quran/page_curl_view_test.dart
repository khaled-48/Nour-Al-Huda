import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/features/quran/presentation/widgets/page_curl_view.dart';

Widget _buildApp({
  required int itemCount,
  required int initialIndex,
  ValueChanged<int>? onIndexChanged,
}) {
  return MaterialApp(
    home: Scaffold(
      body: PageCurlView(
        itemCount: itemCount,
        initialIndex: initialIndex,
        onIndexChanged: onIndexChanged,
        semanticLabel: 'اختبار الصفحات',
        itemBuilder: (context, index) => Center(child: Text('page $index')),
      ),
    ),
  );
}

/// يحاكي شكل الخلل الحقيقي (شاشة الأذكار): صفحة ذات حالة داخلية (State)
/// تُنشئ قائمة بحجم يعتمد على بيانات الصفحة عند أول بناء لها فقط
/// (`late final`)، تماماً كعدّاد تكرار كل دعاء في `_CategoryPageState`.
/// لو أعاد PageCurlView استخدام نفس الـ State عند تغيّر الفهرس (بدل بناء
/// عنصر جديد)، ستبقى هذه القائمة بحجم الصفحة *السابقة*، فيفشل أي وصول
/// لعنصر ضمن حجم الصفحة *الحالية* الأكبر بـ RangeError.
final _itemsPerPage = [3, 5, 2];

class _VariableLengthPage extends StatefulWidget {
  const _VariableLengthPage({required this.pageIndex});

  final int pageIndex;

  @override
  State<_VariableLengthPage> createState() => _VariableLengthPageState();
}

class _VariableLengthPageState extends State<_VariableLengthPage> {
  late final List<int> _counts = List.filled(
    _itemsPerPage[widget.pageIndex],
    0,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < _itemsPerPage[widget.pageIndex]; i++)
          Text('counter-${widget.pageIndex}-$i: ${_counts[i]}'),
      ],
    );
  }
}

void main() {
  testWidgets('يعرض الصفحة الابتدائية المطلوبة', (tester) async {
    await tester.pumpWidget(_buildApp(itemCount: 3, initialIndex: 1));
    await tester.pumpAndSettle();

    expect(find.text('page 1'), findsOneWidget);
  });

  testWidgets('السحب لليمين يتقدّم إلى الصفحة التالية', (tester) async {
    int? changedTo;
    await tester.pumpWidget(
      _buildApp(
        itemCount: 3,
        initialIndex: 0,
        onIndexChanged: (i) => changedTo = i,
      ),
    );
    await tester.pumpAndSettle();

    await tester.fling(find.byType(PageCurlView), const Offset(300, 0), 1000);
    await tester.pumpAndSettle();

    expect(changedTo, 1);
    expect(find.text('page 1'), findsOneWidget);
  });

  testWidgets('السحب لليسار يرجع إلى الصفحة السابقة', (tester) async {
    int? changedTo;
    await tester.pumpWidget(
      _buildApp(
        itemCount: 3,
        initialIndex: 1,
        onIndexChanged: (i) => changedTo = i,
      ),
    );
    await tester.pumpAndSettle();

    await tester.fling(find.byType(PageCurlView), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();

    expect(changedTo, 0);
    expect(find.text('page 0'), findsOneWidget);
  });

  testWidgets('لا يتجاوز آخر صفحة عند محاولة التقدّم بعدها', (tester) async {
    int? changedTo;
    await tester.pumpWidget(
      _buildApp(
        itemCount: 2,
        initialIndex: 1,
        onIndexChanged: (i) => changedTo = i,
      ),
    );
    await tester.pumpAndSettle();

    await tester.fling(find.byType(PageCurlView), const Offset(300, 0), 1000);
    await tester.pumpAndSettle();

    expect(changedTo, isNull);
    expect(find.text('page 1'), findsOneWidget);
  });

  testWidgets('لا يرجع قبل أول صفحة عند محاولة الرجوع منها', (tester) async {
    int? changedTo;
    await tester.pumpWidget(
      _buildApp(
        itemCount: 2,
        initialIndex: 0,
        onIndexChanged: (i) => changedTo = i,
      ),
    );
    await tester.pumpAndSettle();

    await tester.fling(find.byType(PageCurlView), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();

    expect(changedTo, isNull);
    expect(find.text('page 0'), findsOneWidget);
  });

  testWidgets('إجراء increase من قارئ الشاشة يتقدّم للصفحة التالية', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    int? changedTo;
    await tester.pumpWidget(
      _buildApp(
        itemCount: 3,
        initialIndex: 0,
        onIndexChanged: (i) => changedTo = i,
      ),
    );
    await tester.pumpAndSettle();

    final node = tester.getSemantics(find.bySemanticsLabel('اختبار الصفحات'));
    node.owner!.performAction(node.id, SemanticsAction.increase);
    await tester.pumpAndSettle();

    expect(changedTo, 1);
    expect(find.text('page 1'), findsOneWidget);

    handle.dispose();
  });

  testWidgets('إجراء decrease من قارئ الشاشة يرجع للصفحة السابقة', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    int? changedTo;
    await tester.pumpWidget(
      _buildApp(
        itemCount: 3,
        initialIndex: 1,
        onIndexChanged: (i) => changedTo = i,
      ),
    );
    await tester.pumpAndSettle();

    final node = tester.getSemantics(find.bySemanticsLabel('اختبار الصفحات'));
    node.owner!.performAction(node.id, SemanticsAction.decrease);
    await tester.pumpAndSettle();

    expect(changedTo, 0);
    expect(find.text('page 0'), findsOneWidget);

    handle.dispose();
  });

  testWidgets(
    'التنقّل بين صفحات ذات حالة داخلية مختلفة الحجم لا يسبب RangeError',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageCurlView(
              itemCount: _itemsPerPage.length,
              initialIndex: 0,
              itemBuilder: (context, index) =>
                  _VariableLengthPage(pageIndex: index),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // من 3 عناصر إلى 5 عناصر: كان هذا يسبب RangeError عند إعادة استخدام
      // نفس الـ State بقائمة عدّادات بحجم 3 القديم.
      await tester.fling(
        find.text('counter-0-0: 0'),
        const Offset(300, 0),
        1000,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('counter-1-4: 0'), findsOneWidget);

      // من 5 عناصر إلى 2: نفس الخطر في الاتجاه المعاكس.
      await tester.fling(
        find.text('counter-1-0: 0'),
        const Offset(300, 0),
        1000,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('counter-2-1: 0'), findsOneWidget);
    },
  );

  testWidgets('سحب قطري يبدأ من النصف العلوي يتقدّم دون استثناء', (
    tester,
  ) async {
    int? changedTo;
    await tester.pumpWidget(
      _buildApp(
        itemCount: 3,
        initialIndex: 0,
        onIndexChanged: (i) => changedTo = i,
      ),
    );
    await tester.pumpAndSettle();

    final topLeft = tester.getTopLeft(find.byType(PageCurlView));
    final size = tester.getSize(find.byType(PageCurlView));
    final start = topLeft + Offset(size.width * 0.7, size.height * 0.15);

    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(40, 20));
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.moveBy(const Offset(450, -60));
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.takeException(), isNull);
    await gesture.up();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(changedTo, 1);
    expect(find.text('page 1'), findsOneWidget);
  });

  testWidgets('سحب قطري يبدأ من النصف السفلي يرجع دون استثناء', (tester) async {
    int? changedTo;
    await tester.pumpWidget(
      _buildApp(
        itemCount: 3,
        initialIndex: 1,
        onIndexChanged: (i) => changedTo = i,
      ),
    );
    await tester.pumpAndSettle();

    final topLeft = tester.getTopLeft(find.byType(PageCurlView));
    final size = tester.getSize(find.byType(PageCurlView));
    final start = topLeft + Offset(size.width * 0.3, size.height * 0.85);

    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(-40, -20));
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.moveBy(const Offset(-450, 60));
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.takeException(), isNull);
    await gesture.up();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(changedTo, 0);
    expect(find.text('page 0'), findsOneWidget);
  });

  testWidgets('سحب جزئي دون الحدّ الأدنى يُلغى ويعود للصفحة نفسها', (
    tester,
  ) async {
    int? changedTo;
    await tester.pumpWidget(
      _buildApp(
        itemCount: 3,
        initialIndex: 1,
        onIndexChanged: (i) => changedTo = i,
      ),
    );
    await tester.pumpAndSettle();

    final center = tester.getCenter(find.byType(PageCurlView));
    final gesture = await tester.startGesture(center);
    // إزاحة تتجاوز منطقة التحديد الميتة فتُحدَّد اتجاهاً (للأمام)، لكنها
    // أقل بكثير من حدّ الالتزام (0.35 من العرض) ثم تُرفَع بلا سرعة انزلاق.
    await gesture.moveBy(const Offset(15, 5));
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.takeException(), isNull);
    await gesture.up();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(changedTo, isNull);
    expect(find.text('page 1'), findsOneWidget);
  });
}
