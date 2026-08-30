import '../settings/numeral_style.dart';
import '../settings/time_format_option.dart';
import 'numeral_formatter.dart';

/// دوال مساعدة لتنسيق الأوقات والمدد بصيغة عربية داخل واجهات التطبيق.
class TimeFormatters {
  TimeFormatters._();

  /// يهيّئ الوقت حسب تفضيل المستخدم (12 أو 24 ساعة) ونظام الأرقام.
  static String time(DateTime time, TimeFormatOption format, [NumeralStyle numerals = NumeralStyle.western]) {
    final formatted = format == TimeFormatOption.h24 ? _time24h(time) : _time12h(time);
    return formatNumerals(formatted, numerals);
  }

  /// ٠٥:٣٢ ص
  static String _time12h(DateTime time) {
    final hour24 = time.hour;
    final isAm = hour24 < 12;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = isAm ? 'ص' : 'م';
    return '${hour12.toString().padLeft(2, '0')}:$minute $period';
  }

  /// ١٧:٣٢
  static String _time24h(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// ٠١:٠٢:٠٣ (ساعات:دقائق:ثواني)، ويحذف الساعات إن كانت صفراً.
  static String countdown(Duration duration, [NumeralStyle numerals = NumeralStyle.western]) {
    final clamped = duration.isNegative ? Duration.zero : duration;
    final hours = clamped.inHours;
    final minutes = clamped.inMinutes.remainder(60);
    final seconds = clamped.inSeconds.remainder(60);

    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');

    final formatted = hours > 0 ? '${hours.toString().padLeft(2, '0')}:$mm:$ss' : '$mm:$ss';
    return formatNumerals(formatted, numerals);
  }
}
