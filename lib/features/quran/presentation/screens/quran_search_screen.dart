import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/ayah_search_result.dart';
import '../../domain/juz_start.dart';
import '../../domain/quran_search_results.dart';
import '../../domain/surah.dart';
import '../providers/quran_providers.dart';
import 'surah_reader_screen.dart';

/// بحث شامل: بالاسم أو رقم السورة، برقم الجزء (١-٣٠)، أو بنص الآية —
/// معروضة في أقسام منظّمة منفصلة بدل قائمة واحدة مبهمة.
class QuranSearchScreen extends ConsumerWidget {
  const QuranSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(quranSearchResultsProvider);
    final query = ref.watch(quranSearchQueryProvider);
    final surahsAsync = ref.watch(surahListProvider);
    final surahNames = surahsAsync.maybeWhen(
      data: (surahs) => {for (final s in surahs) s.id: s.nameAr},
      orElse: () => const <int, String>{},
    );

    return Scaffold(
      appBar: AppBar(title: const Text('البحث في القرآن الكريم')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
            child: TextField(
              autofocus: true,
              textDirection: TextDirection.rtl,
              style: TextStyle(fontSize: 16.sp),
              decoration: InputDecoration(
                hintText: 'اسم سورة، رقم جزء، أو نص آية...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => ref.read(quranSearchQueryProvider.notifier).state = value,
            ),
          ),
          Expanded(
            child: query.trim().isEmpty
                ? const Center(child: Text('اكتب اسم سورة، رقم جزء (١-٣٠)، أو كلمة من آية'))
                : resultsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(child: Text('حدث خطأ أثناء البحث: $error')),
                    data: (results) {
                      if (results.isEmpty) {
                        return const Center(child: Text('لا توجد نتائج مطابقة.'));
                      }
                      return _SearchResultsList(results: results, surahNames: surahNames);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultsList extends StatelessWidget {
  const _SearchResultsList({required this.results, required this.surahNames});

  final QuranSearchResults results;
  final Map<int, String> surahNames;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        if (results.juzMatches.isNotEmpty) ...[
          const _SectionHeader('الأجزاء'),
          ...results.juzMatches.map((j) => _JuzTile(juzStart: j, surahName: surahNames[j.surahId] ?? '')),
        ],
        if (results.surahs.isNotEmpty) ...[
          const _SectionHeader('السور'),
          ...results.surahs.map((s) => _SurahTile(surah: s)),
        ],
        if (results.ayahs.isNotEmpty) ...[
          const _SectionHeader('الآيات'),
          ...results.ayahs.map((a) => _AyahTile(result: a)),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 6.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _JuzTile extends StatelessWidget {
  const _JuzTile({required this.juzStart, required this.surahName});
  final JuzStart juzStart;
  final String surahName;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Text('${juzStart.juz}')),
      title: Text('الجزء ${juzStart.juz}'),
      subtitle: Text('يبدأ من $surahName، الآية ${juzStart.ayahNumber}'),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SurahReaderScreen(
            surahId: juzStart.surahId,
            highlightAyahNumber: juzStart.ayahNumber,
          ),
        ),
      ),
    );
  }
}

class _SurahTile extends StatelessWidget {
  const _SurahTile({required this.surah});
  final Surah surah;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Text('${surah.id}')),
      title: Text(surah.nameAr, style: const TextStyle(fontFamily: 'AmiriQuran')),
      subtitle: Text('${surah.isMeccan ? 'مكية' : 'مدنية'} • ${surah.ayahCount} آية'),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SurahReaderScreen(surahId: surah.id)),
      ),
    );
  }
}

class _AyahTile extends StatelessWidget {
  const _AyahTile({required this.result});
  final AyahSearchResult result;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        result.textUthmani,
        textDirection: TextDirection.rtl,
        style: TextStyle(fontFamily: 'AmiriQuran', fontSize: 17.sp),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text('${result.surahNameAr} : ${result.ayahNumber}'),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SurahReaderScreen(
            surahId: result.surahId,
            highlightAyahNumber: result.ayahNumber,
          ),
        ),
      ),
    );
  }
}
