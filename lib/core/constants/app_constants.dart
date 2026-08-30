/// ثوابت عامة يُعاد استخدامها في أنحاء التطبيق.
class AppConstants {
  AppConstants._();

  static const String appName = 'مُصْحَفْ وَأَذْكَارْ';

  // مفاتيح SharedPreferences
  static const String prefThemeMode = 'pref_theme_mode';
  static const String prefIqamahOffsetPrefix = 'pref_iqamah_offset_'; // + اسم الصلاة
  static const String prefPrayerAdjustmentPrefix = 'pref_prayer_adjustment_'; // + اسم الصلاة
  static const String prefCalculationMethod = 'pref_calculation_method';
  static const String prefMadhab = 'pref_madhab';
  static const String prefTimeFormat = 'pref_time_format';
  static const String prefNumeralStyle = 'pref_numeral_style';
  static const String prefNotificationsEnabled = 'pref_notifications_enabled';
  static const String prefLastLatitude = 'pref_last_latitude';
  static const String prefLastLongitude = 'pref_last_longitude';

  // مسارات بيانات القرآن الكريم والتفسير (JSON محلي ضمن الـ assets)
  static const String quranSurahsAssetPath = 'assets/data/quran/surahs.json';
  static const String quranSearchIndexAssetPath = 'assets/data/quran/search_index.json';
  static const String quranJuzIndexAssetPath = 'assets/data/quran/juz_index.json';
  static String quranAyahsAssetPath(int surahId) =>
      'assets/data/quran/ayahs/${surahId.toString().padLeft(3, '0')}.json';
  static String quranTafsirAssetPath(int surahId) =>
      'assets/data/quran/tafsir/${surahId.toString().padLeft(3, '0')}.json';

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
