import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/settings/numeral_style.dart';
import '../../../../core/settings/numeral_style_provider.dart';
import '../../../../core/utils/numeral_formatter.dart';
import '../../domain/ayah.dart';
import '../providers/quran_reader_settings_provider.dart';

/// يعرض آيات سورة كاملة كفقرة عربية واحدة متصلة ومستمرة (Justified)، تماماً
/// كطباعة المصحف الشريف الورقي: بلا بطاقات ولا حدود ولا أي فاصل بصري بين
/// الآيات — النص يتدفق على خلفية موحّدة بألوان وحجم خط يختارهما المستخدم
/// بحرية من إعدادات القراءة. رقم كل آية يظهر داخل مِدلاة صغيرة مكتومة
/// اللون مندمجة في سياق النص مباشرة (تتحوّل لأيقونة علامة مرجعية للآيات
/// المُعلَّمة). النقر على نص الآية يفتح تفسيرها.
///
/// تعمّدنا عدم وضع مستمع نقر مستقل لكل مِدلاة رقم آية (بالإضافة لمستمع
/// نص الآية) تفادياً لمضاعفة عدد الأدوات (Widgets) داخل الفقرة الواحدة؛
/// فقرة سورة طويلة (٢٨٦ آية في سورة البقرة مثلاً) تصبح ثقيلة الرسم لو
/// تضاعف عدد أدوات كل WidgetSpan.
class SurahText extends ConsumerStatefulWidget {
  const SurahText({
    super.key,
    required this.ayahs,
    required this.onAyahTap,
    this.isAyahBookmarked,
    this.highlightAyahNumber,
    this.highlightAnchorKey,
  });

  final List<Ayah> ayahs;
  final int? highlightAyahNumber;
  final ValueChanged<int> onAyahTap;
  final bool Function(int ayahNumber)? isAyahBookmarked;

  /// مرساة غير مرئية تُوضع قبل الآية المبرزة مباشرة، تُستخدم للتمرير
  /// إليها بدقة (`Scrollable.ensureVisible`) رغم أن كل السورة نص متصل واحد.
  final GlobalKey? highlightAnchorKey;

  @override
  ConsumerState<SurahText> createState() => _SurahTextState();
}

class _SurahTextState extends ConsumerState<SurahText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void didUpdateWidget(covariant SurahText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ayahs != widget.ayahs) _rebuildRecognizers();
  }

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  void _rebuildRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers
      ..clear()
      ..addAll(
        widget.ayahs.map(
          (ayah) => TapGestureRecognizer()..onTap = () => widget.onAyahTap(ayah.ayahNumber),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    if (_recognizers.length != widget.ayahs.length) _rebuildRecognizers();

    final settings = ref.watch(quranReaderSettingsProvider).resolveFor(Theme.of(context).brightness);
    final numeralStyle = ref.watch(numeralStyleProvider);
    final baseStyle = TextStyle(
      fontFamily: 'AmiriQuran',
      fontSize: 26.sp * settings.fontScale,
      height: 2.6,
      color: settings.textColor,
    );
    final highlightStyle = TextStyle(backgroundColor: settings.accentColor.withValues(alpha: 0.35));

    final spans = <InlineSpan>[];
    for (var i = 0; i < widget.ayahs.length; i++) {
      final ayah = widget.ayahs[i];
      final isHighlighted = ayah.ayahNumber == widget.highlightAyahNumber;
      final isBookmarked = widget.isAyahBookmarked?.call(ayah.ayahNumber) ?? false;

      if (isHighlighted && widget.highlightAnchorKey != null) {
        spans.add(
          WidgetSpan(child: SizedBox(key: widget.highlightAnchorKey, width: 0, height: 0)),
        );
      }

      spans.add(
        TextSpan(
          text: ayah.textUthmani,
          recognizer: _recognizers[i],
          style: isHighlighted ? highlightStyle : null,
        ),
      );
      spans.add(const TextSpan(text: ' '));
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _AyahNumberBadge(
            number: ayah.ayahNumber,
            accent: settings.accentColor,
            fontScale: settings.fontScale,
            isBookmarked: isBookmarked,
            numeralStyle: numeralStyle,
          ),
        ),
      );
      spans.add(const TextSpan(text: '  '));
    }

    return RichText(
      textAlign: TextAlign.justify,
      textDirection: TextDirection.rtl,
      text: TextSpan(style: baseStyle, children: spans),
    );
  }
}

class _AyahNumberBadge extends StatelessWidget {
  const _AyahNumberBadge({
    required this.number,
    required this.accent,
    required this.fontScale,
    required this.isBookmarked,
    required this.numeralStyle,
  });

  final int number;
  final Color accent;
  final double fontScale;
  final bool isBookmarked;
  final NumeralStyle numeralStyle;

  @override
  Widget build(BuildContext context) {
    final size = 28.w * fontScale;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: isBookmarked ? 0.32 : 0.16),
      ),
      child: isBookmarked
          ? Icon(Icons.bookmark, size: 14.sp * fontScale, color: accent)
          : Text(
              formatNumerals('$number', numeralStyle),
              style: TextStyle(fontSize: 11.sp * fontScale, fontFamily: 'Cairo', color: accent),
            ),
    );
  }
}
