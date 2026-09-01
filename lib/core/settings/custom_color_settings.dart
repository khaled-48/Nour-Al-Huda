import 'package:flutter/material.dart';

/// تخصيص ألوان يدوي متقدم لعناصر واجهة مواقيت الصلاة: كل عنصر (لون
/// النصوص العامة، خلفيات البطاقات، لون التاريخ/الأيام، ولون الأوقات
/// والساعات) قابل للتحكم فيه منفصلاً عن غيره. أي حقل null يعني "استخدم
/// اللون الافتراضي للتطبيق" بدل قيمة مفروضة.
class CustomColorSettings {
  const CustomColorSettings({
    this.enabled = false,
    this.textColor,
    this.backgroundColor,
    this.dateColor,
    this.clockColor,
  });

  /// المفتاح الرئيسي: إن كان false تُتجاهل كل الألوان أدناه ويُستخدم مظهر
  /// التطبيق الافتراضي بالكامل، حتى لو اختار المستخدم ألواناً من قبل.
  final bool enabled;

  /// لون النصوص العامة (أسماء الصلوات، العناوين...).
  final Color? textColor;

  /// لون خلفيات البطاقات (بطاقة الصلاة القادمة، قائمة المواقيت...).
  final Color? backgroundColor;

  /// لون التاريخ الهجري/الميلادي واسم اليوم.
  final Color? dateColor;

  /// لون أرقام الأوقات والعدّاد التنازلي.
  final Color? clockColor;
}
