// يبني ملفات assets/data/quran/*.json من مصادر رسمية موثوقة:
//
//  - نص القرآن العثماني الكامل بالتشكيل: مشروع تنزيل (Tanzil Project)،
//    النسخة الرسمية المؤرشفة بتاريخ 2025-06-25 على Internet Archive
//    (https://archive.org/details/quran-uthmani_20250625) — وهو المصدر
//    المعتمد في أغلب تطبيقات القرآن نظراً لمراجعته الدقيقة المستمرة.
//  - بيانات هيكلية فقط (اسم السورة، الجزء، الصفحة لكل آية): alquran.cloud
//    (quran-uthmani edition)، تُستخدم للبنية وليس لنص الآية نفسه.
//  - التفسير الميسر: alquran.cloud (ar.muyassar edition)، وهو فعلياً نص
//    "مجمع الملك فهد لطباعة المصحف الشريف" — الجهة الناشرة الرسمية لهذا
//    التفسير (اسم الإصدار في alquran.cloud: "King Fahad Quran Complex").
//
// يتحقق تلقائياً من أن عدد آيات كل سورة متطابق بين المصدرين قبل الكتابة،
// ويتوقف بخطأ فوراً عند أي تعارض بدل كتابة بيانات مشكوك في صحتها.
//
// التشغيل: `node tool/build_quran_assets.js` (يتطلب اتصال إنترنت وقت
// البناء فقط؛ الناتج ملفات JSON محلية لا يحتاج التطبيق بعدها لأي اتصال).

const fs = require('fs');
const path = require('path');

const OUT_ROOT = path.join(__dirname, '..', 'assets', 'data', 'quran');

const TANZIL_URL = 'https://archive.org/download/quran-uthmani_20250625/quran-uthmani-aya.txt';
const META_URL = 'https://api.alquran.cloud/v1/quran/quran-uthmani';
const TAFSIR_URL = 'https://api.alquran.cloud/v1/quran/ar.muyassar';

async function fetchText(url) {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`فشل تحميل ${url}: HTTP ${res.status}`);
  return res.text();
}

async function fetchJson(url) {
  const text = await fetchText(url);
  return JSON.parse(text);
}

// مطابق تماماً لـ lib/core/utils/arabic_normalizer.dart — يجب تحديث
// الاثنين معاً عند أي تعديل، وإلا اختلفت نتائج البحث الحيّة عن الفهرسة.
function normalizeArabic(text) {
  return text
    .replace(/[ً-ٰٕۖ-ۭـ]/g, '')
    .replace(/[أإآٱ]/g, 'ا')
    .replace(/ى/g, 'ي')
    .replace(/ة/g, 'ه')
    .replace(/\s+/g, ' ')
    .trim();
}

function parseTanzilAya(raw) {
  const bySurah = new Map();
  for (const line of raw.split('\n')) {
    if (!line || line.startsWith('#')) continue;
    const firstBar = line.indexOf('|');
    const secondBar = line.indexOf('|', firstBar + 1);
    const surahId = Number(line.slice(0, firstBar));
    const ayahNumber = Number(line.slice(firstBar + 1, secondBar));
    const text = line.slice(secondBar + 1);
    if (!bySurah.has(surahId)) bySurah.set(surahId, new Map());
    bySurah.get(surahId).set(ayahNumber, text);
  }
  return bySurah;
}

async function main() {
  console.log('تحميل النص العثماني الرسمي من مشروع تنزيل...');
  const tanzilBySurah = parseTanzilAya(await fetchText(TANZIL_URL));

  console.log('تحميل البيانات الهيكلية (الجزء/الصفحة/أسماء السور)...');
  const meta = await fetchJson(META_URL);

  console.log('تحميل التفسير الميسر (مجمع الملك فهد)...');
  const muyassar = await fetchJson(TAFSIR_URL);

  if (meta.code !== 200 || muyassar.code !== 200) {
    throw new Error('استجابة غير سليمة من alquran.cloud');
  }

  fs.mkdirSync(path.join(OUT_ROOT, 'ayahs'), { recursive: true });
  fs.mkdirSync(path.join(OUT_ROOT, 'tafsir'), { recursive: true });

  const pad3 = (n) => String(n).padStart(3, '0');
  const surahsOut = [];
  const searchIndex = [];
  const juzIndex = [];
  let lastJuz = 0;
  let totalAyahs = 0;

  for (let i = 0; i < 114; i++) {
    const suMeta = meta.data.surahs[i];
    const suTafsir = muyassar.data.surahs[i];
    const surahId = suMeta.number;
    const tanzilAyahs = tanzilBySurah.get(surahId);

    if (!tanzilAyahs || tanzilAyahs.size !== suMeta.ayahs.length) {
      throw new Error(
        `تعارض في عدد آيات السورة ${surahId}: تنزيل=${tanzilAyahs?.size} alquran.cloud=${suMeta.ayahs.length}`,
      );
    }

    surahsOut.push({
      id: surahId,
      name_ar: suMeta.name,
      name_en: suMeta.englishName,
      translation_en: suMeta.englishNameTranslation,
      revelation_type: suMeta.revelationType,
      ayah_count: suMeta.ayahs.length,
    });

    const ayahsOut = [];
    const tafsirOut = [];

    for (let j = 0; j < suMeta.ayahs.length; j++) {
      const ayahNumber = j + 1;
      const canonicalText = tanzilAyahs.get(ayahNumber);
      if (!canonicalText) throw new Error(`نص تنزيل مفقود للآية ${surahId}:${ayahNumber}`);

      const { juz, page } = suMeta.ayahs[j];
      ayahsOut.push({ ayah_number: ayahNumber, text_uthmani: canonicalText, juz, page });
      tafsirOut.push({ ayah_number: ayahNumber, text: suTafsir.ayahs[j].text });

      if (juz !== lastJuz) {
        juzIndex.push({ juz, surah_id: surahId, ayah_number: ayahNumber });
        lastJuz = juz;
      }

      searchIndex.push({
        surah_id: surahId,
        surah_name_ar: suMeta.name,
        ayah_number: ayahNumber,
        text_uthmani: canonicalText,
        text_search: normalizeArabic(canonicalText),
      });
      totalAyahs++;
    }

    fs.writeFileSync(
      path.join(OUT_ROOT, 'ayahs', `${pad3(surahId)}.json`),
      JSON.stringify({ surah_id: surahId, ayahs: ayahsOut }),
    );
    fs.writeFileSync(
      path.join(OUT_ROOT, 'tafsir', `${pad3(surahId)}.json`),
      JSON.stringify({ surah_id: surahId, tafsir: tafsirOut }),
    );
  }

  fs.writeFileSync(path.join(OUT_ROOT, 'surahs.json'), JSON.stringify(surahsOut));
  fs.writeFileSync(path.join(OUT_ROOT, 'search_index.json'), JSON.stringify(searchIndex));
  fs.writeFileSync(path.join(OUT_ROOT, 'juz_index.json'), JSON.stringify(juzIndex));

  console.log('تم. السور:', surahsOut.length, '| إجمالي الآيات:', totalAyahs, '(المتوقع 6236)');
  if (totalAyahs !== 6236) throw new Error('عدد الآيات الإجمالي غير مطابق للمتوقع (6236)');
  if (juzIndex.length !== 30) throw new Error('عدد الأجزاء غير مطابق للمتوقع (30)');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
