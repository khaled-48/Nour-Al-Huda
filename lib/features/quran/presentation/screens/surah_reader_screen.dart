import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/reading/reading_settings_sheet.dart';
import '../../../../core/settings/numeral_style_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/juz_names.dart';
import '../../../../core/utils/numeral_formatter.dart';
import '../../../../core/utils/qpc_font_loader.dart';
import '../../../../core/widgets/gold_icon_button.dart';
import '../../../../core/widgets/ornate_page_frame.dart';
import '../providers/quran_bookmarks_provider.dart';
import '../providers/quran_providers.dart';
import '../providers/quran_reader_settings_provider.dart';
import '../widgets/page_curl_view.dart';
import '../widgets/qpc_mushaf_page.dart';
import '../widgets/quran_reader_toolbar.dart';
import '../widgets/tafsir_sheet.dart';
import 'quran_bookmarks_screen.dart';
import 'quran_search_screen.dart';

/// شاشة قراءة القرآن: صفحة مصحفية حقيقية لكل صفحة من صفحات مصحف المدينة
/// المطبعي القياسي الـ 604 (نفس ترقيم الصفحة/الجزء المعتمد)، يمكن التنقّل
/// بينها بالسحب يميناً ويساراً بتأثير طيّ ورقي واقعي ([PageCurlView]) يحاكي
/// تقليب صفحات المصحف الحقيقي. الصفحة الواحدة قد تمتد عبر أكثر من سورة إذا
/// بدأت سورة جديدة وسطها (كصفحات نهاية جزء عمّ مثلاً)، فتُعرض كل سورة
/// بعنوانها الخاص وسط الصفحة، على خلفية وبألوان وحجم خط يختارها المستخدم
/// بحرية من إعدادات القراءة.
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
  int? _currentPage;
  int? _currentSurahId;
  bool _immersive = false;

  void _toggleImmersive() => setState(() => _immersive = !_immersive);

  int get _targetSurahId => _currentSurahId ?? widget.surahId;

  void _onSave(String surahNameAr) {
    final surahId = _targetSurahId;
    ref
        .read(quranBookmarksProvider.notifier)
        .toggle(surahId: surahId, ayahNumber: 1, surahNameAr: surahNameAr);
    final isBookmarked = ref
        .read(quranBookmarksProvider)
        .any((b) => b.surahId == surahId && b.ayahNumber == 1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isBookmarked ? 'تم حفظ موضع القراءة' : 'تمت إزالة الحفظ'),
      ),
    );
  }

  void _onShare(String surahNameAr) {
    Clipboard.setData(ClipboardData(text: 'سورة $surahNameAr - القرآن الكريم'));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم نسخ اسم السورة للمشاركة')));
  }

  void _onTafsir(String surahNameAr) {
    showTafsirSheet(
      context: context,
      surahId: _targetSurahId,
      surahNameAr: surahNameAr,
      ayahNumber: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialAyahsAsync = ref.watch(ayahsForSurahProvider(widget.surahId));

    return initialAyahsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) =>
          Scaffold(body: Center(child: Text('تعذّر تحميل السورة: $error'))),
      data: (ayahs) {
        final targetAyah = ayahs.firstWhere(
          (a) => a.ayahNumber == (widget.highlightAyahNumber ?? 1),
          orElse: () => ayahs.first,
        );
        _currentPage ??= targetAyah.page;
        _currentSurahId ??= widget.surahId;
        return _buildReader(context, initialPage: targetAyah.page);
      },
    );
  }

  Widget _buildReader(BuildContext context, {required int initialPage}) {
    final settings = ref
        .watch(quranReaderSettingsProvider)
        .resolveFor(Theme.of(context).brightness);
    final bookmarks = ref.watch(quranBookmarksProvider);
    final surahAsync = ref.watch(surahListProvider);

    final currentSurahName = surahAsync.maybeWhen(
      data: (surahs) => surahs.firstWhere((s) => s.id == _targetSurahId).nameAr,
      orElse: () => '...',
    );
    final isBookmarked = bookmarks.any(
      (b) => b.surahId == _targetSurahId && b.ayahNumber == 1,
    );

    return Scaffold(
      appBar: _immersive
          ? null
          : AppBar(
              title: const Text(
                'القرآن الكريم',
                style: TextStyle(fontFamily: 'AmiriQuran', fontSize: 18),
              ),
              actions: [
                GoldIconButton(
                  icon: Icons.search,
                  tooltip: 'البحث',
                  color: AppColors.goldLight,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const QuranSearchScreen(),
                    ),
                  ),
                ),
                GoldIconButton(
                  icon: Icons.bookmark_border,
                  tooltip: 'العلامات المرجعية',
                  color: AppColors.goldLight,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const QuranBookmarksScreen(),
                    ),
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
      body: PageCurlView(
        itemCount: AppConstants.quranPageCount,
        semanticLabel: 'قارئ صفحات المصحف',
        initialIndex: initialPage - 1,
        prefetch: (index) async {
          final page = index + 1;
          await ref.read(qpcPageLayoutProvider(page).future);
          await QpcFontLoader.ensureLoaded(page);
        },
        onIndexChanged: (index) {
          final entry = ref.read(pageIndexProvider).value?[index];
          setState(() {
            _currentPage = index + 1;
            if (entry != null) _currentSurahId = entry.ranges.first.surahId;
          });
        },
        itemBuilder: (context, index) {
          final page = index + 1;
          return _MushafPage(
            pageNumber: page,
            highlightSurahId: widget.surahId,
            highlightAyahNumber: widget.highlightAyahNumber,
          );
        },
      ),
      bottomNavigationBar: QuranReaderToolbar(
        isBookmarked: isBookmarked,
        onSave: () => _onSave(currentSurahName),
        onShare: () => _onShare(currentSurahName),
        onTafsir: () => _onTafsir(currentSurahName),
        onSearch: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const QuranSearchScreen())),
        onFont: () => showReadingSettingsSheet(
          context,
          provider: quranReaderSettingsProvider,
        ),
        isImmersive: _immersive,
        onToggleImmersive: _toggleImmersive,
      ),
    );
  }
}

