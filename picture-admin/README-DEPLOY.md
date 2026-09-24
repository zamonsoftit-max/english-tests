# ☁️ Cloudflare Pages ga yuklash — yo'riqnoma

Sayt **sof statik** (HTML/CSS/JS), server kerak emas — Cloudflare Pages ga to'g'ridan-to'g'ri mos.

## Tayyorlash

1. Tayyor rasmlarni `picture-admin/images/` papkasiga soling.
   Fayl nomlari `manifest.json` dagi kabi bo'lsin (masalan `apple.jpg`).
2. Terminalda ro'yxatni yangilang (muhim — bo'lmasa rasmlar ko'rinmaydi):
   `node tools/gen-images-list.js`
3. `picture-admin` papkada shu fayllar bo'lishi shart:
   `index.html`, `styles.css`, `app.js`, `words.js`, `images-list.js`, `_headers`, `images/`

## 1-usul: Dashboard (eng oson, build kerak emas)

1. https://dash.cloudflare.com → **Workers & Pages** → **Create** → **Pages** → **Upload assets**
2. Loyiha nomi: masalan `rasm-boshqarish`
3. `picture-admin` papkani zip qilib yuklang yoki fayllarni sudrab tashlang
4. **Deploy** — tayyor! Adres: `https://rasm-boshqarish.pages.dev`

## 2-usul: Terminal (Wrangler CLI)

```bash
npm install -g wrangler
wrangler login
npx wrangler pages deploy picture-admin --project-name=rasm-boshqarish
```

Chiqqan `https://...pages.dev` manzil — saytingiz.

## 3-usul: GitHub orqali (avtomatik deploy)

1. Loyihani GitHub ga push qiling.
2. Cloudflare Pages → Create → **Connect to Git** → repozitariyni tanlang.
3. Sozlamalar:
   - **Framework preset:** None
   - **Build command:** (bo'sh qoldiring)
   - **Build output directory:** `picture-admin`
4. Deploy — har push da sayt avtomatik yangilanadi.

## Eslatmalar

- Rasmlar brauzer IndexedDB sida saqlanadi — saytni yangilasangiz ham o'chmaydi.
- Boshqa kompyuterda davom ettirish uchun rasmlarni `images/` ga solib qayta deploy qiling.
- `800×600 px` o'lcham sayt ichida avtomatik qilinadi.
