// يبني assets/data/azkar/hisn_almuslim.json من نص كتاب "حصن المسلم من
// أذكار الكتاب والسنة" (سعيد بن علي بن وهف القحطاني)، بصيغة JSON مفتوحة:
// https://github.com/rn0x/hisn_almuslim_json
//
// يحوّل الملف المصدر (كائن JSON مفتاحه عنوان الباب بالعربية) إلى خريطة
// بيانات (Map) نظيفة مفتاحها معرّف رقمي فريد لكل باب — هذا يمنع بنيوياً
// أي تكرار لمعرّف باب عند الكتابة (بعكس مصفوفة قد تحوي عنصرين بنفس
// المعرّف دون أن يشتكي أي شيء)، ويتحقق أولاً بمسح نصي مباشر للملف الخام
// (بدل الاعتماد على JSON.parse وحده) من خلوّه من عناوين أبواب متكررة أو
// أدعية فارغة أو مكرَّرة داخل الباب نفسه، ويتوقف بخطأ فوراً عند أي مشكلة.
//
// التشغيل: `node tool/build_azkar_assets.js`

const fs = require('fs');
const path = require('path');

const OUT_PATH = path.join(__dirname, '..', 'assets', 'data', 'azkar', 'hisn_almuslim.json');
const SOURCE_URL = 'https://raw.githubusercontent.com/rn0x/hisn_almuslim_json/main/hisn_almuslim.json';

function findTopLevelKeys(raw) {
  let depth = 0;
  let i = 0;
  const keys = [];

  function readString(start) {
    let j = start + 1;
    while (j < raw.length) {
      if (raw[j] === '\\') { j += 2; continue; }
      if (raw[j] === '"') return j;
      j++;
    }
    throw new Error('نص غير منتهٍ عند الموضع ' + start);
  }

  while (i < raw.length) {
    const ch = raw[i];
    if (ch === '"') {
      const end = readString(i);
      if (depth === 1) {
        let k = end + 1;
        while (/\s/.test(raw[k])) k++;
        if (raw[k] === ':') keys.push(JSON.parse(raw.slice(i, end + 1)));
      }
      i = end + 1;
      continue;
    }
    if (ch === '{' || ch === '[') depth++;
    else if (ch === '}' || ch === ']') depth--;
    i++;
  }
  return keys;
}

async function main() {
  console.log('تحميل حصن المسلم...');
  const res = await fetch(SOURCE_URL);
  if (!res.ok) throw new Error(`فشل التحميل: HTTP ${res.status}`);
  const raw = await res.text();

  // تحقق من عدم وجود عناوين أبواب متكررة قبل أن يبتلعها JSON.parse بصمت.
  const topLevelKeys = findTopLevelKeys(raw);
  const seen = new Set();
  for (const key of topLevelKeys) {
    if (seen.has(key)) throw new Error(`عنوان باب مكرر في المصدر: ${key}`);
    seen.add(key);
  }

  const parsed = JSON.parse(raw);
  if (Object.keys(parsed).length !== topLevelKeys.length) {
    throw new Error('عدد الأبواب بعد JSON.parse لا يطابق المسح الخام — احتمال بيانات مفقودة');
  }

  const categories = {};
  let index = 0;
  let totalItems = 0;

  for (const [title, value] of Object.entries(parsed)) {
    index++;
    const texts = Array.isArray(value.text) ? value.text : [value.text];
    const footnotes = Array.isArray(value.footnote) ? value.footnote : [value.footnote].filter(Boolean);

    const seenTexts = new Set();
    for (const t of texts) {
      if (!t || !t.trim()) throw new Error(`نص فارغ في الباب "${title}"`);
      if (seenTexts.has(t)) throw new Error(`دعاء مكرر داخل الباب "${title}": ${t.slice(0, 40)}...`);
      seenTexts.add(t);
    }

    categories[String(index)] = {
      title,
      items: texts.map((t, i) => ({ text: t, footnote: footnotes[i] || null })),
    };
    totalItems += texts.length;
  }

  fs.mkdirSync(path.dirname(OUT_PATH), { recursive: true });
  fs.writeFileSync(OUT_PATH, JSON.stringify({ categories }));

  console.log('تم. الأبواب:', Object.keys(categories).length, '| إجمالي الأدعية:', totalItems);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
