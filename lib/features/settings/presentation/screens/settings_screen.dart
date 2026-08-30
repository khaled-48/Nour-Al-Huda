import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/settings/notifications_settings_provider.dart';
import '../../../../core/settings/numeral_style.dart';
import '../../../../core/settings/numeral_style_provider.dart';
import '../../../../core/settings/time_format_option.dart';
import '../../../../core/settings/time_format_provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/single_choice_dialog.dart';
import '../../../prayer_times/domain/daily_prayer_times.dart';
import '../../../prayer_times/domain/prayer_calculation_settings.dart';
import '../../../prayer_times/presentation/providers/location_provider.dart';
import '../../../prayer_times/presentation/providers/prayer_settings_provider.dart';
import '../../../prayer_times/presentation/widgets/edit_iqamah_offset_dialog.dart';

String _themeModeLabel(ThemeMode mode) => switch (mode) {
      ThemeMode.system => 'حسب النظام',
      ThemeMode.light => 'فاتح',
      ThemeMode.dark => 'داكن',
    };

String _madhabLabel(Madhab madhab) =>
    madhab == Madhab.shafi ? 'شافعي/مالكي/حنبلي (الظل مثل الشيء)' : 'حنفي (الظل مثلي الشيء)';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final timeFormat = ref.watch(timeFormatProvider);
    final numeralStyle = ref.watch(numeralStyleProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final prayerSettings = ref.watch(prayerSettingsProvider);
    final iqamahOffsets = ref.watch(iqamahOffsetsProvider);
    final locationAsync = ref.watch(locationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        children: [
          const _SectionHeader('المظهر'),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('وضع العرض'),
            subtitle: Text(_themeModeLabel(themeMode)),
            onTap: () async {
              final selected = await showSingleChoiceDialog<ThemeMode>(
                context: context,
                title: 'وضع العرض',
                options: ThemeMode.values,
                labelBuilder: _themeModeLabel,
                currentValue: themeMode,
              );
              if (selected != null) {
                ref.read(themeModeProvider.notifier).setThemeMode(selected);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.access_time_outlined),
            title: const Text('تنسيق الوقت'),
            subtitle: Text(timeFormat.arabicLabel),
            onTap: () async {
              final selected = await showSingleChoiceDialog<TimeFormatOption>(
                context: context,
                title: 'تنسيق الوقت',
                options: TimeFormatOption.values,
                labelBuilder: (option) => option.arabicLabel,
                currentValue: timeFormat,
              );
              if (selected != null) {
                ref.read(timeFormatProvider.notifier).setFormat(selected);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.pin_outlined),
            title: const Text('نظام الأرقام'),
            subtitle: Text(numeralStyle.arabicLabel),
            onTap: () async {
              final selected = await showSingleChoiceDialog<NumeralStyle>(
                context: context,
                title: 'نظام الأرقام',
                options: NumeralStyle.values,
                labelBuilder: (option) => option.arabicLabel,
                currentValue: numeralStyle,
              );
              if (selected != null) {
                ref.read(numeralStyleProvider.notifier).setStyle(selected);
              }
            },
          ),
          const Divider(height: 1),
          const _SectionHeader('الإشعارات'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('تنبيه الأذان'),
            subtitle: const Text('إشعار محلي عند دخول وقت كل صلاة'),
            value: notificationsEnabled,
            onChanged: (value) =>
                ref.read(notificationsEnabledProvider.notifier).setEnabled(value),
          ),
          const Divider(height: 1),
          const _SectionHeader('مواقيت الصلاة'),
          ListTile(
            leading: const Icon(Icons.calculate_outlined),
            title: const Text('طريقة حساب المواقيت'),
            subtitle: Text(prayerSettings.method.arabicLabel),
            onTap: () async {
              final selected = await showSingleChoiceDialog<PrayerCalculationMethodOption>(
                context: context,
                title: 'طريقة حساب المواقيت',
                options: PrayerCalculationMethodOption.values,
                labelBuilder: (option) => option.arabicLabel,
                currentValue: prayerSettings.method,
              );
              if (selected != null) {
                ref.read(prayerSettingsProvider.notifier).setMethod(selected);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.mosque_outlined),
            title: const Text('المذهب الفقهي (حساب صلاة العصر)'),
            subtitle: Text(_madhabLabel(prayerSettings.madhab)),
            onTap: () async {
              final selected = await showSingleChoiceDialog<Madhab>(
                context: context,
                title: 'المذهب الفقهي',
                options: Madhab.values,
                labelBuilder: _madhabLabel,
                currentValue: prayerSettings.madhab,
              );
              if (selected != null) {
                ref.read(prayerSettingsProvider.notifier).setMadhab(selected);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.my_location_outlined),
            title: const Text('الموقع الجغرافي'),
            subtitle: Text(
              locationAsync.when(
                data: (pos) =>
                    'خط العرض ${pos.latitude.toStringAsFixed(3)}، خط الطول ${pos.longitude.toStringAsFixed(3)}',
                loading: () => 'جارٍ التحديد...',
                error: (_, _) => 'غير متاح',
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.read(locationProvider.notifier).refresh(),
            ),
          ),
          const Divider(height: 1),
          const _SectionHeader('مواعيد الإقامة بعد الأذان'),
          ...PrayerName.values.where((p) => p.hasIqamah).map((prayer) {
            final minutes = iqamahOffsets[prayer] ?? 0;
            return ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: Text(prayer.arabicLabel),
              subtitle: Text('بعد الأذان بـ $minutes دقيقة'),
              onTap: () async {
                final newValue = await showEditIqamahOffsetDialog(
                  context: context,
                  prayer: prayer,
                  currentMinutes: minutes,
                );
                if (newValue != null) {
                  ref.read(iqamahOffsetsProvider.notifier).setOffset(prayer, newValue);
                }
              },
            );
          }),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
