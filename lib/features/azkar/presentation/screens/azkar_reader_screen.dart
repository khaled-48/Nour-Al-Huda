import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/reading/reading_settings_sheet.dart';
import '../../../../core/widgets/ornate_divider.dart';
import '../../domain/azkar_category.dart';
import '../providers/azkar_providers.dart';
import '../providers/azkar_reader_settings_provider.dart';

/// عرض أدعية الأبواب، بابًا بابًا، مع إمكانية التنقّل بين الأبواب بالسحب
/// يميناً ويساراً (PageView) تماماً كشاشة قراءة القرآن. لون الخلفية ولون
/// النص وحجم الخط قابلة للتخصيص من إعدادات القراءة (أيقونة الضبط بالأعلى).
/// النقر على أي بطاقة يزيد عدّاد مرات القراءة (يُصفَّر تلقائياً عند تغيير
/// الباب، فهو مجرد مساعد بصري أثناء القراءة).
class AzkarReaderScreen extends ConsumerStatefulWidget {
  const AzkarReaderScreen({super.key, required this.initialCategoryId});

  final int initialCategoryId;

  @override
  ConsumerState<AzkarReaderScreen> createState() => _AzkarReaderScreenState();
}

class _AzkarReaderScreenState extends ConsumerState<AzkarReaderScreen> {
  late final PageController _pageController;
  late int _currentCategoryId;

  @override
  void initState() {
    super.initState();
    _currentCategoryId = widget.initialCategoryId;
    _pageController = PageController(initialPage: widget.initialCategoryId - 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings =
        ref.watch(azkarReaderSettingsProvider).resolveFor(Theme.of(context).brightness);
    final categoriesAsync = ref.watch(azkarCategoriesProvider);

    return categoriesAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) =>
          Scaffold(body: Center(child: Text('تعذّر تحميل الأذكار: $error'))),
      data: (categoriesById) {
        final categories = categoriesById.values.toList(growable: false);
        final currentTitle = categoriesById[_currentCategoryId]?.title ?? '...';

        return Scaffold(
          appBar: AppBar(
            title: Text(currentTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.tune),
                tooltip: 'إعدادات القراءة',
                onPressed: () => showReadingSettingsSheet(
                  context,
                  provider: azkarReaderSettingsProvider,
                ),
              ),
            ],
          ),
          backgroundColor: settings.backgroundColor,
          body: PageView.builder(
            controller: _pageController,
            itemCount: categories.length,
            onPageChanged: (index) =>
                setState(() => _currentCategoryId = categories[index].id),
            itemBuilder: (context, index) {
              return RepaintBoundary(
                child: _CategoryPage(category: categories[index]),
              );
            },
          ),
        );
      },
    );
  }
}

class _CategoryPage extends ConsumerStatefulWidget {
  const _CategoryPage({required this.category});

  final AzkarCategory category;

  @override
  ConsumerState<_CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends ConsumerState<_CategoryPage> {
  late final List<int> _counts = List.filled(widget.category.items.length, 0);

  @override
  Widget build(BuildContext context) {
    final settings =
        ref.watch(azkarReaderSettingsProvider).resolveFor(Theme.of(context).brightness);
    final cardColor = Color.alphaBlend(
      settings.textColor.withValues(alpha: 0.04),
      settings.backgroundColor,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth >= 700
            ? 700.0
            : constraints.maxWidth;
        return Center(
          child: SizedBox(
            width: maxWidth,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  child: OrnateDivider(color: settings.accentColor),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    itemCount: widget.category.items.length,
                    itemBuilder: (context, index) {
                      final item = widget.category.items[index];
                      return Card(
                        color: cardColor,
                        margin: EdgeInsets.only(bottom: 10.h),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12.r),
                          onTap: () => setState(() => _counts[index]++),
                          child: Padding(
                            padding: EdgeInsets.all(16.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  item.text,
                                  textAlign: TextAlign.justify,
                                  textDirection: TextDirection.rtl,
                                  style: TextStyle(
                                    fontFamily: 'AmiriQuran',
                                    fontSize: 18.sp * settings.fontScale,
                                    height: 1.9,
                                    color: settings.textColor,
                                  ),
                                ),
                                if (item.footnote != null) ...[
                                  SizedBox(height: 8.h),
                                  Text(
                                    item.footnote!,
                                    textDirection: TextDirection.rtl,
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: settings.accentColor,
                                    ),
                                  ),
                                ],
                                SizedBox(height: 10.h),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: _CounterBadge(
                                    count: _counts[index],
                                    accent: settings.accentColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  child: OrnateDivider(color: settings.accentColor),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CounterBadge extends StatelessWidget {
  const _CounterBadge({required this.count, required this.accent});

  final int count;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.touch_app_outlined, size: 14.sp, color: accent),
          SizedBox(width: 6.w),
          Text(
            '$count',
            style: TextStyle(fontSize: 13.sp, color: accent),
          ),
        ],
      ),
    );
  }
}
