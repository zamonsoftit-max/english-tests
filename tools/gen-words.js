// words.dart -> picture-admin/words.js generator
// Ishlatish: node tools/gen-words.js
const fs = require('fs');
const path = require('path');

const src = fs.readFileSync(path.join(__dirname, '..', 'lib', 'data', 'words.dart'), 'utf8');
const re = /Word\s*\(\s*english\s*:\s*(['"])(.*?)\1\s*,\s*uzbek\s*:\s*(['"])(.*?)\3\s*,\s*category\s*:\s*(['"])(.*?)\5\s*\)/gs;

function slug(s) {
  return s.toLowerCase().trim()
    .replace(/[''`]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '') + '.png';
}

const words = [];
let m;
while ((m = re.exec(src)) !== null) {
  words.push({
    id: words.length + 1,
    english: m[2],
    uzbek: m[4],
    category: m[6],
    file: slug(m[2]),
  });
}

const out = '// Avto-generatsiya: node tools/gen-words.js\n// ' + words.length + " ta so'z\nconst WORDS = " + JSON.stringify(words, null, 1) + ';\n';
const outDir = path.join(__dirname, '..', 'picture-admin');
if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });
fs.writeFileSync(path.join(outDir, 'words.js'), out, 'utf8');
console.log('WORDS:', words.length);
