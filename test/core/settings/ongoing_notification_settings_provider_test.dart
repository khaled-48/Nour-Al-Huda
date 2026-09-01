import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/core/constants/app_constants.dart';
import 'package:islamic_app/core/settings/ongoing_notification_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ينشئ حاوية جديدة ويقرأ المزوّد فوراً (فهو كسول ولن يبدأ تحميل الحالة من
/// SharedPreferences إلا عند أول قراءة)، ثم ينتظر اكتمال ذلك التحميل غير
/// المتزامن قبل إعادة الحاوية.
Future<ProviderContainer> _readyContainer() async {
  final container = ProviderContainer();
  container.read(ongoingPrayerNotificationEnabledProvider);
  await Future<void>.delayed(const Duration(milliseconds: 20));
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('معطَّل افتراضياً بلا قيمة محفوظة (بخلاف تنبيه الأذان)', () async {
    SharedPreferences.setMockInitialValues({});
    final container = await _readyContainer();
    addTearDown(container.dispose);

    expect(container.read(ongoingPrayerNotificationEnabledProvider), isFalse);
  });

  test('يحمّل true إن كانت محفوظة كذلك', () async {
    SharedPreferences.setMockInitialValues({
      AppConstants.prefOngoingPrayerNotificationEnabled: true,
    });
    final container = await _readyContainer();
    addTearDown(container.dispose);

    expect(container.read(ongoingPrayerNotificationEnabledProvider), isTrue);
  });

  test('setEnabled يحدّث الحالة ويحفظها', () async {
    SharedPreferences.setMockInitialValues({});
    final container = await _readyContainer();
    addTearDown(container.dispose);

    await container
        .read(ongoingPrayerNotificationEnabledProvider.notifier)
        .setEnabled(true);

    expect(container.read(ongoingPrayerNotificationEnabledProvider), isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getBool(AppConstants.prefOngoingPrayerNotificationEnabled),
      isTrue,
    );
  });
}
