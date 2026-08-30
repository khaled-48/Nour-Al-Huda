import 'package:flutter/material.dart';

import '../../features/azkar/presentation/screens/azkar_categories_screen.dart';
import '../../features/prayer_times/presentation/screens/prayer_times_screen.dart';
import '../../features/quran/presentation/screens/favorites_screen.dart';
import '../../features/quran/presentation/screens/surah_list_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../theme/app_colors.dart';

/// الإطار الرئيسي للتطبيق: تنقّل سفلي بين الأقسام الخمسة (القرآن،
/// الأذكار، المواقيت، المفضلة، الإعدادات). على الشاشات العريضة (تابلت
/// أفقي) يتحول إلى شريط تنقّل جانبي (NavigationRail).
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth >= 700;

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
              border: Border(top: BorderSide(color: AppColors.gold.withValues(alpha: 0.35))),
            ),
            child: NavigationBar(
              backgroundColor: surfaceColor,
              indicatorColor: AppColors.gold.withValues(alpha: 0.22),
              selectedIndex: _index,
              onDestinationSelected: _onSelect,
              destinations: _destinations,
            ),
          ),
        );
      },
    );
  }
}
