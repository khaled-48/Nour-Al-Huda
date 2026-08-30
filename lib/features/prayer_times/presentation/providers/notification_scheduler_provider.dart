import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/notification_service.dart';
import '../../../../core/settings/notifications_settings_provider.dart';
import 'prayer_times_provider.dart';

/// يراقب مواقيت الصلاة القادمة (٧ أيام مقدَّماً) وإعداد تفعيل الإشعارات،
/// ويعيد جدولة إشعارات الأذان المحلية تلقائياً كلما تغيّر أيٌّ منهما (موقع
/// جديد، طريقة حساب مختلفة، تعديل يدوي لوقت صلاة، تفعيل/تعطيل الإشعارات).
/// جدولة عدة أيام مقدَّماً (بدل اليوم الحالي فقط) تمنع توقّف الإشعارات إن لم
/// يُفتح التطبيق يومياً؛ يكفي مراقبة هذا المزوّد مرة واحدة من جذر التطبيق.
final notificationSchedulerProvider = Provider<void>((ref) {
  final notificationsEnabled = ref.watch(notificationsEnabledProvider);
  final upcomingAsync = ref.watch(upcomingPrayerTimesProvider);

  if (!notificationsEnabled) {
    NotificationService.instance.cancelAll();
    return;
  }

  upcomingAsync.whenData((days) {
    NotificationService.instance.scheduleUpcomingAdhan(days);
  });
});
