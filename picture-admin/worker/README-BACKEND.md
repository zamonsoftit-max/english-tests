# To'liq backend — deploy yo'riqnomasi (5-10 daqiqa)

Maqsad: admin saytda **Saqlash** bossangiz → Cloudflare da saqlanadi → Android ilova internet bilan yangilanadi.

## 1. Kerakli narsalar
- Cloudflare akkaunt (Pages ishlatganingiz yetadi)
- `wrangler` CLI: `npm install -g wrangler` → `wrangler login`

## 2. KV + R2 yaratish (1 marta)

```bash
cd picture-admin/worker

# So'zlar bazasi
npx wrangler kv namespace create WORDS_KV

# Rasmlar ombori
npx wrangler r2 bucket create english-test-images
```

Chiqqan `KV id` ni `wrangler.toml` dagi izohdan chiqarib yoqing:
```toml
[[kv_namespaces]]
binding = "WORDS_KV"
id = "SIZNING_KV_ID"

[[r2_buckets]]
binding = "IMAGES_BUCKET"
bucket_name = "english-test-images"
```

## 3. Admin parol (token) o'rnatish

```bash
npx wrangler secret put ADMIN_TOKEN
# masalan: MeninMaxfiyTokenim123
```

## 4. Worker ni deploy qilish

```bash
npx wrangler deploy
# Chiqqan manzilni nusxalang, masalan:
# https://english-test-api.SIZ.workers.dev
```

Tekshirish: brauzerda `https://.../api/health` → `{"ok":true}` chiqishi kerak.

## 5. Admin panelni Worker ga ulash

`picture-admin/config.js` ni oching va API manzilni yozing:
```js
const API_CONFIG = { API_BASE: "https://english-test-api.SIZ.workers.dev" };
```

Keyin GitHub ga push qiling (Pages avtomatik yangilanadi).
Admin saytda **☁️ Cloud** bo'limida tokenni yozib **⬇ Yuklash / ⬆ Saqlash** ni bosing.

## 6. Flutter ilova

`lib/services/remote_config.dart` dagi `kApiBase` ga o'sha Worker manzilni yozing,
`flutter build apk --release` qilib yangi APK o'rnating. Shundan keyin:
- Internet bo'lsa → ilova Worker dagi so'z + rasmni ko'rsatadi
- Internet bo'lmasa → telefondagi eski (kesh + built-in) ro'yxat ishlaydi

## Xarajat
- Workers free: kuniga 100 000 so'rov — bu loyiha uchun yetadi
- KV free: 100 000 o'qish/kun
- R2: 10 GB gacha free, 429 ta rasm (~100 MB) sig'adi
