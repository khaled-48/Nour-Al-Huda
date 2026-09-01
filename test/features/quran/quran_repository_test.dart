import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/features/quran/data/quran_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final repository = QuranRepository();

  group('getAllSurahs', () {
    test('يحمّل 114 سورة، تبدأ بالفاتحة وتنتهي بالناس', () async {
      final surahs = await repository.getAllSurahs();

      expect(surahs, hasLength(114));
      expect(surahs.first.id, 1);
      expect(surahs.first.nameEn, 'Al-Faatiha');
      expect(surahs.first.ayahCount, 7);
      expect(surahs.last.id, 114);
      expect(surahs.last.nameEn, 'An-Naas');
    });
  });

  group('getAyahsForSurah', () {
    test('سورة الفاتحة تحتوي 7 آيات مرقّمة بالتتابع', () async {
      final ayahs = await repository.getAyahsForSurah(1);

      expect(ayahs, hasLength(7));
      expect(
        ayahs.map((a) => a.ayahNumber).toList(),
        List.generate(7, (i) => i + 1),
      );
      expect(ayahs.every((a) => a.surahId == 1), isTrue);
    });
  });

  group('getTafsirForSurah', () {
    test('تفسير الفاتحة يغطّي آياتها السبع', () async {
      final tafsir = await repository.getTafsirForSurah(1);

      expect(tafsir.keys.toSet(), {1, 2, 3, 4, 5, 6, 7});
      expect(tafsir[1], isNotEmpty);
    });
  });

  group('search / searchAll', () {
    test(
      'البحث بلا تشكيل يجد آيات تحتوي الكلمة رغم التشكيل في الأصل',
      () async {
        final results = await repository.search('الرحمن الرحيم');
        expect(results, isNotEmpty);
      },
    );

    test('نص بحث فارغ يُعيد نتيجة فارغة دون قراءة الفهرس', () async {
      expect(await repository.search(''), isEmpty);
      expect(await repository.search('   '), isEmpty);
    });

    test('searchAll برقم سورة يطابق تلك السورة تحديداً', () async {
      final results = await repository.searchAll('1');
      expect(results.surahs.any((s) => s.id == 1), isTrue);
    });

    test('searchAll برقم جزء ضمن 1-30 يطابق بداية ذلك الجزء', () async {
      final results = await repository.searchAll('1');
      expect(results.juzMatches, isNotEmpty);
      expect(results.juzMatches.every((j) => j.juz == 1), isTrue);
    });

    test('searchAll باسم سورة عربي يطابقها فهرسياً', () async {
      final results = await repository.searchAll('الفاتحة');
      expect(results.surahs.any((s) => s.id == 1), isTrue);
    });

    test('searchAll لنص فارغ يُعيد نتيجة فارغة تماماً', () async {
      final results = await repository.searchAll('   ');
      expect(results.surahs, isEmpty);
      expect(results.juzMatches, isEmpty);
      expect(results.ayahs, isEmpty);
    });
  });

  group('getJuzIndex', () {
    test('يحمّل فهرس الثلاثين جزءاً كاملاً', () async {
      final juzIndex = await repository.getJuzIndex();
      expect(juzIndex, hasLength(30));
    });
  });

  group('getPageIndex / getAyahsForPage', () {
    test('فهرس الصفحات يحتوي 604 صفحة مصحفية بالترتيب', () async {
      final index = await repository.getPageIndex();
      expect(index, hasLength(604));
      expect(index.first.page, 1);
      expect(index.last.page, 604);
    });

    test('الصفحة الأولى: الفاتحة كاملة (7 آيات) في نطاق واحد', () async {
      final ayahs = await repository.getAyahsForPage(1);
      expect(ayahs, hasLength(7));
      expect(ayahs.every((a) => a.surahId == 1), isTrue);
      expect(ayahs.map((a) => a.ayahNumber).toList(), List.generate(7, (i) => i + 1));
    });

    test('صفحة تمتد عبر سورتين: آخر آية من سورة وأول آية من التالية بالترتيب', () async {
      // صفحة 106: آخر آية من سورة النساء (176) ثم أول آيتين من سورة المائدة.
      final ayahs = await repository.getAyahsForPage(106);
      expect(ayahs.first.surahId, 4);
      expect(ayahs.first.ayahNumber, 176);
      expect(ayahs.last.surahId, 5);
      expect(ayahs.map((a) => a.surahId).toSet(), {4, 5});
    });

    test('الصفحة الأخيرة (604): تحوي الإخلاص والفلق والناس بالترتيب', () async {
      final ayahs = await repository.getAyahsForPage(604);
      final surahOrder = <int>[];
      for (final a in ayahs) {
        if (surahOrder.isEmpty || surahOrder.last != a.surahId) {
          surahOrder.add(a.surahId);
        }
      }
      expect(surahOrder, [112, 113, 114]);
    });
  });
}
