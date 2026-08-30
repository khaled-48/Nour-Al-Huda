import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../providers/quran_bookmarks_provider.dart';
import '../providers/quran_providers.dart';

/// يعرض التفسير الميسر لآية واحدة في قائمة سفلية (Bottom Sheet)، محلياً
/// وفورياً دون إنترنت، مع زرّ لوضع علامة مرجعية على الآية لمتابعة القراءة
/// منها لاحقاً.
Future<void> showTafsirSheet({
  required BuildContext context,
  required int surahId,
  required String surahNameAr,
  required int ayahNumber,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _TafsirSheetContent(
      surahId: surahId,
      surahNameAr: surahNameAr,
      ayahNumber: ayahNumber,
    ),
  );
}

class _TafsirSheetContent extends ConsumerWidget {
  const _TafsirSheetContent({
    required this.surahId,
    required this.surahNameAr,
    required this.ayahNumber,
  });

  final int surahId;
  final String surahNameAr;
  final int ayahNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tafsirAsync = ref.watch(tafsirForSurahProvider(surahId));
    final bookmarks = ref.watch(quranBookmarksProvider);
    final isBookmarked = bookmarks.any((b) => b.surahId == surahId && b.ayahNumber == ayahNumber);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Spacer(),
                Expanded(
                  flex: 6,
                  child: Text(
                    'التفسير الميسر — $surahNameAr: $ayahNumber',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: IconButton(
                    tooltip: isBookmarked ? 'إزالة العلامة' : 'ضع علامة لمتابعة القراءة',
                    icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border),
                    color: Theme.of(context).colorScheme.secondary,
                    onPressed: () => ref.read(quranBookmarksProvider.notifier).toggle(
                          surahId: surahId,
                          ayahNumber: ayahNumber,
                          surahNameAr: surahNameAr,
                        ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 0.5.sh),
              child: SingleChildScrollView(
                child: tafsirAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) => const Text('تعذّر عرض التفسير.'),
                  data: (tafsirByAyah) => Text(
                    tafsirByAyah[ayahNumber] ?? 'لا يتوفر تفسير لهذه الآية.',
                    textAlign: TextAlign.justify,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, height: 1.9),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
