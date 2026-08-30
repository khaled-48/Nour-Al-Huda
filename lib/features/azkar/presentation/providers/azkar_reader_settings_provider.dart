import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/reading/reading_settings.dart';
import '../../../../core/reading/reading_settings_notifier.dart';

final azkarReaderSettingsProvider =
    StateNotifierProvider<ReadingSettingsNotifier, ReadingSettings>((ref) {
  return ReadingSettingsNotifier('azkar_reader');
});
