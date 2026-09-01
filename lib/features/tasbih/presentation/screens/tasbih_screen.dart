import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/islamic_pattern_background.dart';
import '../../../../core/widgets/ornate_divider.dart';
import '../../../../core/widgets/single_choice_dialog.dart';
import '../../../../core/widgets/text_input_dialog.dart';
import '../../domain/tasbih_state.dart';
import '../providers/tasbih_provider.dart';

/// عدّاد تسبيح مستقل: عبارة قابلة للاختيار، دائرة كبيرة تُعِدّ عند كل
/// نقرة (مع اهتزاز خفيف)، هدف قابل للتخصيص، وحفظ تلقائي للتقدّم.
class TasbihScreen extends ConsumerWidget {
  const TasbihScreen({super.key});

  Future<void> _pickTarget(BuildContext context, WidgetRef ref, int current) async {
    final selected = await showSingleChoiceDialog<int>(
      context: context,
      title: 'هدف التسبيح',
      options: const [33, 99, 100, -1],
      labelBuilder: (value) => value == -1 ? 'مخصّص' : '$value',
      currentValue: const [33, 99, 100].contains(current) ? current : -1,
    );
    if (selected == null) return;
    if (selected == -1) {
      if (!context.mounted) return;
      final text = await showTextInputDialog(
        context: context,
        title: 'عدد مخصّص',
        initialValue: '$current',
        hintText: 'مثال: 7',
      );
      final parsed = int.tryParse(text ?? '');
      if (parsed != null && parsed > 0) {
        await ref.read(tasbihProvider.notifier).setTarget(parsed);
      }
      return;
    }
    await ref.read(tasbihProvider.notifier).setTarget(selected);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tasbihProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reachedTarget = state.target > 0 && state.count > 0 && state.count % state.target == 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('عداد التسبيح'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'إعادة تصفير',
            onPressed: () => ref.read(tasbihProvider.notifier).reset(),
          ),
        ],
      ),
      body: IslamicPatternBackground(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        patternColor: AppColors.gold,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < tasbihPhrases.length; i++)
                      ChoiceChip(
                        label: Text(tasbihPhrases[i]),
                        selected: state.phraseIndex == i,
                        selectedColor: AppColors.gold.withValues(alpha: 0.3),
                        onSelected: (_) => ref.read(tasbihProvider.notifier).setPhraseIndex(i),
                      ),
                  ],
                ),
              ),
              OrnateDivider(color: AppColors.gold.withValues(alpha: 0.55)),
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      ref.read(tasbihProvider.notifier).increment();
                    },
                    child: Container(
                      width: 220,
                      height: 220,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.gold.withValues(alpha: reachedTarget ? 0.28 : 0.14),
                        border: Border.all(color: AppColors.gold, width: 2),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${state.count}',
                            style: const TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              color: AppColors.goldLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'الهدف: ${state.target}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: TextButton.icon(
                  onPressed: () => _pickTarget(context, ref, state.target),
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('تغيير الهدف'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
