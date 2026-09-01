import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/settings/custom_color_settings_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/simple_color_picker.dart';

/// شاشة تخصيص ألوان مواقيت الصلاة يدوياً: تحكّم منفصل بلون النصوص العامة،
/// خلفيات البطاقات، لون التاريخ، ولون الأوقات/الساعات - كل ذلك خلف مفتاح
/// تفعيل رئيسي واحد، حتى لا يفقد المستخدم مظهر التطبيق الافتراضي بالخطأ.
class CustomColorsScreen extends ConsumerWidget {
  const CustomColorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(customColorSettingsProvider);
    final notifier = ref.read(customColorSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('تخصيص الألوان')),
      body: ListView(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.palette_outlined),
            title: const Text('تفعيل الألوان المخصصة'),
            subtitle: const Text('عند التعطيل يعود التطبيق لمظهره الافتراضي'),
            value: settings.enabled,
            onChanged: (value) => notifier.setEnabled(value),
          ),
          const Divider(height: 1),
          _ColorRow(
            icon: Icons.text_fields,
            label: 'لون النصوص العامة',
            color: settings.textColor ?? Colors.white,
            enabled: settings.enabled,
            onPick: () async {
              final picked = await showSimpleColorPicker(
                context: context,
                title: 'لون النصوص العامة',
                initialColor: settings.textColor ?? Colors.white,
              );
              if (picked != null) notifier.setTextColor(picked);
            },
            onReset: () => notifier.setTextColor(null),
          ),
          _ColorRow(
            icon: Icons.dashboard_customize_outlined,
            label: 'لون خلفيات البطاقات',
            color: settings.backgroundColor ?? AppColors.primaryDark,
            enabled: settings.enabled,
            onPick: () async {
              final picked = await showSimpleColorPicker(
                context: context,
                title: 'لون خلفيات البطاقات',
                initialColor: settings.backgroundColor ?? AppColors.primaryDark,
              );
              if (picked != null) notifier.setBackgroundColor(picked);
            },
            onReset: () => notifier.setBackgroundColor(null),
          ),
          _ColorRow(
            icon: Icons.calendar_month_outlined,
            label: 'لون التاريخ والأيام',
            color: settings.dateColor ?? AppColors.goldLight,
            enabled: settings.enabled,
            onPick: () async {
              final picked = await showSimpleColorPicker(
                context: context,
                title: 'لون التاريخ والأيام',
                initialColor: settings.dateColor ?? AppColors.goldLight,
              );
              if (picked != null) notifier.setDateColor(picked);
            },
            onReset: () => notifier.setDateColor(null),
          ),
          _ColorRow(
            icon: Icons.access_time,
            label: 'لون الأوقات والساعات',
            color: settings.clockColor ?? AppColors.goldLight,
            enabled: settings.enabled,
            onPick: () async {
              final picked = await showSimpleColorPicker(
                context: context,
                title: 'لون الأوقات والساعات',
                initialColor: settings.clockColor ?? AppColors.goldLight,
              );
              if (picked != null) notifier.setClockColor(picked);
            },
            onReset: () => notifier.setClockColor(null),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: settings.enabled ? () => notifier.resetAll() : null,
              icon: const Icon(Icons.restart_alt),
              label: const Text('إعادة كل الألوان للوضع الافتراضي'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onPick,
    required this.onReset,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onPick;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      enabled: enabled,
      onTap: enabled ? onPick : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (enabled)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'إعادة للافتراضي',
              onPressed: onReset,
            ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black26),
            ),
          ),
        ],
      ),
    );
  }
}
