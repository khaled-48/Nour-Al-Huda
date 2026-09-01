import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/azkar/presentation/screens/azkar_categories_screen.dart';
import '../../features/prayer_times/presentation/screens/prayer_times_screen.dart';
import '../../features/quran/presentation/screens/favorites_screen.dart';
import '../../features/quran/presentation/screens/surah_list_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../theme/app_colors.dart';
import '../tv/tv_mode.dart';
import '../widgets/tv_focusable.dart';

/// الإطار الرئيسي للتطبيق: تنقّل سفلي بين الأقسام الخمسة (القرآن،
/// الأذكار، المواقيت، المفضلة، الإعدادات) على الهاتف، شريط جانبي على
/// الشاشات العريضة (تابلت أفقي)، وشريط علوي بتركيز D-pad على أجهزة
/// التلفاز (لا شريط سفلي عليها إطلاقاً، فهو غير عملي مع ريموت التحكم).
class RootShell extends ConsumerStatefulWidget {
  const RootShell({super.key});

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell> {
  // تبدأ الشاشة بمواقيت الصلاة (الفهرس 2) لا بالقرآن، لأنها الأكثر
  // احتياجاً للمعلومة الفورية عند فتح التطبيق (الصلاة القادمة والوقت
  // المتبقي)، خلافاً لترتيب عناصر شريط التنقّل نفسه الذي يبقى كما هو.
  int _index = 2;

  static const _screens = [
    SurahListScreen(),
    AzkarCategoriesScreen(),
    PrayerTimesScreen(),
    FavoritesScreen(),
    SettingsScreen(),
  ];

  static const _destinations = [
    NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'القرآن'),
    NavigationDestination(icon: Icon(Icons.nights_stay_outlined), selectedIcon: Icon(Icons.nights_stay), label: 'الأذكار'),
    NavigationDestination(icon: Icon(Icons.access_time_outlined), selectedIcon: Icon(Icons.access_time), label: 'المواقيت'),
    NavigationDestination(icon: Icon(Icons.bookmark_border), selectedIcon: Icon(Icons.bookmark), label: 'المفضلة'),
    NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'الإعدادات'),
  ];

  void _onSelect(int value) => setState(() => _index = value);

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final tvOverride = ref.watch(tvModeOverrideProvider);
    final tv = isTvMode(context, tvOverride);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth >= 700;

        if (tv) {
          return Scaffold(
            body: Column(
              children: [
                _TvTopNavBar(
                  selectedIndex: _index,
                  onSelect: _onSelect,
                ),
                Expanded(
                  child: IndexedStack(index: _index, children: _screens),
                ),
              ],
            ),
          );
        }

        if (isWideScreen) {
          return Scaffold(
            body: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    border: Border(right: BorderSide(color: AppColors.gold.withValues(alpha: 0.35))),
                  ),
                  child: NavigationRail(
                    backgroundColor: Colors.transparent,
                    indicatorColor: AppColors.gold.withValues(alpha: 0.22),
                    selectedIndex: _index,
                    onDestinationSelected: _onSelect,
                    labelType: NavigationRailLabelType.all,
                    destinations: _destinations
                        .map((d) => NavigationRailDestination(icon: d.icon, selectedIcon: d.selectedIcon, label: Text(d.label)))
                        .toList(),
                  ),
                ),
                Expanded(
                  child: IndexedStack(index: _index, children: _screens),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: IndexedStack(index: _index, children: _screens),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(top: BorderSide(color: AppColors.gold.withValues(alpha: 0.55))),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    for (var i = 0; i < _destinations.length; i++)
                      _AnimatedNavItem(
                        destination: _destinations[i],
                        selected: i == _index,
                        onTap: () => _onSelect(i),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// عنصر واحد ضمن شريط التنقّل السفلي، بحركات ضمنية (implicit animations)
/// تجعل التبديل بين الأقسام يبدو حيّاً: الأيقونة تكبر وتتوهّج بظلّ ذهبي
/// خلف حبّة (pill) خلفية تتلاشى للداخل عند الاختيار، والتسمية تتحوّل
/// تدريجياً لخط عريض ذهبي. لا حاجة لـ AnimationController هنا: كل حركة
/// (AnimatedContainer/AnimatedScale/AnimatedDefaultTextStyle) تُشغَّل
/// تلقائياً كلما تغيّرت [selected] بين إعادتي بناء متتاليتين.
class _AnimatedNavItem extends StatelessWidget {
  const _AnimatedNavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final NavigationDestination destination;
  final bool selected;
  final VoidCallback onTap;

  static const _duration = Duration(milliseconds: 280);
  // Curves.easeOutBack (تأثير "قفزة" مرن) يتجاوز حدّي 0/1 مؤقتاً أثناء
  // الحركة، وهو آمن لخاصية بلا حدّ دنيا كالـ scale، لكنه يُسقِط
  // AnimatedContainer.boxShadow في قيمة blurRadius سالبة للحظة عند إخفاء
  // الظلّ (١٤→٠) فيرمي استثناء "Text shadow blur radius should be
  // non-negative" — لذا يبقى محصوراً في AnimatedScale وحده، بينما تستخدم
  // خاصيتا الظل والنص منحنى مضبوطاً بلا تجاوز.
  static const _curve = Curves.easeOut;
  static const _scaleCurve = Curves.easeOutBack;

  @override
  Widget build(BuildContext context) {
    final icon = selected
        ? (destination.selectedIcon ?? destination.icon)
        : destination.icon;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: destination.label,
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: _duration,
                curve: _curve,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.gold.withValues(alpha: 0.22)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: selected
                      ? Border.all(color: AppColors.gold, width: 1)
                      : Border.all(color: Colors.transparent, width: 1),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.45),
                            blurRadius: 14,
                            spreadRadius: 0.5,
                          ),
                        ]
                      : const [],
                ),
                child: AnimatedScale(
                  scale: selected ? 1.15 : 1.0,
                  duration: _duration,
                  curve: _scaleCurve,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: IconTheme.merge(
                      key: ValueKey(selected),
                      data: IconThemeData(
                        size: 22,
                        color: selected ? AppColors.goldLight : null,
                      ),
                      child: icon,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: _duration,
                curve: _curve,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? AppColors.goldLight : null,
                ),
                child: Text(destination.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// شريط تنقّل علوي لواجهة التلفاز: عناصر كبيرة أفقية قابلة للتركيز عبر
/// D-pad (الأسهم يمين/يسار تنقل بينها تلقائياً بفضل نظام التركيز في
/// فلاتر)، بإطار وتوهّج ذهبي واضح على العنصر المُختار، بديلاً عن الشريط
/// السفلي غير العملي مع ريموت التحكم.
class _TvTopNavBar extends StatelessWidget {
  const _TvTopNavBar({required this.selectedIndex, required this.onSelect});

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static const _items = [
    (icon: Icons.menu_book, label: 'القرآن'),
    (icon: Icons.nights_stay, label: 'الأذكار'),
    (icon: Icons.access_time, label: 'المواقيت'),
    (icon: Icons.bookmark, label: 'المفضلة'),
    (icon: Icons.settings, label: 'الإعدادات'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF10241E), Color(0xFF18332B)],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        border: Border(bottom: BorderSide(color: AppColors.gold, width: 1.4)),
      ),
      child: FocusTraversalGroup(
        // Wrap بدل Row: على شاشات التلفاز العريضة تُعرض العناصر الخمسة في
        // سطر واحد كما هو مقصود، لكنها تلتفّ لسطر ثانٍ بدل أن تفيض خارج
        // الشاشة إذا فُرضت واجهة التلفاز يدوياً على هاتف أضيق من الإعدادات.
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 18,
          runSpacing: 8,
          children: [
            for (var i = 0; i < _items.length; i++)
              _TvNavItem(
                icon: _items[i].icon,
                label: _items[i].label,
                selected: i == selectedIndex,
                autofocus: i == selectedIndex,
                onTap: () => onSelect(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _TvNavItem extends StatelessWidget {
  const _TvNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.autofocus,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool autofocus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      onTap: onTap,
      autofocus: autofocus,
      borderRadius: 14,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.gold.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? AppColors.goldLight : Colors.white70, size: 26),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? AppColors.goldLight : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
