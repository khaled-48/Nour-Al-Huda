import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/reading/reading_settings.dart';
import '../../../../core/reading/reading_settings_notifier.dart';

final quranReaderSettingsProvider =
    StateNotifierProvider<ReadingSettingsNotifier, ReadingSettings>((ref) {
  return ReadingSettingsNotifier('quran_reader');
});
