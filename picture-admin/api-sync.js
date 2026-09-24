// ☁️ Cloud sync — admin panel <-> Cloudflare Workers (KV + R2).
// app.js dagi ALL, mem, customs, overrides bilan ishlaydi.
// Majburiy emas: API_BASE bo'sh bo'lsa faqat lokal rejim.

(function () {
  function apiBase() {
    try {
      const b = (typeof API_CONFIG !== 'undefined' && API_CONFIG.API_BASE) || '';
      return b.replace(/\/+$/, '');
    } catch (e) { return ''; }
  }
  function token() {
    try { return localStorage.getItem('cloud_admin_token') || ''; } catch (e) { return ''; }
  }
  function setToken(t) {
    try { localStorage.setItem('cloud_admin_token', t); } catch (e) {}
  }
  function status(msg, ok) {
    const el = document.getElementById('cloudStatus');
    if (el) {
      el.textContent = msg;
      el.style.color = ok === false ? '#c0392b' : ok === true ? '#1e8449' : '#666';
    }
    if (typeof toast === 'function' && msg) toast(msg);
  }

  async function downloadCloud() {
    const base = apiBase();
    if (!base) { status('❌ Avval config.js da API_BASE ni yozing', false); return; }
    status('⬇ Yuklanmoqda...');
    try {
      const r = await fetch(base + '/api/words', { cache: 'no-store' });
      if (!r.ok) throw new Error('HTTP ' + r.status);
      const data = await r.json();
      const words = Array.isArray(data.words) ? data.words : [];
      if (!words.length) { status('☁️ Cloud bo‘sh (0 ta so‘z)', false); return; }
      // Lokalga qo'llash: customs + overrides ni qayta quramiz
      // WORDS dagi id larni yangilaymiz (id bo'yicha moslash)
      const byId = {};
      for (const w of words) byId[String(w.id)] = w;
      // Mavjud WORDS ni yangilash (xotirada)
      for (const w of WORDS) {
        const c = byId[String(w.id)];
        if (c) { w.english = c.english; w.uzbek = c.uzbek; w.category = c.category; w.file = c.file; }
      }
      // Yangi custom so'zlar (id 'c...' yoki WORDS da yo'q id)
      const localIds = new Set(WORDS.map((w) => String(w.id)));
      const incomingCustom = words.filter((w) => !localIds.has(String(w.id)));
      try {
        localStorage.setItem('pa_custom_words', JSON.stringify(incomingCustom.map((w) => ({
          id: String(w.id), english: w.english, uzbek: w.uzbek, category: w.category, file: w.file,
        }))));
        localStorage.setItem('pa_overrides', '{}');
      } catch (e) {}
      if (typeof loadLocal === 'function') loadLocal();
      if (typeof refreshAll === 'function') refreshAll();
      if (typeof refreshCats === 'function') refreshCats();
      if (typeof render === 'function') render();
      status('✅ Cloud dan ' + words.length + ' ta so‘z yuklandi', true);
    } catch (e) {
      status('❌ Yuklashda xato: ' + e.message, false);
    }
  }

  async function uploadCloud() {
    const base = apiBase();
    if (!base) { status('❌ Avval config.js da API_BASE ni yozing', false); return; }
    const t = token();
    if (!t) { status('❌ Avval admin tokenni yozing', false); return; }
    if (typeof ALL === 'undefined' || !ALL.length) { status('❌ Hozircha so‘z yo‘q', false); return; }
    status('⬆ Saqlanmoqda (' + ALL.length + ' ta)...');
    try {
      const payload = {
        words: ALL.map((w) => ({ id: w.id, english: w.english, uzbek: w.uzbek, category: w.category, file: w.file })),
      };
      const r = await fetch(base + '/api/words', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + t },
        body: JSON.stringify(payload),
      });
      const data = await r.json().catch(() => ({}));
      if (!r.ok) throw new Error(data.error || ('HTTP ' + r.status));
      status('✅ Cloud ga saqlandi: ' + data.count + ' ta. Endi Android yangilanadi 📱', true);
    } catch (e) {
      status('❌ Saqlashda xato: ' + e.message, false);
    }
  }

  // Rasmni R2 ga yuklash.
  // MUHIM: token bo'lmasa jim turmaydi — xatoni qaytaradi,
  // aks holda rasm faqat brauzerda qolib, APK ga chiqmaydi.
  async function uploadImage(file, dataUrl) {
    const base = apiBase();
    const t = token();
    if (!base) return { ok: false, error: 'API_BASE yo‘q' };
    if (!t) {
      status('❌ Rasm Cloud ga chiqmadi: admin token yozilmagan!', false);
      return { ok: false, error: 'no token' };
    }
    if (!file) return { ok: false, error: 'no file' };
    try {
      const blob = await (await fetch(dataUrl)).blob();
      const r = await fetch(base + '/api/upload?file=' + encodeURIComponent(file.replace(/\.png$/i, '.jpg')), {
        method: 'POST',
        headers: { 'Content-Type': 'image/jpeg', Authorization: 'Bearer ' + t },
        body: blob,
      });
      const data = await r.json().catch(() => ({}));
      if (!r.ok) {
        status('❌ Rasm yuklanmadi (' + file + '): ' + (data.error || r.status), false);
        return { ok: false, error: data.error || r.status };
      }
      return { ok: true, ...data };
    } catch (e) { status('❌ Rasm yuklanmadi: ' + e.message, false); return { ok: false, error: e.message }; }
  }

  // Brauzerdagi barcha rasmlarni R2 ga qayta yuklash (R2 bo'sh bo'lsa qutqarish).
  async function uploadAllImages() {
    const base = apiBase();
    const t = token();
    if (!base) { status('❌ Avval config.js da API_BASE ni yozing', false); return; }
    if (!t) { status('❌ Avval admin tokenni yozing', false); return; }
    if (typeof mem === 'undefined') { status('❌ mem topilmadi', false); return; }
    const ids = Object.keys(mem);
    if (!ids.length) { status('❌ Brauzerda rasm yo‘q (avval + Rasm bosing)', false); return; }
    status('⬆ ' + ids.length + ' ta rasm yuklanmoqda...');
    let ok = 0, fail = 0;
    for (const id of ids) {
      try {
        const w = (typeof ALL !== 'undefined' ? ALL : []).find((x) => String(x.id) === String(id));
        if (!w) { fail++; continue; }
        const r = await uploadImage(w.file, mem[id]);
        if (r && r.ok) ok++; else fail++;
      } catch (e) { fail++; }
    }
    status('✅ ' + ok + ' ta yuklandi' + (fail ? ', ❌ ' + fail + ' ta xato' : '') + '. Endi ⬆ Saqlash ni bosing 📱', fail === 0);
  }

  function initUI() {
    const tInput = document.getElementById('cloudToken');
    if (tInput) {
      tInput.value = token();
      tInput.addEventListener('change', () => setToken(tInput.value.trim()));
    }
    const bDown = document.getElementById('btnCloudDown');
    if (bDown) bDown.onclick = downloadCloud;
    const bUp = document.getElementById('btnCloudUp');
    if (bUp) bUp.onclick = uploadCloud;
    // R2 bo'sh qolganda qutqarish tugmasi
    const cloudBar = document.getElementById('cloudBar');
    if (cloudBar && !document.getElementById('btnCloudUpImg')) {
      const bImg = document.createElement('button');
      bImg.id = 'btnCloudUpImg';
      bImg.textContent = '🖼️ Rasmlarni yuklash';
      bImg.title = 'Brauzerdagi barcha rasmlarni R2 ga yuklash (bir marta bosing)';
      bImg.onclick = uploadAllImages;
      cloudBar.appendChild(bImg);
    }
    const base = apiBase();
    if (!base) status('⚠️ Cloud o‘chiq — config.js da API_BASE ni yozing');
    else status('☁️ Tayyor: ' + base);
  }

  document.addEventListener('DOMContentLoaded', initUI);
  window.CloudSync = { downloadCloud, uploadCloud, uploadImage, uploadAllImages, apiBase, token, setToken };
})();
