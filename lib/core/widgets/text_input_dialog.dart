import 'package:flutter/material.dart';

/// حوار إدخال نص واحد (اسم مدينة، اسم مسجد...)، يُعيد النص المُدخَل بعد
/// تشذيبه، أو null إن أُلغي. حقل فارغ يُعيد نصاً فارغاً (يُفسَّر كمسح القيمة).
Future<String?> showTextInputDialog({
  required BuildContext context,
  required String title,
  String? initialValue,
  String? hintText,
}) {
  final controller = TextEditingController(text: initialValue ?? '');
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(hintText: hintText),
        onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text.trim()),
          child: const Text('حفظ'),
        ),
      ],
    ),
  );
}
