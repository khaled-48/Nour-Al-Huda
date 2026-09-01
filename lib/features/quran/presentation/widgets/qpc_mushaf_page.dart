import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/qpc_font_loader.dart';
import '../../../../core/widgets/ornate_page_frame.dart';
import '../../domain/qpc_page_layout.dart';
import '../providers/quran_providers.dart';
import '../providers/quran_reader_settings_provider.dart';

/// نص البسملة المرجعي (نفس نص الآية الأولى من الفاتحة حرفياً) - يُعرض بخط
/// عادي (AmiriQuran) لأسطر البسملة الزخرفية التي لا تحمل رموز كلمات في
/// تخطيط QPC (لأنها ليست آية حقيقية في أغلب السور).
const String _basmala = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ';

/// نسب عرض تقريبية لأسطر الهيكل العظمي (Skeleton) الخمسة عشر، تتكرر بنمط
/// غير رتيب حتى لا تبدو الصفحة الفارغة كأشرطة متطابقة الطول.
const List<double> _skeletonLineWidths = [
  0.55,
  0.92,
  0.78,
  0.95,
  0.68,
  0.9,
  0.6,
  0.85,
  0.72,
  0.95,
  0.65,
  0.88,
  0.58,
  0.8,
  0.5,
];

/// صفحة مصحف واحدة (1-604) مطابقة حرفياً لطباعة مجمع الملك فهد: تُعرض
/// أسطرها الخمسة عشر كما هي بالضبط (بلا التفاف/تبرير نصي من فلاتر إطلاقاً)،
/// باستخدام رموز حروف خط تلك الصفحة تحديداً (QPC v2) - كل صفحة لها خط
/// مستقل تماماً، يُحمَّل ديناميكياً فقط عند فتحها ([QpcFontLoader]).
class QpcMushafPage extends ConsumerStatefulWidget {
  const QpcMushafPage({
    super.key,
    required this.pageNumber,
    this.highlightSurahId,
    this.highlightAyahNumber,
    this.isAyahBookmarked,
    required this.onAyahTap,
  });

  final int pageNumber;
  final int? highlightSurahId;
  final int? highlightAyahNumber;
  final bool Function(int surahId, int ayahNumber)? isAyahBookmarked;
  final void Function(int surahId, int ayahNumber) onAyahTap;

  @override
  ConsumerState<QpcMushafPage> createState() => _QpcMushafPageState();
}

