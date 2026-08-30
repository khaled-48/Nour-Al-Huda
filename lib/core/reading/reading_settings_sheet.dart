import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'hsl_color_picker.dart';
import 'reading_settings.dart';
import 'reading_settings_notifier.dart';

/// لوحة إعدادات قراءة عامة (حجم الخط، ألوان جاهزة، ومنتقي ألوان حر)،
/// تعمل مع أي [StateNotifierProvider] لإعدادات قراءة — تُستخدم لشاشتي
/// قراءة القرآن والأذكار معاً بنفس الكود.
Future<void> showReadingSettingsSheet(
  BuildContext context, {
  required StateNotifierProvider<ReadingSettingsNotifier, ReadingSettings> provider,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ReadingSettingsSheet(provider: provider),
  );
}

class _Preset {
  const _Preset(this.name, this.background, this.text);
  final String name;
  final Color background;
  final Color text;
}

const _presets = [
  _Preset('ورقي', Color(0xFFFBF3E1), Color(0xFF3A362E)),
  _Preset('أبيض', Color(0xFFFFFFFF), Color(0xFF1B1B1B)),
  _Preset('سيبيا', Color(0xFFEFE0C4), Color(0xFF4A3B24)),
  _Preset('رمادي داكن', Color(0xFF23262B), Color(0xFFE7E3D8)),
  _Preset('أسود', Color(0xFF000000), Color(0xFFDCD6C4)),
];

class _ReadingSettingsSheet extends ConsumerWidget {
  const _ReadingSettingsSheet({required this.provider});

  final StateNotifierProvider<ReadingSettingsNotifier, ReadingSettings> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawSettings = ref.watch(provider);
    final settings = rawSettings.resolveFor(Theme.of(context).brightness);
    final notifier = ref.read(provider.notifier);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'إعدادات القراءة',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 18.h),

            Text('حجم الخط', style: TextStyle(fontSize: 13.sp)),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.text_decrease),
                  onPressed: () => notifier.setFontScale(settings.fontScale - 0.1),
                ),
                Expanded(
                  child: Slider(
                    value: settings.fontScale,
                    min: ReadingSettings.minFontScale,
                    max: ReadingSettings.maxFontScale,
                    divisions: 11,
                    label: '${(settings.fontScale * 100).round()}٪',
                    onChanged: notifier.setFontScale,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.text_increase),
                  onPressed: () => notifier.setFontScale(settings.fontScale + 0.1),
                ),
              ],
            ),

            SizedBox(height: 8.h),
            Text('ألوان جاهزة', style: TextStyle(fontSize: 13.sp)),
            SizedBox(height: 10.h),
            Wrap(
              spacing: 14.w,
              runSpacing: 12.h,
              children: _presets.map((preset) {
                final isSelected = settings.backgroundColor.toARGB32() == preset.background.toARGB32() &&
                    settings.textColor.toARGB32() == preset.text.toARGB32();
                return GestureDetector(
                  onTap: () => notifier.applyPreset(background: preset.background, text: preset.text),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44.w,
                        height: 44.w,
                        decoration: BoxDecoration(
                          color: preset.background,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black26,
                            width: isSelected ? 2.5 : 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'أ',
                          style: TextStyle(color: preset.text, fontWeight: FontWeight.bold, fontSize: 16.sp),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(preset.name, style: TextStyle(fontSize: 10.sp)),
                    ],
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: 18.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.palette_outlined),
                    label: const Text('لون الخلفية'),
                    onPressed: () => _openColorPicker(
                      context,
                      title: 'لون الخلفية',
                      initialColor: settings.backgroundColor,
                      onChanged: (color) =>
                          notifier.setColors(background: color, text: settings.textColor),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.format_color_text_outlined),
                    label: const Text('لون النص'),
                    onPressed: () => _openColorPicker(
                      context,
                      title: 'لون النص',
                      initialColor: settings.textColor,
                      onChanged: (color) =>
                          notifier.setColors(background: settings.backgroundColor, text: color),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 10.h),
            TextButton(
              onPressed: notifier.resetToDefaults,
              child: const Text('استعادة الإعداد الافتراضي'),
            ),
          ],
        ),
      ),
    );
  }

  void _openColorPicker(
    BuildContext context, {
    required String title,
    required Color initialColor,
    required ValueChanged<Color> onChanged,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 320,
          child: HslColorPicker(initialColor: initialColor, onChanged: onChanged),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('تم')),
        ],
      ),
    );
  }
}
