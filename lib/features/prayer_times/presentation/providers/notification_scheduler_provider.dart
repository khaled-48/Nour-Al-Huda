import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/notification_service.dart';
import '../../../../core/settings/notifications_settings_provider.dart';
import '../../../../core/settings/ongoing_notification_settings_provider.dart';
import 'prayer_times_provider.dart';

/// يراقب مواقيت الصلاة القادمة (٧ أيام مقدَّماً) وإعدادي تفعيل إشعار الأذان
/// والإشعار الدائم بالصلاة القادمة، ويعيد جدولة كل منهما تلقائياً كلما تغيّر
/// أيٌّ منهما (موقع جديد، طريقة حساب مختلفة، تعديل يدوي لوقت صلاة، تفعيل/
/// تعطيل أي من الإشعارين). المفتاحان مستقلان تماماً: تعطيل تنبيه الأذان لا
/// يوقف الإشعار الدائم والعكس صحيح. جدولة عدة أيام مقدَّماً (بدل اليوم
/// الحالي فقط) تمنع توقّف الإشعارات إن لم يُفتح التطبيق يومياً؛ يكفي مراقبة
/// هذا المزوّد مرة واحدة من جذر التطبيق.
final notificationSchedulerProvider = Provider<void>((ref) {
  final notificationsEnabled = ref.watch(notificationsEnabledProvider);
  final ongoingEnabled = ref.watch(ongoingPrayerNotificationEnabledProvider);
  final upcomingAsync = ref.watch(upcomingPrayerTimesProvider);

  upcomingAsync.whenData((days) async {
    if (notificationsEnabled) {
      await NotificationService.instance.scheduleUpcomingAdhan(days);
    } else {
      await NotificationService.instance.cancelAll();
    }
    // تُستدعى دوماً بعد فرع الأذان أياً كانت نتيجته: scheduleUpcomingAdhan
    // تبدأ بإلغاء شامل يمسح أي تسليح سابق للإشعار الدائم أيضاً، فتُعيدان
    // هاتان الدالتان تأسيسه (أو إبقاءه ملغى) بشكل صحيح مهما كان ترتيب
    // تغيّر المفتاحين.
    await NotificationService.instance.updateOngoingNextPrayerNotification(
      days.first,
      enabled: ongoingEnabled,
    );
    await NotificationService.instance.scheduleOngoingNextPrayerBoundary(
      days,
      enabled: ongoingEnabled,
    );
  });
});
