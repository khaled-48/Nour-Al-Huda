import 'package:flutter/material.dart';

/// حوار اختيار واحد من قائمة خيارات (طريقة الحساب، المذهب، وضع العرض...).
/// يُستخدم في شاشة الإعدادات لتقليل تكرار نفس منطق الحوار لكل إعداد.
Future<T?> showSingleChoiceDialog<T>({
  required BuildContext context,
  required String title,
  required List<T> options,
  required String Function(T option) labelBuilder,
  required T currentValue,
}) {
  return showDialog<T>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        child: RadioGroup<T>(
          groupValue: currentValue,
          onChanged: (value) => Navigator.of(context).pop(value),
          child: ListView(
            shrinkWrap: true,
            children: options.map((option) {
              return RadioListTile<T>(
                value: option,
                title: Text(labelBuilder(option)),
              );
            }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
      ],
    ),
  );
}
