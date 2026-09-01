import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/features/settings/data/backup_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// نسخة وهمية من PathProviderPlatform تُعيد مجلداً مؤقتاً حقيقياً على القرص،
/// حتى يتمكّن BackupService من كتابة ملف النسخة الاحتياطية فعلياً أثناء
/// الاختبار بلا حاجة لقناة منصّة (platform channel) غير متوفرة في بيئة
/// الاختبار.
class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this._tempDir);
  final Directory _tempDir;

  @override
  Future<String?> getTemporaryPath() async => _tempDir.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  const service = BackupService();

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('backup_service_test');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir);
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('يصدّر كل مفاتيح SharedPreferences إلى ملف JSON صالح', () async {
    SharedPreferences.setMockInitialValues({
      'pref_theme_mode': 'dark',
      'pref_tasbih_count': 42,
      'pref_notifications_enabled': true,
    });

    final path = await service.exportToJsonFile();
    final file = File(path);

    expect(file.existsSync(), isTrue);
    final content = file.readAsStringSync();
    expect(content, contains('pref_theme_mode'));
    expect(content, contains('pref_tasbih_count'));
    expect(content, contains('"schemaVersion":1'));
  });

  test('يستعيد نفس القيم التي صُدِّرت (تصدير ثم استيراد)', () async {
    SharedPreferences.setMockInitialValues({
      'pref_theme_mode': 'dark',
      'pref_tasbih_count': 42,
      'pref_notifications_enabled': true,
    });

    final path = await service.exportToJsonFile();

    // يمحو كل الإعدادات الحالية قبل الاستعادة، للتأكد أن الاستيراد هو ما
    // أعادها فعلاً وليست باقية من قبل.
    SharedPreferences.setMockInitialValues({});

    final result = await service.importFromJsonFile(path);
    expect(result.restoredKeyCount, 3);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('pref_theme_mode'), 'dark');
    expect(prefs.getInt('pref_tasbih_count'), 42);
    expect(prefs.getBool('pref_notifications_enabled'), isTrue);
  });

  test('يرفض ملف نسخة احتياطية بإصدار مخطط غير مدعوم', () async {
    final file = File('${tempDir.path}/bad_backup.json');
    await file.writeAsString(
      '{"schemaVersion": 99, "prefs": {"pref_theme_mode": "dark"}}',
    );

    expect(
      () => service.importFromJsonFile(file.path),
      throwsA(isA<UnsupportedBackupVersionException>()),
    );
  });
}
