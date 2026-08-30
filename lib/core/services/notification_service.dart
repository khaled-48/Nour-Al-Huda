import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../features/prayer_times/domain/daily_prayer_times.dart';

/// يدير جدولة إشعارات الأذان المحلية (بدون إنترنت) عبر flutter_local_notifications.
/// يُهيَّأ مرة واحدة عند إقلاع التطبيق، ثم يُعاد جدولة إشعارات اليوم كلما
/// تغيّرت مواقيت الصلاة (تغيّر الموقع، أو طريقة الحساب، أو يوم جديد).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'adhan_channel';
  static const _channelName = 'تنبيهات الأذان';
  static const _channelDescription = 'تنبيه صوتي عند دخول وقت كل صلاة';

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    final timezoneName = (await FlutterTimezone.getLocalTimezone()).identifier;
    tz.setLocalLocation(tz.getLocation(timezoneName));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: androidInit));

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();

    _initialized = true;
  }

  /// معرّف فريد لكل إشعار عبر مزيج (اليوم × الصلاة)، حتى لا تتصادم إشعارات
  /// نفس الصلاة في أيام مختلفة عند جدولة عدة أيام مسبقاً.
  int _notificationIdFor(int dayOffset, PrayerName prayer) => dayOffset * 10 + prayer.index;

  /// يُلغي كل الإشعارات المجدولة سابقاً، ثم يجدول أذان كل صلاة قادمة ضمن
  /// [upcomingDays] (الشروق مستثنى لأنه ليس أذاناً). تمرير عدة أيام مقدَّماً
  /// (وليس اليوم الحالي فقط) يضمن استمرار الإشعارات حتى لو لم يُفتح التطبيق
  /// يومياً — طالما أنه يُفتح مرة واحدة على الأقل خلال تلك الفترة لتُمدَّد
  /// الجدولة من جديد.
  Future<void> scheduleUpcomingAdhan(List<DailyPrayerTimes> upcomingDays) async {
    await _plugin.cancelAll();
    final now = DateTime.now();

    for (var dayOffset = 0; dayOffset < upcomingDays.length; dayOffset++) {
      final times = upcomingDays[dayOffset];
      for (final prayer in PrayerName.values) {
        if (!prayer.hasIqamah) continue;
        final time = times.timeOf(prayer);
        if (!time.isAfter(now)) continue;

        await _plugin.zonedSchedule(
          _notificationIdFor(dayOffset, prayer),
          'حان الآن وقت أذان ${prayer.arabicLabel}',
          'حي على الصلاة، حي على الفلاح',
          tz.TZDateTime.from(time, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDescription,
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();
}