class _QpcMushafPageState extends ConsumerState<QpcMushafPage>
    with SingleTickerProviderStateMixin {
  final Map<int, TapGestureRecognizer> _recognizers = {};
  int? _recognizersForPage;

  late final AnimationController _shimmerController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  bool _fontReady = false;
  int? _fontReadyForPage;

  @override
  void initState() {
    super.initState();
    _loadFont();
  }

  @override
  void didUpdateWidget(covariant QpcMushafPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber) _loadFont();
  }

  /// يتحقّق أولاً بشكل متزامن هل الخط محمَّل مسبقاً (حالة التخزين المؤقت
  /// الشائعة بفضل التحميل الاستباقي في [PageCurlView.prefetch]) فيُظهر
  /// المحتوى فوراً من أول رسمة بلا أي وميض تحميل؛ فقط إن لم يكن محمَّلاً
  /// فعلاً يُظهر الهيكل العظمي (Skeleton) ريثما يكتمل التحميل الفعلي.
  void _loadFont() {
    final page = widget.pageNumber;
    if (QpcFontLoader.isLoaded(page)) {
      _fontReady = true;
      _fontReadyForPage = page;
      return;
    }
    _fontReady = false;
    QpcFontLoader.ensureLoaded(page).then((_) {
      if (!mounted || widget.pageNumber != page) return;
      setState(() {
        _fontReady = true;
        _fontReadyForPage = page;
      });
    });
  }

  int _ayahKey(int surahId, int ayahNumber) => surahId * 1000 + ayahNumber;

  TapGestureRecognizer _recognizerFor(int surahId, int ayahNumber) {
    if (_recognizersForPage != widget.pageNumber) {
      for (final r in _recognizers.values) {
        r.dispose();
      }
      _recognizers.clear();
      _recognizersForPage = widget.pageNumber;
    }
    final key = _ayahKey(surahId, ayahNumber);
    return _recognizers.putIfAbsent(
      key,
      () =>
          TapGestureRecognizer()
            ..onTap = () => widget.onAyahTap(surahId, ayahNumber),
    );
  }

  @override
  void dispose() {
    for (final r in _recognizers.values) {
      r.dispose();
    }
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layoutAsync = ref.watch(qpcPageLayoutProvider(widget.pageNumber));
    final surahsAsync = ref.watch(surahListProvider);
    final settings = ref
        .watch(quranReaderSettingsProvider)
        .resolveFor(Theme.of(context).brightness);

    if (layoutAsync.hasError) {
      return Center(child: Text('تعذّر تحميل الصفحة: ${layoutAsync.error}'));
    }

    final fontReady = _fontReady && _fontReadyForPage == widget.pageNumber;
    final layout = layoutAsync.value;
    if (!fontReady || layout == null) {
      return _buildSkeleton(settings);
    }

    String surahNameOf(int surahId) => surahsAsync.maybeWhen(
      data: (surahs) => surahs
          .firstWhere((s) => s.id == surahId, orElse: () => surahs.first)
          .nameAr,
      orElse: () => '',
    );

    final fontSize = 23.sp * settings.fontScale;

    return LayoutBuilder(
      builder: (context, constraints) {
        // نُبقي حجم الخط ثابتاً ومريحاً للقراءة دوماً (لا نُصغّره أبداً) -
        // بدل ذلك نضغط التباعد الأفقي بين الكلمات لكل سطر على حدة (حسب
        // محتواه الفعلي) لمنع الفيض العرضي، ونُقلّص ارتفاع علبة السطر
        // قليلاً عند الحاجة فقط (لا حجم الحرف نفسه) لمنع الفيض الرأسي.
        final heightMultiplier = _fitLineHeightMultiplier(
          layout: layout,
          availableHeight: constraints.maxHeight,
          fontSize: fontSize,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final line in layout.lines)
              Expanded(
                // كل سطر "كتلة" مقصوصة بحدودها تماماً - مهما اختلفت أبعاد
                // حروف خط الصفحة (QPC) عن التقدير، لا يمكن لأي رسم أن
                // يتجاوز حدود سطره ليتداخل مع السطر الذي فوقه أو تحته.
                child: ClipRect(
                  child: _buildLine(
                    context,
                    line,
                    settings: settings,
                    surahNameOf: surahNameOf,
                    fontSize: fontSize,
                    heightMultiplier: heightMultiplier,
                    availableWidth: constraints.maxWidth,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// يقيس الارتفاع الطبيعي الفعلي لحرف حقيقي من حروف خط هذه الصفحة (QPC)
  /// بحجم الخط الثابت المريح، ثم يُعيد مضاعِف ارتفاع سطر (height) أصغر من
  /// 1.0 فقط إن كان ذلك الارتفاع الطبيعي أطول من حصّة السطر الواحد من
  /// الإطار المتاح - يُقلِّص علبة تخطيط السطر لا حجم الحرف نفسه، بحدّ أدنى
  /// معقول (0.8) حتى لا يبدو النص مضغوطاً بشكل غير مريح.
  double _fitLineHeightMultiplier({
    required QpcPageLayout layout,
    required double availableHeight,
    required double fontSize,
  }) {
    if (availableHeight <= 0 || layout.lines.isEmpty) return 1.0;
    final lineBudget = availableHeight / layout.lines.length;

    QpcWord? sample;
    for (final line in layout.lines) {
      if (line.words.isNotEmpty) {
        sample = line.words.first;
        break;
      }
    }
    if (sample == null) return 1.0;

    final painter = TextPainter(
      text: TextSpan(
        text: sample.text,
        style: TextStyle(
          fontFamily: AppConstants.qpcPageFontFamily(widget.pageNumber),
          fontSize: fontSize,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    final naturalHeight = painter.height;
    painter.dispose();

    if (naturalHeight <= lineBudget || naturalHeight <= 0) return 1.0;

    const floor = 0.8;
    return (lineBudget / naturalHeight).clamp(floor, 1.0);
  }

  /// يبحث بالتنصيف (binary search) عن أقرب قيمة letterSpacing سالبة للصفر
  /// (أفضل مقروئية) تجعل عرض السطر المُقاس فعلياً عبر TextPainter - لا
  /// المُقدَّر حسابياً - يتّسع ضمن العرض المتاح بلا التفاف.
  ///
  /// كان الحساب السابق يُقسِّم الفائض على (plainText.length - 1) بافتراض أن
  /// كل وحدة UTF-16 في النص تقابل "فجوة" تباعد واحدة يُطبَّق عليها
  /// letterSpacing - لكن نص القرآن المُشكَّل يحوي كمّاً كبيراً من علامات
  /// التشكيل (فتحة/ضمة/كسرة/شدة/تنوين...) التي تُحسَب ضمن .length دون أن
  /// تُضيف فجوة تباعد فعلية خاصة بها، فيُقلَّل الضغط الفعلي المطلوب بشدة على
  /// الأسطر الكثيفة الكلمات (فيلتف السطر) رغم عمله على الأسطر القصيرة. القياس
  /// الفعلي هنا في كل محاولة يتجنّب هذا الافتراض كلياً.
  double _fitLetterSpacing({
    required String plainText,
    required String fontFamily,
    required double fontSize,
    required double availableWidth,
  }) {
    if (plainText.length <= 1 || availableWidth <= 0) return 0;

    double measureWidth(double spacing) {
      final painter = TextPainter(
        text: TextSpan(
          text: plainText,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: fontSize,
            letterSpacing: spacing,
          ),
        ),
        textDirection: TextDirection.rtl,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    if (measureWidth(0) <= availableWidth) return 0;

    final floor = -fontSize * 1.5;
    var lo = -1.0;
    while (measureWidth(lo) > availableWidth && lo > floor) {
      lo *= 2;
    }
    if (lo < floor) lo = floor;

    var hi = 0.0;
    for (var i = 0; i < 12; i++) {
      final mid = (lo + hi) / 2;
      if (measureWidth(mid) <= availableWidth) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  /// هيكل عظمي بلون الورق نفسه (لا أبيض ولا فراغ مطلقاً) بأشرطة خافتة
  /// تنبض بلطف بعدد أسطر الصفحة الحقيقي (15 سطراً) بدل مؤشر تحميل دائري
  /// يكسر إحساس "صفحة مصحف" أثناء الانتظار القصير لتحميل الخط/البيانات.
  Widget _buildSkeleton(dynamic settings) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) {
        final alpha = 0.06 + _shimmerController.value * 0.08;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final widthFraction in _skeletonLineWidths)
              Expanded(
                child: Center(
                  child: FractionallySizedBox(
                    widthFactor: widthFraction,
                    child: Container(
                      height: 14.h,
                      decoration: BoxDecoration(
                        color: settings.textColor.withValues(alpha: alpha),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildLine(
    BuildContext context,
    QpcLine line, {
    required dynamic settings,
    required String Function(int) surahNameOf,
    required double fontSize,
    required double heightMultiplier,
    required double availableWidth,
  }) {
    switch (line.type) {
      case 'surah_name':
        // Stack(expand) يملأ نفس علبة السطر الثابتة بالضبط (لا يزيد عليها
        // بكسلاً واحداً)، فالإطار المرسوم خلف العنوان زخرفة بحتة لا تُزيح
        // النص عن مركزه ولا تُغيّر ارتفاع هذا السطر بين بقية الأسطر.
        return Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _SurahTitleFramePainter(color: settings.accentColor)),
            Center(
              child: Text(
                '﴿ ${surahNameOf(line.surahId!)} ﴾',
                style: TextStyle(
                  fontFamily: 'AmiriQuran',
                  fontSize: fontSize * (20 / 21),
                  fontWeight: FontWeight.w600,
                  color: settings.accentColor,
                ),
              ),
            ),
          ],
        );
      case 'basmala':
        return Center(
          child: Text(
            _basmala,
            style: TextStyle(
              fontFamily: 'AmiriQuran',
              fontSize: fontSize * (19 / 21),
              color: settings.textColor,
            ),
          ),
        );
      default:
        return _buildAyahLine(
          context,
          line,
          settings: settings,
          fontSize: fontSize,
          heightMultiplier: heightMultiplier,
          availableWidth: availableWidth,
        );
    }
  }

  Widget _buildAyahLine(
    BuildContext context,
    QpcLine line, {
    required dynamic settings,
    required double fontSize,
    required double heightMultiplier,
    required double availableWidth,
  }) {
    final fontFamily = AppConstants.qpcPageFontFamily(widget.pageNumber);
    final spans = <InlineSpan>[];
    final plainText = StringBuffer();

    for (var i = 0; i < line.words.length; i++) {
      final word = line.words[i];
      final isHighlighted =
          word.surahId == widget.highlightSurahId &&
          word.ayahNumber == widget.highlightAyahNumber;
      final isBookmarked =
          widget.isAyahBookmarked?.call(word.surahId, word.ayahNumber) ?? false;

      Color? background;
      if (isHighlighted) {
        background = settings.accentColor.withValues(alpha: 0.35);
      } else if (isBookmarked) {
        background = settings.accentColor.withValues(alpha: 0.12);
      }

      final text = i == line.words.length - 1 ? word.text : '${word.text} ';
      plainText.write(text);
      spans.add(
        TextSpan(
          text: text,
          style: TextStyle(backgroundColor: background),
          recognizer: _recognizerFor(word.surahId, word.ayahNumber),
        ),
      );
    }

    final letterSpacing = _fitLetterSpacing(
      plainText: plainText.toString(),
      fontFamily: fontFamily,
      fontSize: fontSize,
      availableWidth: availableWidth,
    );

    return Center(
      child: RichText(
        textAlign: line.centered ? TextAlign.center : TextAlign.justify,
        textDirection: TextDirection.rtl,
        text: TextSpan(
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: fontSize,
            color: settings.textColor,
            height: heightMultiplier,
            letterSpacing: letterSpacing,
          ),
          children: spans,
        ),
      ),
    );
  }
}

/// إطار زخرفي خفيف (شكل بيضاوي مفرغ بلمسة معينة عند طرفيه) يُرسَم خلف عنوان
/// السورة داخل مساحة سطره الثابتة نفسها - أبعاده نسبة من حجم العلبة
/// المُعطاة له لا قياساً حرفياً لعرض النص، فيبقى ثابتاً بصرياً بغضّ النظر عن
/// طول اسم السورة، ولا يفرض أي قيد جديد على مكان النص المُمركَز فوقه.
class _SurahTitleFramePainter extends CustomPainter {
  _SurahTitleFramePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 24 || size.height <= 8) return;

    final rect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: size.width * 0.86,
      height: size.height * 0.7,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2));

    canvas.drawRRect(rrect, Paint()..color = color.withValues(alpha: 0.06));

    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(rrect, borderPaint);

    final inner = rect.deflate(3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(inner, Radius.circular(inner.height / 2)),
      Paint()
        ..color = color.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );

    // نجمة ثمانية الرؤوس عند كل طرف - نفس نمط زوايا [OrnatePageFrame] كي
    // تبدو شارة العنوان امتداداً طبيعياً لإطار الصفحة نفسه لا زخرفة منفصلة.
    for (final cx in [rect.left, rect.right]) {
      final center = Offset(cx, rect.center.dy);
      final path = eightPointStarPath(center: center, outerRadius: 4.2, innerRadius: 1.8);
      canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.65));
    }
  }

  @override
  bool shouldRepaint(covariant _SurahTitleFramePainter oldDelegate) =>
      oldDelegate.color != color;
}
