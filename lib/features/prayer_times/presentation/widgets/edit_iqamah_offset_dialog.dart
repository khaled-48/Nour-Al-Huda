import 'package:flutter/material.dart';

import '../../domain/daily_prayer_times.dart';

/// حوار بسيط لتعديل عدد دقائق الإقامة بعد أذان صلاة معيّنة.
Future<int?> showEditIqamahOffsetDialog({
  required BuildContext context,
  required PrayerName prayer,
  required int currentMinutes,
}) {
  final controller = TextEditingController(text: currentMinutes.toString());

  return showDialog<int>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('مدة الإقامة بعد أذان ${prayer.arabicLabel}'),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        autofocus: true,
        decoration: const InputDecoration(suffixText: 'دقيقة'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () {
            final value = int.tryParse(controller.text);
            Navigator.of(context).pop(value);
          },
          child: const Text('حفظ'),
        ),
      ],
    ),
  );
}
