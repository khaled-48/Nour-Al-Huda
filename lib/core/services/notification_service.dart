import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../features/prayer_times/domain/daily_prayer_times.dart';
import '../settings/time_format_option.dart';
import '../utils/time_formatters.dart';

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

  static const _ongoingChannelId = 'ongoing_next_prayer_channel';
  static const _ongoingChannelName = 'إشعار الصلاة القادمة';
  static const _ongoingChannelDescription =
      'إشعار دائم يعرض اسم الصلاة القادمة ووقتها';
  // بعيد عن مدى _notificationIdFor (٦٤ كحد أقصى: dayOffset*10 + prayer.index
  // لسبعة أيام × ٥ صلوات) حتى لا يتصادم معه أبداً.
  static const _ongoingNotificationId = 999001;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    final timezoneName = (await FlutterTimezone.getLocalTimezone()).identifier;
    tz.setLocalLocation(tz.getLocation(timezoneName));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: androidInit),
    );

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();

    _initialized = true;
  }

  /// معرّف فريد لكل إشعار عبر مزيج (اليوم × الصلاة)، حتى لا تتصادم إشعارات
  /// نفس الصلاة في أيام مختلفة عند جدولة عدة أيام مسبقاً.
  int _notificationIdFor(int dayOffset, PrayerName prayer) =>
      dayOffset * 10 + prayer.index;

  /// يُلغي كل الإشعارات المجدولة سابقاً، ثم يجدول أذان كل صلاة قادمة ضمن
  /// [upcomingDays] (الشروق مستثنى لأنه ليس أذاناً). تمرير عدة أيام مقدَّماً
  /// (وليس اليوم الحالي فقط) يضمن استمرار الإشعارات حتى لو لم يُفتح التطبيق
  /// يومياً — طالما أنه يُفتح مرة واحدة على الأقل خلال تلك الفترة لتُمدَّد
  /// الجدولة من جديد.
  Future<void> scheduleUpcomingAdhan(
    List<DailyPrayerTimes> upcomingDays,
  ) async {
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
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  AndroidNotificationDetails _ongoingDetails() =>
      const AndroidNotificationDetails(
        _ongoingChannelId,
        _ongoingChannelName,
        channelDescription: _ongoingChannelDescription,
        ongoing: true,
        autoCancel: false,
        showWhen: false,
        playSound: false,
        enableVibration: false,
        importance: Importance.low,
        priority: Priority.low,
        category: AndroidNotificationCategory.status,
      );

  String _ongoingBody(PrayerOccurrence occurrence) {
    final (prayer, time) = occurrence;
    final formatted = TimeFormatters.time(time, TimeFormatOption.h24);
    return 'الصلاة القادمة: ${prayer.arabicLabel} — $formatted';
  }

  /// يعرض/يحدّث فوراً (بلا انتظار جدولة) إشعاراً دائماً بالصلاة القادمة
  /// بالنسبة للحظة الاستدعاء، أو يُلغيه إن [enabled] كانت false. يُستدعى
  /// عند كل فتح للتطبيق حتى لا تبقى البطاقة قديمة إن لم يُفتح التطبيق منذ
  /// فترة.
  Future<void> updateOngoingNextPrayerNotification(
    DailyPrayerTimes today, {
    required bool enabled,
  }) async {
    if (!enabled) {
      await _plugin.cancel(_ongoingNotificationId);
      return;
    }
    final occurrence = today.nextPrayer(DateTime.now());
    await _plugin.show(
      _ongoingNotificationId,
      'الصلاة القادمة',
      _ongoingBody(occurrence),
      NotificationDetails(android: _ongoingDetails()),
    );
  }

  /// يسلّح تحديثاً مستقبلياً واحداً فقط للإشعار الدائم، عند حلول وقت الصلاة
  /// القادمة الحالية بالضبط (فتصبح عندها "الصلاة التي تليها" هي القادمة).
  /// لا يمكن تسليح أكثر من خطوة واحدة تحت نفس المعرّف الثابت: كل جدولة
  /// جديدة لنفس المعرّف تُلغي سابقتها (PendingIntent بنفس الرقم)، فتسلسل
  /// كامل عبر عدة صلوات متتالية والتطبيق مغلق طوال الوقت غير مدعوم عمداً.
  Future<void> scheduleOngoingNextPrayerBoundary(
    List<DailyPrayerTimes> upcomingDays, {
    required bool enabled,
  }) async {
    if (!enabled) return;

    final now = DateTime.now();
    final occurrences = <PrayerOccurrence>[];
    for (final day in upcomingDays) {
      for (final prayer in PrayerName.values) {
        if (!prayer.hasIqamah) continue;
        final time = day.timeOf(prayer);
        if (time.isAfter(now)) occurrences.add((prayer, time));
      }
    }
    if (occurrences.length < 2) return;

    final current = occurrences[0];
    final following = occurrences[1];
    await _plugin.zonedSchedule(
      _ongoingNotificationId,
      'الصلاة القادمة',
      _ongoingBody(following),
      tz.TZDateTime.from(current.$2, tz.local),
      NotificationDetails(android: _ongoingDetails()),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
