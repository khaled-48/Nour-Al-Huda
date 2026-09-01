import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/islamic_pattern_background.dart';
import '../../../tasbih/presentation/screens/tasbih_screen.dart';
import '../../domain/azkar_category.dart';
import '../providers/azkar_providers.dart';
import 'azkar_reader_screen.dart';

class AzkarCategoriesScreen extends ConsumerStatefulWidget {
  const AzkarCategoriesScreen({super.key});

  @override
  ConsumerState<AzkarCategoriesScreen> createState() =>
      _AzkarCategoriesScreenState();
}

class _AzkarCategoriesScreenState extends ConsumerState<AzkarCategoriesScreen> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(azkarCategoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الأذكار والأدعية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.touch_app_outlined),
            tooltip: 'عداد التسبيح',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TasbihScreen()),
            ),
          ),
        ],
      ),
      body: IslamicPatternBackground(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        patternColor: AppColors.gold,
        child: categoriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Center(child: Text('تعذّر تحميل الأذكار: $error')),
          data: (categoriesById) {
            final categories = categoriesById.values;
            final filtered = _filter.isEmpty
                ? categories.toList(growable: false)
                : categories
                      .where((c) => c.title.contains(_filter))
                      .toList(growable: false);

            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
                  child: TextField(
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      hintText: 'ابحث عن باب (مثل: الصباح، النوم، السفر...)',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    onChanged: (value) => setState(() => _filter = value),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('لا توجد نتائج مطابقة.'))
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxisCount = constraints.maxWidth >= 900
                                ? 3
                                : constraints.maxWidth >= 600
                                ? 2
                                : 1;
                            return GridView.builder(
                              padding: EdgeInsets.all(12.w),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                // .w عمداً بدل .h، لنفس سبب فهرس السور: نص البطاقة
                                // يُحجَّم بـ .sp (مقياس العرض)، فيجب أن يتبع ارتفاع
                                // الخلية المقياس نفسه حتى لا يفيض النص عند أي نسبة
                                // عرض إلى ارتفاع غير معتادة.
                                mainAxisExtent: 70.w,
                                crossAxisSpacing: 10.w,
                                mainAxisSpacing: 10.h,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) =>
                                  _CategoryTile(category: filtered[index]),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category});

  final AzkarCategory category;

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
            builder: (_) => AzkarReaderScreen(initialCategoryId: category.id),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
          ),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
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
                child: Icon(
                  Icons.menu_book_outlined,
                  color: AppColors.gold,
                  size: 17.sp,
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
                      category.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14.sp, height: 1.3),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${category.items.length} دعاء/ذكر',
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
            ],
          ),
        ),
      ),
    );
  }
}
