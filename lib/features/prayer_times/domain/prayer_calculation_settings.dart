import 'package:adhan_dart/adhan_dart.dart';

/// طرق الحساب المعروضة للمستخدم مع تسمياتها العربية.
enum PrayerCalculationMethodOption {
  muslimWorldLeague,
  egyptian,
  karachi,
  ummAlQura,
  northAmerica,
  kuwait,
  qatar,
  singapore,
  tehran,
  turkiye,
  dubai,
  moonsightingCommittee,
}

extension PrayerCalculationMethodOptionX on PrayerCalculationMethodOption {
  String get arabicLabel => switch (this) {
        PrayerCalculationMethodOption.muslimWorldLeague => 'رابطة العالم الإسلامي',
        PrayerCalculationMethodOption.egyptian => 'الهيئة المصرية العامة للمساحة',
        PrayerCalculationMethodOption.karachi => 'جامعة العلوم الإسلامية - كراتشي',
        PrayerCalculationMethodOption.ummAlQura => 'جامعة أم القرى - مكة المكرمة',
        PrayerCalculationMethodOption.northAmerica => 'الجمعية الإسلامية لأمريكا الشمالية',
        PrayerCalculationMethodOption.kuwait => 'الكويت',
        PrayerCalculationMethodOption.qatar => 'قطر',
        PrayerCalculationMethodOption.singapore => 'سنغافورة',
        PrayerCalculationMethodOption.tehran => 'طهران',
        PrayerCalculationMethodOption.turkiye => 'تركيا (ديانت)',
        PrayerCalculationMethodOption.dubai => 'دبي',
        PrayerCalculationMethodOption.moonsightingCommittee => 'لجنة رؤية الهلال',
      };

  CalculationParameters toCalculationParameters() => switch (this) {
        PrayerCalculationMethodOption.muslimWorldLeague =>
          CalculationMethodParameters.muslimWorldLeague(),
        PrayerCalculationMethodOption.egyptian => CalculationMethodParameters.egyptian(),
        PrayerCalculationMethodOption.karachi => CalculationMethodParameters.karachi(),
        PrayerCalculationMethodOption.ummAlQura => CalculationMethodParameters.ummAlQura(),
        PrayerCalculationMethodOption.northAmerica => CalculationMethodParameters.northAmerica(),
        PrayerCalculationMethodOption.kuwait => CalculationMethodParameters.kuwait(),
        PrayerCalculationMethodOption.qatar => CalculationMethodParameters.qatar(),
        PrayerCalculationMethodOption.singapore => CalculationMethodParameters.singapore(),
        PrayerCalculationMethodOption.tehran => CalculationMethodParameters.tehran(),
        PrayerCalculationMethodOption.turkiye => CalculationMethodParameters.turkiye(),
        PrayerCalculationMethodOption.dubai => CalculationMethodParameters.dubai(),
        PrayerCalculationMethodOption.moonsightingCommittee =>
          CalculationMethodParameters.moonsightingCommittee(),
      };
}

/// إعدادات حساب مواقيت الصلاة القابلة للتخصيص من قبل المستخدم.
class PrayerCalculationSettings {
  const PrayerCalculationSettings({
    this.method = PrayerCalculationMethodOption.ummAlQura,
    this.madhab = Madhab.shafi,
  });

  final PrayerCalculationMethodOption method;
  final Madhab madhab;

  PrayerCalculationSettings copyWith({
    PrayerCalculationMethodOption? method,
    Madhab? madhab,
  }) {
    return PrayerCalculationSettings(
      method: method ?? this.method,
      madhab: madhab ?? this.madhab,
    );
  }
}
