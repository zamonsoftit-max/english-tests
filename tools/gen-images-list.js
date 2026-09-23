// picture-admin/images papkadagi mavjud rasmlar ro'yxatini generatsiya qiladi.
// Sayt faqat shu ro'yxatdagi fayllarni so'raydi — konsolda 404 xato chiqmaydi.
// Ishlatish: rasmlarni images/ ga solgach: node tools/gen-images-list.js
const fs = require('fs');
const path = require('path');

const dir = path.join(__dirname, '..', 'picture-admin', 'images');
const ALLOW = new Set(['.png', '.jpg', '.jpeg', '.webp']);

let files = [];
if (fs.existsSync(dir)) {
  files = fs.readdirSync(dir)
    .filter((f) => ALLOW.has(path.extname(f).toLowerCase()))
    .sort();
}

const out =
  '// Avto-generatsiya: node tools/gen-images-list.js\n' +
  '// images/ papkadagi mavjud rasmlar — sayt faqat shularni yuklaydi\n' +
  'const DEPLOYED_IMAGES = ' + JSON.stringify(files) + ';\n';

fs.writeFileSync(path.join(dir, '..', 'images-list.js'), out, 'utf8');
console.log('IMAGES:', files.length);
