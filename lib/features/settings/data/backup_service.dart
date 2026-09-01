import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// نسخة احتياطية غير مدعومة (أُنشئت بإصدار أحدث من التطبيق لا يعرفه هذا
/// الإصدار الحالي).
class UnsupportedBackupVersionException implements Exception {
  const UnsupportedBackupVersionException(this.foundVersion);
  final int foundVersion;

  @override
  String toString() =>
      'إصدار النسخة الاحتياطية ($foundVersion) غير مدعوم في هذا الإصدار من التطبيق.';
}

/// نتيجة استعادة ناجحة: عدد الإعدادات التي أُعيدت.
class BackupImportResult {
  const BackupImportResult({required this.restoredKeyCount});
  final int restoredKeyCount;
}

/// يصدّر/يستورد كل ما هو محفوظ في SharedPreferences (كل الإعدادات،
/// العلامات المرجعية، الألوان المخصّصة...) كملف JSON واحد. يعمل بشكل عام
/// عبر SharedPreferences.getKeys() بدل قائمة مفاتيح يدوية، فيلتقط تلقائياً
/// أي مفتاح موجود فعلاً - حالياً أو أُضيف مستقبلاً - بلا صيانة إضافية.
class BackupService {
  const BackupService();

  static const _currentSchemaVersion = 1;

  /// يكتب نسخة احتياطية بكل تفضيلات المستخدم إلى ملف مؤقت، ويُعيد مساره.
  Future<String> exportToJsonFile() async {
    final prefs = await SharedPreferences.getInstance();
    final data = <String, Object?>{
      for (final key in prefs.getKeys()) key: prefs.get(key),
    };

    final payload = {
      'schemaVersion': _currentSchemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'prefs': data,
    };

    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/islamic_app_backup_$timestamp.json');
    await file.writeAsString(jsonEncode(payload));
    return file.path;
  }

  /// يقرأ ملف نسخة احتياطية سابق ويكتب كل مفاتيحه إلى SharedPreferences.
  Future<BackupImportResult> importFromJsonFile(String path) async {
    final raw = await File(path).readAsString();
    final decoded = jsonDecode(raw) as Map<String, dynamic>;

    final schemaVersion = decoded['schemaVersion'] as int? ?? 0;
    if (schemaVersion != _currentSchemaVersion) {
      throw UnsupportedBackupVersionException(schemaVersion);
    }

    final data = (decoded['prefs'] as Map<String, dynamic>);
    final prefs = await SharedPreferences.getInstance();

    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is List) {
        await prefs.setStringList(key, value.cast<String>());
      }
    }

    return BackupImportResult(restoredKeyCount: data.length);
  }
}
