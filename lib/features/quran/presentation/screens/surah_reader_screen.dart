import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/reading/reading_settings_sheet.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gold_gradient_frame.dart';
import '../../../../core/widgets/gold_icon_button.dart';
import '../../../../core/widgets/ornate_divider.dart';
import '../providers/quran_bookmarks_provider.dart';
import '../providers/quran_providers.dart';
import '../providers/quran_reader_settings_provider.dart';
import '../widgets/surah_name_banner.dart';
import '../widgets/surah_text.dart';
import '../widgets/tafsir_sheet.dart';
import 'quran_bookmarks_screen.dart';
import 'quran_search_screen.dart';

/// شاشة قراءة القرآن: صفحة لكل سورة (114 صفحة)، يمكن التنقّل بينها بالسحب
/// يميناً ويساراً (PageView) تماماً كتقليب صفحات المصحف. آيات كل سورة فقرة
/// عربية واحدة متصلة ومستمرة بلا بطاقات أو حدود، على خلفية وبألوان وحجم
/// خط يختارها المستخدم بحرية من إعدادات القراءة (أيقونة الضبط بالأعلى).
///
/// السحب مقصود أن يبقى خفيفاً: لا نُحمِّل الصفحة المجاورة مسبقاً
/// (`allowImplicitScrolling: false`) حتى لا تُبنى فقرة سورة كاملة أثناء
/// الإيماءة نفسها، وكل صفحة مُغلَّفة بـ RepaintBoundary لعزل إعادة الرسم.
class SurahReaderScreen extends ConsumerStatefulWidget {
  const SurahReaderScreen({
    super.key,
    required this.surahId,
    this.highlightAyahNumber,
  });

  final int surahId;
  final int? highlightAyahNumber;

  @override
  ConsumerState<SurahReaderScreen> createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends ConsumerState<SurahReaderScreen> {
  late final PageController _pageController;
  late int _currentSurahId;

  @override
  void initState() {
    super.initState();
    _currentSurahId = widget.surahId;
    _pageController = PageController(initialPage: widget.surahId - 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings =
        ref.watch(quranReaderSettingsProvider).resolveFor(Theme.of(context).brightness);
    final surahAsync = ref.watch(surahListProvider);
    final currentAyahsAsync = ref.watch(ayahsForSurahProvider(_currentSurahId));

    final currentSurahName = surahAsync.maybeWhen(
      data: (surahs) =>
          surahs.firstWhere((s) => s.id == _currentSurahId).nameAr,
      orElse: () => '...',
    );
    final juzLabel = currentAyahsAsync.maybeWhen(
      data: (ayahs) => ayahs.isEmpty ? null : 'الجزء ${ayahs.first.juz}',
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(currentSurahName, style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 18)),
            if (juzLabel != null)
              Text(
                juzLabel,
                style: TextStyle(fontSize: 10.sp, color: Colors.white.withValues(alpha: 0.8)),
              ),
          ],
        ),
        actions: [
          GoldIconButton(
            icon: Icons.search,
            tooltip: 'البحث',
            color: AppColors.goldLight,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const QuranSearchScreen()),
            ),
          ),
          GoldIconButton(
            icon: Icons.bookmark_border,
            tooltip: 'العلامات المرجعية',
            color: AppColors.goldLight,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const QuranBookmarksScreen()),
            ),
          ),
          GoldIconButton(
            icon: Icons.text_fields,
            tooltip: 'حجم الخط والألوان',
            color: AppColors.goldLight,
            onPressed: () => showReadingSettingsSheet(
              context,
              provider: quranReaderSettingsProvider,
            ),
          ),
          SizedBox(width: 4.w),
        ],
      ),
      backgroundColor: settings.backgroundColor,
      body: PageView.builder(
        controller: _pageController,
        itemCount: 114,
        onPageChanged: (index) => setState(() => _currentSurahId = index + 1),
        itemBuilder: (context, index) {
          final surahId = index + 1;
          return RepaintBoundary(
            child: _SurahPage(
              surahId: surahId,
              highlightAyahNumber: surahId == widget.surahId
                  ? widget.highlightAyahNumber
                  : null,
            ),
          );
        },
      ),
    );
  }
}

class _SurahPage extends ConsumerStatefulWidget {
  const _SurahPage({required this.surahId, this.highlightAyahNumber});

  final int surahId;
  final int? highlightAyahNumber;

  @override
  ConsumerState<_SurahPage> createState() => _SurahPageState();
}

class _SurahPageState extends ConsumerState<_SurahPage> {
  final GlobalKey _highlightAnchorKey = GlobalKey();
  bool _didScrollToHighlight = false;

  void _maybeScrollToHighlight() {
    if (_didScrollToHighlight || widget.highlightAyahNumber == null) return;
    final anchorContext = _highlightAnchorKey.currentContext;
    if (anchorContext == null) return;
    _didScrollToHighlight = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Scrollable.ensureVisible(
        anchorContext,
        duration: const Duration(milliseconds: 300),
        alignment: 0.1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings =
        ref.watch(quranReaderSettingsProvider).resolveFor(Theme.of(context).brightness);
    final surahAsync = ref.watch(surahListProvider);
    final ayahsAsync = ref.watch(ayahsForSurahProvider(widget.surahId));
    final bookmarks = ref.watch(quranBookmarksProvider);

    final surahName = surahAsync.maybeWhen(
      data: (surahs) => surahs.firstWhere((s) => s.id == widget.surahId).nameAr,
      orElse: () => '...',
    );

    return ayahsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('تعذّر تحميل السورة: $error')),
      data: (ayahs) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _maybeScrollToHighlight(),
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth >= 700
                ? 700.0
                : constraints.maxWidth;
            return Padding(
              padding: EdgeInsets.all(10.w),
              child: Center(
                child: SizedBox(
                  width: maxWidth,
                  child: GoldGradientFrame(
                    backgroundColor: settings.backgroundColor,
                    goldColor: settings.accentColor,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18.w,
                        vertical: 14.h,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OrnateDivider(color: settings.accentColor),
                          SizedBox(height: 8.h),
                          SurahNameBanner(surahName: surahName),
                          SurahText(
                            ayahs: ayahs,
                            highlightAyahNumber: widget.highlightAyahNumber,
                            highlightAnchorKey:
                                widget.highlightAyahNumber == null
                                ? null
                                : _highlightAnchorKey,
                            isAyahBookmarked: (ayahNumber) => bookmarks.any(
                              (b) =>
                                  b.surahId == widget.surahId &&
                                  b.ayahNumber == ayahNumber,
                            ),
                            onAyahTap: (ayahNumber) => showTafsirSheet(
                              context: context,
                              surahId: widget.surahId,
                              surahNameAr: surahName,
                              ayahNumber: ayahNumber,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          OrnateDivider(color: settings.accentColor),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
