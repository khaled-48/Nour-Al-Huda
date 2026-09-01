// يبني ملف JSON واحد لكل صفحة من صفحات المصحف (1-604) يصف أسطرها الخمسة
// عشر بدقّة تامة كما في طباعة مجمع الملك فهد: نوع كل سطر (اسم سورة/بسملة/
// آيات)، وإن كان مُوسّطاً، وقائمة "كلمات" كل سطر (رمز الحرف الخاص بخط
// الصفحة QPC v2 + رقم السورة/الآية لكل كلمة) - مبني من دمج قاعدتي بيانات:
// تخطيط الأسطر (qpc-v2-15-lines.db) ونصوص الكلمات المرمّزة (qpc-v2.db).
// يعمل هذا مرة واحدة أوفلاين تماماً (بلا شبكة)، تماشياً مع بقية أدوات
// tool/build_*.js في هذا المشروع.
const { DatabaseSync } = require('node:sqlite');
const fs = require('fs');
const path = require('path');

const [layoutDbPath, wordsDbPath] = process.argv.slice(2);
if (!layoutDbPath || !wordsDbPath) {
  console.error(
    'Usage: node build_qpc_v2_pages.js <layout.db> <words.db>',
  );
  process.exit(1);
}

const layoutDb = new DatabaseSync(layoutDbPath, { readOnly: true });
const wordsDb = new DatabaseSync(wordsDbPath, { readOnly: true });

const wordRows = wordsDb.prepare('SELECT * FROM words ORDER BY id').all();
const wordsById = new Map();
for (const w of wordRows) {
  wordsById.set(w.id, w);
}
console.log('Loaded', wordsById.size, 'words');

const lineRows = layoutDb
  .prepare(
    'SELECT * FROM pages ORDER BY page_number, line_number',
  )
  .all();

const pages = new Map();
for (const row of lineRows) {
  if (!pages.has(row.page_number)) pages.set(row.page_number, []);

  const hasWordRange =
    row.first_word_id !== '' && row.last_word_id !== '';
  const first = Number(row.first_word_id);
  const last = Number(row.last_word_id);

  const words = [];
  if (hasWordRange) {
    for (let id = first; id <= last; id++) {
      const w = wordsById.get(id);
      if (!w) {
        console.error(
          `Missing word id ${id} referenced by page ${row.page_number} line ${row.line_number}`,
        );
        continue;
      }
      words.push({ surah: w.surah, ayah: w.ayah, word: w.word, text: w.text });
    }
  }

  pages.get(row.page_number).push({
    line: row.line_number,
    type: row.line_type,
    centered: !!row.is_centered,
    surah: row.surah_number === '' ? null : row.surah_number,
    words,
  });
}

const outDir = path.join(
  __dirname,
  '..',
  'assets',
  'data',
  'quran',
  'qpc_pages',
);
fs.mkdirSync(outDir, { recursive: true });

let written = 0;
for (const [page, lines] of pages) {
  const file = path.join(outDir, `${String(page).padStart(3, '0')}.json`);
  fs.writeFileSync(file, JSON.stringify({ page, lines }));
  written++;
}
console.log('Wrote', written, 'page files to', outDir);
