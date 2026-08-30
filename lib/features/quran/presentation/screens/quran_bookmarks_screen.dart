import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/quran_bookmarks_provider.dart';
import 'surah_reader_screen.dart';

/// قائمة العلامات المرجعية التي وضعها المستخدم، للعودة لمتابعة القراءة
/// من نفس الآية بالضبط. جسم قابل لإعادة الاستخدام (يُستخدم كتبويب
/// "المفضلة" مباشرة، وأيضاً كشاشة مستقلة عبر [QuranBookmarksScreen]).
class QuranBookmarksBody extends ConsumerWidget {
  const QuranBookmarksBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(quranBookmarksProvider);

    if (bookmarks.isEmpty) {
      return const Center(
        child: Text('لا توجد علامات بعد. اضغط على أيقونة العلامة عند فتح تفسير أي آية.'),
      );
    }

    return ListView.separated(
      itemCount: bookmarks.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final bookmark = bookmarks[bookmarks.length - 1 - index];
        return ListTile(
          leading: const Icon(Icons.bookmark),
          title: Text(bookmark.surahNameAr, style: const TextStyle(fontFamily: 'AmiriQuran')),
          subtitle: Text('الآية ${bookmark.ayahNumber}'),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () =>
                ref.read(quranBookmarksProvider.notifier).remove(bookmark.surahId, bookmark.ayahNumber),
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SurahReaderScreen(
                surahId: bookmark.surahId,
                highlightAyahNumber: bookmark.ayahNumber,
              ),
            ),
          ),
        );
      },
    );
  }
}

class QuranBookmarksScreen extends StatelessWidget {
  const QuranBookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('العلامات المرجعية')),
      body: const QuranBookmarksBody(),
    );
  }
}
