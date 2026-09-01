/// الصلوات المعروضة للمستخدم (الشروق معروض إعلامياً فقط، لا تُقام له جماعة).
enum PrayerName { fajr, sunrise, dhuhr, asr, maghrib, isha }

extension PrayerNameLabel on PrayerName {
  String get arabicLabel => switch (this) {
        PrayerName.fajr => 'الفجر',
        PrayerName.sunrise => 'الشروق',
        PrayerName.dhuhr => 'الظهر',
        PrayerName.asr => 'العصر',
        PrayerName.maghrib => 'المغرب',
        PrayerName.isha => 'العشاء',
      };

  /// هل تُقام لها جماعة (الإقامة)؟ الشروق ليس صلاة تُقام.
  bool get hasIqamah => this != PrayerName.sunrise;
}

/// اسم الصلاة مقروناً بوقت أذانها الفعلي. ضروري لأن "الصلاة الحالية" بين
/// منتصف الليل وأذان الفجر تكون هي عشاء *الأمس*، وليس عشاء اليوم (الذي لم
/// يحن وقته بعد)، فلا يكفي الاسم وحده لمعرفة الوقت الصحيح.
typedef PrayerOccurrence = (PrayerName name, DateTime time);

/// مواقيت الصلاة الخمس + الشروق ليوم واحد، مع عشاء الأمس وفجر الغد (اللازمين
/// لحساب الصلاة الحالية والإقامة بشكل صحيح في ساعات ما بعد منتصف الليل).
/// مستقل عن تفاصيل مكتبة الحساب الفلكي المستخدمة داخلياً (adhan_dart).
class DailyPrayerTimes {
  const DailyPrayerTimes({
    required this.date,
    required this.times,
    required this.yesterdayIsha,
    required this.tomorrowFajr,
  });

  final DateTime date;
  final Map<PrayerName, DateTime> times;
  final DateTime yesterdayIsha;
  final DateTime tomorrowFajr;

  DateTime timeOf(PrayerName prayer) => times[prayer]!;

  /// الصلاة القادمة بالنسبة لِـ [now] مع وقت أذانها. إن مرّت صلاة عشاء اليوم
  /// تُعاد صلاة فجر الغد.
  PrayerOccurrence nextPrayer(DateTime now) {
    for (final prayer in PrayerName.values) {
      final time = times[prayer]!;
      if (time.isAfter(now)) return (prayer, time);
    }
    return (PrayerName.fajr, tomorrowFajr);
  }

  /// الصلاة الحالية (آخر صلاة *تُقام* دخل وقتها) مع وقت أذانها الفعلي. قبل
  /// دخول وقت فجر اليوم تكون الصلاة الحالية هي عشاء الأمس بوقته الصحيح
  /// (وليس عشاء اليوم). الشروق مستثنى عمداً من هذا الحساب رغم وجوده ضمن
  /// [PrayerName.values]: فهو ليس صلاة تُقام لها جماعة ([PrayerNameLabel.hasIqamah])،
  /// فلا يصحّ اعتباره "الصلاة الحالية" بين وقته ووقت الظهر - كان هذا يجعل
  /// الصلاة الحالية تُقرأ خطأً كـ"الشروق" لنحو ٦ ساعات كل صباح.
  PrayerOccurrence currentPrayer(DateTime now) {
    PrayerName current = PrayerName.isha;
    DateTime currentTime = yesterdayIsha;
    for (final prayer in PrayerName.values) {
      if (!prayer.hasIqamah) continue;
      final time = times[prayer]!;
      if (!time.isAfter(now)) {
        current = prayer;
        currentTime = time;
      } else {
        break;
      }
    }
    return (current, currentTime);
  }

  /// نسخة مُعدَّلة يدوياً: يضيف عدد الدقائق المحدَّد لكل صلاة (موجب أو سالب)
  /// فوق الوقت المحسوب فلكياً، لمعايرة دقيقة حسب رؤية المستخدم المحلية.
  /// يُطبَّق التعديل أيضاً على عشاء الأمس وفجر الغد بنفس القيمة حتى يبقى
  /// حساب "الصلاة الحالية" قرب منتصف الليل متّسقاً مع التعديل.
  DailyPrayerTimes withAdjustments(Map<PrayerName, int> minutesByPrayer) {
    Duration deltaFor(PrayerName prayer) => Duration(minutes: minutesByPrayer[prayer] ?? 0);

    return DailyPrayerTimes(
      date: date,
      times: {for (final prayer in PrayerName.values) prayer: times[prayer]!.add(deltaFor(prayer))},
      yesterdayIsha: yesterdayIsha.add(deltaFor(PrayerName.isha)),
      tomorrowFajr: tomorrowFajr.add(deltaFor(PrayerName.fajr)),
    );
  }
}
