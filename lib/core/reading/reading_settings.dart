import 'package:flutter/material.dart';

/// إعدادات قراءة عامة (لون الخلفية، لون النص، حجم الخط) قابلة لإعادة
/// الاستخدام في أي شاشة قراءة طويلة بالتطبيق (القرآن، الأذكار...)، بحيث
/// يملك كل مستخدم تحكماً حراً في المظهر يناسب راحة عينيه.
class ReadingSettings {
  const ReadingSettings({
    required this.backgroundColor,
    required this.textColor,
    required this.fontScale,
    this.isCustom = false,
  });

  final Color backgroundColor;
  final Color textColor;
  final double fontScale;

  /// هل اختار المستخدم هذه الألوان بنفسه؟ إن كانت false فالألوان مجرد
  /// افتراضي مؤقت يجب استبداله بـ [resolveFor] حسب السطوع الحالي (فاتح/داكن)
  /// قبل العرض، لأن هذا الكائن نفسه لا يعرف سطوع الثيم وقت إنشائه.
  final bool isCustom;

  static const minFontScale = 0.7;
  static const maxFontScale = 1.8;

  /// افتراضي فاتح ومضيء قليلاً وهادئ للعين، أقرب لدرجة الورق الكريمي.
  static const lightDefaults = ReadingSettings(
    backgroundColor: Color(0xFFFBF3E1),
    textColor: Color(0xFF3A362E),
    fontScale: 1.0,
  );

  /// افتراضي داكن مريح ليلاً، بدرجة بنّية سوداء دافئة بدل الأسود البحت.
  static const darkDefaults = ReadingSettings(
    backgroundColor: Color(0xFF1E1B16),
    textColor: Color(0xFFE4DCC8),
    fontScale: 1.0,
  );

  static ReadingSettings defaultsFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkDefaults : lightDefaults;

  /// لون زخرفي مكتوم مُشتقّ من لون النص ممزوجاً بالخلفية، يُستخدم للحدود
  /// والمِدلايات والفواصل دون الحاجة لإعداد لون ثالث منفصل.
  Color get accentColor => Color.alphaBlend(textColor.withValues(alpha: 0.55), backgroundColor);

  /// يُرجع هذه الإعدادات كما هي إن خصّصها المستخدم بنفسه، وإلا الألوان
  /// الافتراضية المناسبة لسطوع الثيم الحالي (فاتح/داكن) مع الإبقاء على حجم
  /// الخط المختار. استخدم هذه الدالة عند العرض دائماً بدل الحقول مباشرة.
  ReadingSettings resolveFor(Brightness brightness) {
    if (isCustom) return this;
    return defaultsFor(brightness).copyWith(fontScale: fontScale);
  }

  ReadingSettings copyWith({
    Color? backgroundColor,
    Color? textColor,
    double? fontScale,
    bool? isCustom,
  }) {
    return ReadingSettings(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      fontScale: fontScale ?? this.fontScale,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}
