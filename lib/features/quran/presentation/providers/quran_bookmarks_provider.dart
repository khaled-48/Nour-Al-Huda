import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/quran_bookmark.dart';

/// يدير العلامات المرجعية على الآيات (يضعها القارئ حين يتوقف عن القراءة
/// ليتابع لاحقاً من نفس الموضع بالضبط)، ويحفظها محلياً.
class QuranBookmarksNotifier extends StateNotifier<List<QuranBookmark>> {
  QuranBookmarksNotifier() : super(const []) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.prefQuranBookmarks);
    if (raw == null) return;

    state = (jsonDecode(raw) as List<Object?>)
        .map((e) => QuranBookmark.fromJson(e! as Map<String, Object?>))
        .toList();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.prefQuranBookmarks,
      jsonEncode(state.map((b) => b.toJson()).toList()),
    );
  }

  bool isBookmarked(int surahId, int ayahNumber) =>
      state.any((b) => b.surahId == surahId && b.ayahNumber == ayahNumber);

  Future<void> toggle({
    required int surahId,
    required int ayahNumber,
    required String surahNameAr,
  }) async {
    if (isBookmarked(surahId, ayahNumber)) {
      state = state.where((b) => !(b.surahId == surahId && b.ayahNumber == ayahNumber)).toList();
    } else {
      state = [...state, QuranBookmark(surahId: surahId, ayahNumber: ayahNumber, surahNameAr: surahNameAr)];
    }
    await _persist();
  }

  Future<void> remove(int surahId, int ayahNumber) async {
    state = state.where((b) => !(b.surahId == surahId && b.ayahNumber == ayahNumber)).toList();
    await _persist();
  }
}

final quranBookmarksProvider = StateNotifierProvider<QuranBookmarksNotifier, List<QuranBookmark>>((ref) {
  return QuranBookmarksNotifier();
});

/// آخر علامة أضافها المستخدم، لعرض زر "متابعة القراءة" السريع في القائمة.
final lastQuranBookmarkProvider = Provider<QuranBookmark?>((ref) {
  final bookmarks = ref.watch(quranBookmarksProvider);
  return bookmarks.isEmpty ? null : bookmarks.last;
});
