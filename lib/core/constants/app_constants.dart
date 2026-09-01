/// ثوابت عامة يُعاد استخدامها في أنحاء التطبيق.
class AppConstants {
  AppConstants._();

  static const String appName = 'مُصْحَفْ وَأَذْكَارْ';

  // مفاتيح SharedPreferences
  static const String prefThemeMode = 'pref_theme_mode';
  static const String prefIqamahOffsetPrefix =
      'pref_iqamah_offset_'; // + اسم الصلاة
  static const String prefPrayerAdjustmentPrefix =
      'pref_prayer_adjustment_'; // + اسم الصلاة
  static const String prefCalculationMethod = 'pref_calculation_method';
  static const String prefMadhab = 'pref_madhab';
  static const String prefTimeFormat = 'pref_time_format';
  static const String prefNumeralStyle = 'pref_numeral_style';
  static const String prefNotificationsEnabled = 'pref_notifications_enabled';
  static const String prefLastLatitude = 'pref_last_latitude';
  static const String prefLastLongitude = 'pref_last_longitude';
  static const String prefTvModeOverride = 'pref_tv_mode_override';
  static const String prefCityName = 'pref_city_name';
  static const String prefMosqueName = 'pref_mosque_name';

  // مسارات بيانات القرآن الكريم والتفسير (JSON محلي ضمن الـ assets)
  static const String quranSurahsAssetPath = 'assets/data/quran/surahs.json';
  static const String quranSearchIndexAssetPath =
      'assets/data/quran/search_index.json';
  static const String quranJuzIndexAssetPath =
      'assets/data/quran/juz_index.json';
  static const String quranPageIndexAssetPath =
      'assets/data/quran/page_index.json';

  /// عدد صفحات مصحف المدينة المطبعي القياسي، وهو ترقيم الصفحة/الجزء
  /// المضمَّن أصلاً في كل آية ضمن ملفات assets/data/quran/ayahs.
  static const int quranPageCount = 604;
  static String quranAyahsAssetPath(int surahId) =>
      'assets/data/quran/ayahs/${surahId.toString().padLeft(3, '0')}.json';
  static String quranTafsirAssetPath(int surahId) =>
      'assets/data/quran/tafsir/${surahId.toString().padLeft(3, '0')}.json';

  /// تخطيط صفحة مصحف مطابق حرفياً لطباعة مجمع الملك فهد (QPC v2): كل سطر
  /// من أسطر الصفحة الخمسة عشر برموز حروف خط تلك الصفحة تحديداً.
  static String qpcPageLayoutAssetPath(int page) =>
      'assets/data/quran/qpc_pages/${page.toString().padLeft(3, '0')}.json';

  /// خط QPC v2 الخاص بصفحة واحدة (مختلف لكل صفحة) - يُحمَّل ديناميكياً عند
  /// الحاجة فقط (لا يُدرَج ضمن `flutter.fonts` الثابتة في pubspec.yaml).
  static String qpcPageFontAssetPath(int page) =>
      'assets/fonts/qpc_v2/p$page.ttf';

  /// اسم عائلة الخط المُسجَّلة ديناميكياً لصفحة معيّنة (انظر [QpcFontLoader]).
  static String qpcPageFontFamily(int page) => 'QpcV2Page$page';

  // مسارات بيانات الأذكار (JSON محلي)
  static const String azkarDataPath = 'assets/data/azkar';
  static const String azkarAssetPath = 'assets/data/azkar/hisn_almuslim.json';

  // العلامات المرجعية (متابعة القراءة من حيث توقف المستخدم)
  static const String prefQuranBookmarks = 'pref_quran_bookmarks';

  // القيم الافتراضية لوقت الإقامة بعد الأذان (بالدقائق)
  static const Map<String, int> defaultIqamahOffsets = {
    'fajr': 20,
    'dhuhr': 15,
    'asr': 15,
    'maghrib': 10,
    'isha': 15,
  };
}
