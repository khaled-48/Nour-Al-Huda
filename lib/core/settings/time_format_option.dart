/// تنسيق عرض الوقت في كل أنحاء التطبيق.
enum TimeFormatOption { h12, h24 }

extension TimeFormatOptionLabel on TimeFormatOption {
  String get arabicLabel => switch (this) {
        TimeFormatOption.h12 => '12 ساعة (ص/م)',
        TimeFormatOption.h24 => '24 ساعة',
      };
}
