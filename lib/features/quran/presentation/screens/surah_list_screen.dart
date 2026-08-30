import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/islamic_pattern_background.dart';
import '../../domain/quran_bookmark.dart';
import '../../domain/surah.dart';
import '../providers/quran_bookmarks_provider.dart';
import '../providers/quran_providers.dart';
import 'quran_bookmarks_screen.dart';
import 'quran_search_screen.dart';
import 'surah_reader_screen.dart';

class SurahListScreen extends ConsumerWidget {
  const SurahListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahsAsync = ref.watch(surahListProvider);
    final lastBookmark = ref.watch(lastQuranBookmarkProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('القرآن الكريم'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            tooltip: 'العلامات المرجعية',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const QuranBookmarksScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'بحث',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const QuranSearchScreen()),
            ),
          ),
        ],
      ),
      body: IslamicPatternBackground(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        patternColor: AppColors.gold,
        child: surahsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Center(child: Text('تعذّر تحميل القرآن الكريم: $error')),
          data: (surahs) => LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 900
                  ? 3
                  : constraints.maxWidth >= 600
                  ? 2
                  : 1;
              return Column(
                children: [
                  if (lastBookmark != null)
                    Padding(
                      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 0),
                      child: _ContinueReadingBanner(bookmark: lastBookmark),
                    ),
                  Expanded(
                    child: GridView.builder(
                      padding: EdgeInsets.all(12.w),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        // نستخدم .w (مقياس العرض) بدل .h هنا عمداً — نص
                        // البطاقة يُحجَّم بـ .sp الذي يتبع مقياس العرض أيضاً؛
                        // لو استُخدم .h (مقياس الارتفاع) بدلاً منه، يختلف
                        // المقياسان عند أي نسبة عرض إلى ارتفاع غير معتادة
                        // (تابلت أفقي مثلاً) فيفيض النص فوق ارتفاع الخلية.
                        mainAxisExtent: 90.w,
                        crossAxisSpacing: 10.w,
                        mainAxisSpacing: 10.h,
                      ),
                      itemCount: surahs.length,
                      itemBuilder: (context, index) =>
                          _SurahListTile(surah: surahs[index]),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ContinueReadingBanner extends StatelessWidget {
  const _ContinueReadingBanner({required this.bookmark});

  final QuranBookmark bookmark;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.primary.withValues(alpha: 0.08),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.r),
        side: BorderSide(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: ListTile(
        leading: Icon(Icons.menu_book, color: colorScheme.primary),
        title: const Text('متابعة القراءة'),
        subtitle: Text(
          '${bookmark.surahNameAr} — الآية ${bookmark.ayahNumber}',
        ),
        trailing: const Icon(Icons.arrow_back_ios, size: 14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SurahReaderScreen(
              surahId: bookmark.surahId,
              highlightAyahNumber: bookmark.ayahNumber,
            ),
          ),
        ),
      ),
    );
  }
}

class _SurahListTile extends StatelessWidget {
  const _SurahListTile({required this.surah});

  final Surah surah;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 1.5,
      shadowColor: AppColors.gold.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SurahReaderScreen(surahId: surah.id),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
          ),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          child: Row(
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold.withValues(alpha: 0.14),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  '${surah.id}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      surah.nameAr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'AmiriQuran',
                        fontSize: 17.sp,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${surah.isMeccan ? 'مكية' : 'مدنية'} • ${surah.ayahCount} آية',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.sp,
                        height: 1.2,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                surah.isMeccan
                    ? Icons.change_history_outlined
                    : Icons.mosque_outlined,
                color: AppColors.gold,
                size: 18.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
