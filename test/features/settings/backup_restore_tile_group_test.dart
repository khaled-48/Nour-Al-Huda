import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/features/settings/presentation/widgets/backup_restore_tile_group.dart';

void main() {
  testWidgets('يعرض عنصرَي التصدير والاستعادة بعنوانيهما ووصفيهما', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        home: Scaffold(body: BackupRestoreTileGroup()),
      ),
    );

    expect(find.text('نسخ احتياطي'), findsOneWidget);
    expect(
      find.text('تصدير كل الإعدادات والعلامات المرجعية لملف واحد'),
      findsOneWidget,
    );
    expect(find.text('استعادة نسخة احتياطية'), findsOneWidget);
    expect(find.text('استيراد ملف نسخة احتياطية سابق'), findsOneWidget);

    expect(find.byIcon(Icons.backup_outlined), findsOneWidget);
    expect(find.byIcon(Icons.restore_outlined), findsOneWidget);

    // كلاهما قابل للنقر فعلياً (ListTile له onTap)، بلا تنفيذ النقر هنا -
    // ذلك يستدعي قنوات منصّة حقيقية (مُنتقي ملفات/مشاركة) غير متوفرة في
    // بيئة الاختبار؛ منطق BackupService نفسه مُختبَر بمعزل في
    // backup_service_test.dart.
    final exportTile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'نسخ احتياطي'),
    );
    final restoreTile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'استعادة نسخة احتياطية'),
    );
    expect(exportTile.onTap, isNotNull);
    expect(restoreTile.onTap, isNotNull);
  });
}
