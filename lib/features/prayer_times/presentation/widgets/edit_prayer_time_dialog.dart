import 'package:flutter/material.dart';

/// يفتح منتقي وقت (ساعة ودقيقة) لمعايرة وقت صلاة يدوياً، ويُعيد الفرق
/// بالدقائق بين الوقت الجديد المُختار ووقت الحساب الفلكي الأصلي — هذا
/// الفرق هو ما يُحفظ كتعديل دائم يُطبَّق على حساب كل يوم لاحقاً.
Future<int?> showEditPrayerTimeDialog({
  required BuildContext context,
  required String prayerLabel,
  required DateTime currentAdjustedTime,
  required DateTime rawCalculatedTime,
}) async {
  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(currentAdjustedTime),
    helpText: 'وقت أذان $prayerLabel',
  );
  if (picked == null) return null;

  final rawMinutesOfDay = rawCalculatedTime.hour * 60 + rawCalculatedTime.minute;
  final pickedMinutesOfDay = picked.hour * 60 + picked.minute;
  return pickedMinutesOfDay - rawMinutesOfDay;
}