/// صفحة مصحفية واحدة (1-604): شريط علوي بالجزء (يمين) واسم السورة الحالية
/// (يسار)، ثم إطار زخرفي ذهبي يحوي محتوى الصفحة مطابقاً حرفياً لطباعة
/// مجمع الملك فهد (خط QPC v2 الخاص بكل صفحة)، وأخيراً رقم الصفحة أسفلها.
class _MushafPage extends ConsumerWidget {
  const _MushafPage({
    required this.pageNumber,
    this.highlightSurahId,
    this.highlightAyahNumber,
  });

  final int pageNumber;
  final int? highlightSurahId;
  final int? highlightAyahNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref
        .watch(quranReaderSettingsProvider)
        .resolveFor(Theme.of(context).brightness);
    // خلفية معتمة تملأ الخلية كاملة قبل أي محتوى: صفحات المصحف المجاورة
    // (السابقة/التالية) تبقى مبنيّة فعلياً خلف الصفحة الحالية في نفس
    // الـ Stack (بلا Opacity(0) لأسباب التقاط اللقطة)، فلو تُرك أي جزء من
    // الصفحة الحالية شفافاً (كسطر نص مُوسّط أضيق من عرض الصفحة) لظهرت
    // نصوص الصفحة المجاورة الحيّة من خلاله وتحرّكت بشكل غير مستقر.
    return ColoredBox(
      color: settings.backgroundColor,
      child: _buildBody(context, ref, settings),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, dynamic settings) {
    final numeralStyle = ref.watch(numeralStyleProvider);
    final pageIndexAsync = ref.watch(pageIndexProvider);
    final surahAsync = ref.watch(surahListProvider);
    final bookmarks = ref.watch(quranBookmarksProvider);

    if (pageIndexAsync.isLoading || surahAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (pageIndexAsync.hasError) {
      return Center(child: Text('تعذّر تحميل الفهرس: ${pageIndexAsync.error}'));
    }

    final entry = pageIndexAsync.value![pageNumber - 1];
    final surahs = surahAsync.value ?? const [];
    String surahNameOf(int surahId) => surahs
        .firstWhere((s) => s.id == surahId, orElse: () => surahs.first)
        .nameAr;

    final juzLabel = juzOrdinalName(entry.juz);
    final currentSurahLabel = surahNameOf(entry.ranges.last.surahId);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth >= 900
            ? 900.0
            : constraints.maxWidth;
        return Padding(
          padding: EdgeInsets.all(4.w),
          child: Center(
            child: SizedBox(
              width: maxWidth,
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 4.h,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              juzLabel,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: settings.textColor.withValues(
                                  alpha: 0.75,
                                ),
                              ),
                            ),
                            Text(
                              currentSurahLabel,
                              style: TextStyle(
                                fontFamily: 'AmiriQuran',
                                fontSize: 15.sp,
                                color: settings.textColor.withValues(
                                  alpha: 0.85,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 6.h,
                          ),
                          child: QpcMushafPage(
                            pageNumber: pageNumber,
                            highlightSurahId: highlightSurahId,
                            highlightAyahNumber: highlightAyahNumber,
                            isAyahBookmarked: (surahId, ayahNumber) =>
                                bookmarks.any(
                                  (b) =>
                                      b.surahId == surahId &&
                                      b.ayahNumber == ayahNumber,
                                ),
                            onAyahTap: (surahId, ayahNumber) =>
                                showTafsirSheet(
                                  context: context,
                                  surahId: surahId,
                                  surahNameAr: surahNameOf(surahId),
                                  ayahNumber: ayahNumber,
                                ),
                          ),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Center(
                        child: Text(
                          formatNumerals('$pageNumber', numeralStyle),
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            color: settings.accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // إطار زخرفي فوقي بحت (IgnorePointer) لا يحجز أي مساحة
                  // تخطيط ولا يُمرَّر عبره أي Padding لمحتوى الصفحة أعلاه -
                  // فقيود القياس التي تصل QpcMushafPage تبقى كما هي حرفياً،
                  // ومواضع أسطر القرآن لا تتحرك مطلقاً.
                  Positioned.fill(
                    child: OrnatePageFrame(color: settings.accentColor),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
