import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../providers/quran_reader_settings_provider.dart';

/// شريط زخرفي هادئ لاسم السورة أعلى صفحة القراءة، مستوحى من شريط اسم
/// السورة في المصحف الشريف لكن بلون مكتوم واحد بدل الألوان الصاخبة
/// المعتادة، حتى يبقى التركيز على النص لا على الزخرفة.
class SurahNameBanner extends ConsumerWidget {
  const SurahNameBanner({super.key, required this.surahName});

  final String surahName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(quranReaderSettingsProvider).resolveFor(Theme.of(context).brightness);
    final lineColor = settings.accentColor.withValues(alpha: 0.5);

    return Padding(
      padding: EdgeInsets.only(bottom: 22.h),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: lineColor), bottom: BorderSide(color: lineColor)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('❊', style: TextStyle(color: settings.accentColor, fontSize: 14.sp)),
            SizedBox(width: 12.w),
            Text(
              surahName,
              style: TextStyle(
                fontFamily: 'AmiriQuran',
                fontSize: 22.sp * settings.fontScale,
                color: settings.accentColor,
              ),
            ),
            SizedBox(width: 12.w),
            Text('❊', style: TextStyle(color: settings.accentColor, fontSize: 14.sp)),
          ],
        ),
      ),
    );
  }
}
