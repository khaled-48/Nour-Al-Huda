// يبني assets/data/quran/page_index.json: فهرس الصفحات الـ 604 لمصحف
// المدينة المطبعي القياسي (نفس ترقيم الصفحة/الجزء المُضمَّن أصلاً في كل
// آية ضمن assets/data/quran/ayahs/*.json التي بناها build_quran_assets.js).
//
// كل صفحة قد تحوي آيات من سورة واحدة أو (عند بداية سورة جديدة وسط الصفحة)
// من سورتين متتاليتين، لذا الفهرس لكل صفحة قائمة نطاقات (surah_id +
// from_ayah/to_ayah) بدل افتراض سورة واحدة فقط، مع "juz" الجزء الذي تبدأ
// به الصفحة (من أول آية فيها).
//
// عمل بالكامل محلياً بلا إنترنت - يقرأ ملفات الآيات المبنية مسبقاً فقط.
//
// التشغيل: `node tool/build_quran_page_index.js`

const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..', 'assets', 'data', 'quran');
const AYAHS_DIR = path.join(ROOT, 'ayahs');

function main() {
  const pages = new Map(); // page -> { juz, ranges: [{surah_id, from_ayah, to_ayah}] }

  for (let surahId = 1; surahId <= 114; surahId++) {
    const file = path.join(AYAHS_DIR, `${String(surahId).padStart(3, '0')}.json`);
    const { ayahs } = JSON.parse(fs.readFileSync(file, 'utf8'));

    let currentRange = null;
    for (const ayah of ayahs) {
      const { ayah_number: ayahNumber, page, juz } = ayah;

      if (!pages.has(page)) pages.set(page, { juz, ranges: [] });

      if (
        currentRange &&
        currentRange.page === page &&
        currentRange.surah_id === surahId &&
        currentRange.to_ayah === ayahNumber - 1
      ) {
        currentRange.to_ayah = ayahNumber;
      } else {
        currentRange = { page, surah_id: surahId, from_ayah: ayahNumber, to_ayah: ayahNumber };
        pages.get(page).ranges.push(currentRange);
      }
    }
  }

  const maxPage = Math.max(...pages.keys());
  const out = [];
  for (let page = 1; page <= maxPage; page++) {
    const entry = pages.get(page);
    if (!entry) throw new Error(`صفحة مفقودة من الفهرس: ${page}`);
    out.push({
      page,
      juz: entry.juz,
      ranges: entry.ranges.map(({ surah_id, from_ayah, to_ayah }) => ({ surah_id, from_ayah, to_ayah })),
    });
  }

  fs.writeFileSync(path.join(ROOT, 'page_index.json'), JSON.stringify(out));
  console.log('تم. عدد الصفحات:', out.length, '(المتوقع 604)');
  if (out.length !== 604) throw new Error('عدد الصفحات غير مطابق للمتوقع (604)');
}

main();
