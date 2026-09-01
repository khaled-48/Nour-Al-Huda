import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/backup_service.dart';

/// قسم "نسخ احتياطي" في الإعدادات: تصدير كل تفضيلات المستخدم (الثيم،
/// الألوان المخصّصة، العلامات المرجعية، مواقيت الإقامة...) لملف JSON واحد
/// قابل للمشاركة، واستعادته لاحقاً على نفس الجهاز أو جهاز آخر.
class BackupRestoreTileGroup extends StatelessWidget {
  const BackupRestoreTileGroup({super.key});

  Future<void> _export(BuildContext context) async {
    final path = await const BackupService().exportToJsonFile();
    await SharePlus.instance.share(ShareParams(files: [XFile(path)]));
  }

  Future<void> _import(BuildContext context) async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (files.isEmpty) return;
    final path = files.first.path;
    if (path == null) return;

    if (!context.mounted) return;
    try {
      await const BackupService().importFromJsonFile(path);
    } on UnsupportedBackupVersionException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
      return;
    }

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('تمّت الاستعادة'),
        content: const Text(
          'تمّت استعادة النسخة الاحتياطية بنجاح. أغلق التطبيق الآن وأعد '
          'فتحه حتى تُطبَّق كل الإعدادات المستعادة بشكل صحيح.',
        ),
        actions: [
          FilledButton(
            onPressed: () => SystemNavigator.pop(),
            child: const Text('إغلاق التطبيق'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.backup_outlined),
          title: const Text('نسخ احتياطي'),
          subtitle: const Text(
            'تصدير كل الإعدادات والعلامات المرجعية لملف واحد',
          ),
          onTap: () => _export(context),
        ),
        ListTile(
          leading: const Icon(Icons.restore_outlined),
          title: const Text('استعادة نسخة احتياطية'),
          subtitle: const Text('استيراد ملف نسخة احتياطية سابق'),
          onTap: () => _import(context),
        ),
      ],
    );
  }
}
