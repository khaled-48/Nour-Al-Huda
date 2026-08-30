import 'package:flutter/material.dart';

import 'quran_bookmarks_screen.dart';

/// تبويب "المفضلة" في الشريط السفلي: العلامات المرجعية على آيات القرآن.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المفضلة')),
      body: const QuranBookmarksBody(),
    );
  }
}
