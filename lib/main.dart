import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/navigation/root_shell.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/prayer_times/presentation/providers/notification_scheduler_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar');
  HijriCalendar.setLocal('ar');
  await NotificationService.instance.initialize();
  runApp(const ProviderScope(child: IslamicApp()));
}

class IslamicApp extends ConsumerWidget {
  const IslamicApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    // مراقبته هنا يكفي لتفعيل إعادة جدولة إشعارات الأذان تلقائياً طوال عمر التطبيق.
    ref.watch(notificationSchedulerProvider);

    // مقاس تصميم مرجعي (هاتف متوسط)، ScreenUtil يتكفّل بالتحجيم
    // على التابلت والشاشات الكبيرة تلقائياً.
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'مُصْحَفْ وَأَذْكَارْ',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, widget) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: widget!,
            );
          },
          home: const RootShell(),
        );
      },
    );
  }
}
