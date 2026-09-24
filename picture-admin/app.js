// Rasm Boshqarish paneli — sof statik, Cloudflare Pages mos.
// Rasmlar IndexedDB da saqlanadi (brauzer ombori). Deploy qilingan
// saytda `images/<fayl>` mavjud bo'lsa, u avtomatik ko'rinadi.

const TARGET_W = 800, TARGET_H = 600;

// ---------- IndexedDB kichik ormagi ----------
const DB_NAME = 'rasm-admin', STORE = 'images';
let dbPromise = null;
function db() {
  if (!dbPromise) {
    dbPromise = new Promise((resolve, reject) => {
      try {
        const req = indexedDB.open(DB_NAME, 1);
        req.onupgradeneeded = () => req.result.createObjectStore(STORE);
        req.onsuccess = () => resolve(req.result);
        req.onerror = () => reject(req.error);
      } catch (e) { reject(e); }
    });
  }
  return dbPromise;
}
async function idbGetAll() {
  try {
    const d = await db();
    return await new Promise((res, rej) => {
      const tx = d.transaction(STORE, 'readonly');
      const q = tx.objectStore(STORE).getAll();
      q.onsuccess = () => res(q.result || []);
      q.onerror = () => rej(q.error);
    });
  } catch (e) { return []; }
}
async function idbPut(id, dataUrl) {
  const d = await db();
  return new Promise((res, rej) => {
    const tx = d.transaction(STORE, 'readwrite');
    tx.objectStore(STORE).put({ id, dataUrl });
    tx.oncomplete = res; tx.onerror = () => rej(tx.error);
  });
}
async function idbDel(id) {
  try {
    const d = await db();
    return new Promise((res) => {
      const tx = d.transaction(STORE, 'readwrite');
      tx.objectStore(STORE).delete(id);
      tx.oncomplete = res; tx.onerror = () => res();
    });
  } catch (e) { /* ignore */ }
}
async function idbClear() {
  try {
    const d = await db();
    return new Promise((res) => {
      const tx = d.transaction(STORE, 'readwrite');
      tx.objectStore(STORE).clear();
      tx.oncomplete = res; tx.onerror = () => res();
    });
  } catch (e) { /* ignore */ }
}

// ---------- Holat ----------
const mem = {}; // id -> dataURL (brauzerda yuklangan)
// Deploydagi images/ papkasida bor fayllar (images-list.js dan, 404 so'ramaslik uchun)
const deployedSet = new Set(typeof DEPLOYED_IMAGES !== 'undefined' ? DEPLOYED_IMAGES : []);
function deployedPath(file) {
  if (deployedSet.has(file)) return 'images/' + file;
  const alt = file.toLowerCase().endsWith('.png')
    ? file.replace(/\.png$/i, '.jpg')
    : file.replace(/\.jpe?g$/i, '.png');
  if (deployedSet.has(alt)) return 'images/' + alt;
  return null;
}

// ---------- Maxsus so'zlar va tahrirlar (localStorage) ----------
let customs = [];   // [{id:'c...', english, uzbek, category, file}]
let overrides = {}; // {id: {english, uzbek, category}} — 303 lik ro'yxatga tahrir
let ALL = [];       // samarali ro'yxat: WORDS + tahrirlar + maxsus so'zlar
function loadLocal() {
  try { customs = JSON.parse(localStorage.getItem('pa_custom_words') || '[]'); } catch (e) { customs = []; }
  try { overrides = JSON.parse(localStorage.getItem('pa_overrides') || '{}'); } catch (e) { overrides = {}; }
  if (!Array.isArray(customs)) customs = [];
  if (!overrides || typeof overrides !== 'object') overrides = {};
}
function saveLocal() {
  try {
    localStorage.setItem('pa_custom_words', JSON.stringify(customs));
    localStorage.setItem('pa_overrides', JSON.stringify(overrides));
  } catch (e) { toast('❌ Saqlashda xato (xotira to‘la?)'); }
}
function refreshAll() {
  ALL = WORDS.map((w) => (overrides[w.id] ? Object.assign({}, w, overrides[w.id]) : w)).concat(customs);
}
function isCustom(id) { return String(id).charAt(0) === 'c'; }
function slugify(s) {
  const t = String(s).toLowerCase().trim().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
  return (t || 'word') + '.png';
}
const $ = (id) => document.getElementById(id);
const grid = $('grid');

function toast(msg) {
  const t = $('toast');
  t.textContent = msg;
  t.hidden = false;
  clearTimeout(t._tm);
  t._tm = setTimeout(() => (t.hidden = true), 2200);
}

// ---------- Rasmni 800x600 ga keltirish (cover-crop) ----------
function processFile(file) {
  return new Promise((resolve, reject) => {
    const url = URL.createObjectURL(file);
    const img = new Image();
    img.onload = () => {
      try {
        const cv = document.createElement('canvas');
        cv.width = TARGET_W; cv.height = TARGET_H;
        const cx = cv.getContext('2d');
        cx.fillStyle = '#ffffff';
        cx.fillRect(0, 0, TARGET_W, TARGET_H);
        const s = Math.max(TARGET_W / img.width, TARGET_H / img.height);
        const w = img.width * s, h = img.height * s;
        cx.drawImage(img, (TARGET_W - w) / 2, (TARGET_H - h) / 2, w, h);
        URL.revokeObjectURL(url);
        resolve(cv.toDataURL('image/jpeg', 0.85));
      } catch (e) { reject(e); }
    };
    img.onerror = () => { URL.revokeObjectURL(url); reject(new Error('Rasm ochilmadi')); };
    img.src = url;
  });
}

async function setImage(id, file) {
  try {
    const dataUrl = await processFile(file);
    mem[id] = dataUrl;
    try { await idbPut(id, dataUrl); } catch (e) { /* faqat xotirada */ }
    render();
    toast('✅ Saqlandi (' + id + ')');
    // Cloud (R2) ga ham yuborish — token bo'lmasa endi jim turmaydi, ogohlantiradi
    try {
      const w = ALL.find((x) => String(x.id) === String(id));
      if (w && window.CloudSync) {
        window.CloudSync.uploadImage(w.file, dataUrl).then((r) => {
          if (r && r.ok) toast('☁️ Cloud ga ham yuklandi 📱');
          else if (r && r.error === 'no token') toast('⚠️ Faqat brauzerda saqlandi! Cloud token yozilmagan — APK ga chiqmaydi');
        });
      }
    } catch (e) { /* lokal yetadi */ }
  } catch (e) {
    toast('❌ Xato: rasm ochilmadi');
  }
}

// ---------- Chizish ----------
function filteredWords() {
  const q = $('search').value.trim().toLowerCase();
  const cat = $('catFilter').value;
  const st = $('statusFilter').value;
  return ALL.filter((w) => {
    if (cat && w.category !== cat) return false;
    if (st === 'with' && !mem[w.id]) return false;
    if (st === 'without' && mem[w.id]) return false;
    if (q && !(w.english.toLowerCase().includes(q) || w.uzbek.toLowerCase().includes(q) || w.file.includes(q))) return false;
    return true;
  });
}

function render() {
  const list = filteredWords();
  grid.innerHTML = '';
  $('empty').hidden = list.length > 0;
  const frag = document.createDocumentFragment();
  for (const w of list) {
    const has = !!mem[w.id];
    const card = document.createElement('div');
    card.className = 'card';
    card.dataset.id = w.id;

    const thumb = document.createElement('div');
    thumb.className = 'thumb';
    if (has) {
      const im = document.createElement('img');
      im.src = mem[w.id];
      im.alt = w.english;
      im.loading = 'lazy';
      thumb.appendChild(im);
    } else {
      // Faqat ro'yxatda bor fayl so'raladi — yo'q bo'lsa so'rov yuborilmaydi (404 chiqmaydi)
      const dp = deployedPath(w.file);
      if (dp) {
        const im = document.createElement('img');
        im.src = dp;
        im.alt = w.english;
        im.loading = 'lazy';
        im.onerror = () => { im.remove(); thumb.textContent = '🖼️'; };
        thumb.appendChild(im);
      } else {
        thumb.textContent = '🖼️';
      }
    }
    thumb.onclick = () => openModal(w);
    card.appendChild(thumb);

    const body = document.createElement('div');
    body.className = 'card-body';
    const tag = isCustom(w.id) ? ' <span class="cat">🆕</span>' : (overrides[w.id] ? ' <span class="cat">✏️</span>' : '');
    body.innerHTML =
      '<div class="row"><span class="en">#' + w.id + ' ' + escapeHtml(w.english) + '</span>' +
      '<span class="badge ' + (has ? 'ok' : 'no') + '">' + (has ? '✅' : '❌') + '</span></div>' +
      '<div class="uz">' + escapeHtml(w.uzbek) + '</div>' +
      '<div class="row"><span class="cat">' + escapeHtml(w.category) + '</span>' + tag + '</div>' +
      '<div class="fname">' + escapeHtml(w.file) + '</div>';

    const btns = document.createElement('div');
    btns.className = 'card-btns';

    const add = document.createElement('label');
    add.className = 'add';
    add.textContent = '+ Rasm';
    const inp = document.createElement('input');
    inp.type = 'file';
    inp.accept = 'image/*';
    inp.hidden = true;
    inp.onchange = () => { if (inp.files[0]) setImage(w.id, inp.files[0]); inp.value = ''; };
    add.appendChild(inp);

    const edt = document.createElement('button');
    edt.textContent = '✏️';
    edt.title = 'So‘zni tahrirlash';
    edt.onclick = () => openWordModal(w.id);

    const del = document.createElement('button');
    del.className = 'del';
    del.textContent = '🗑';
    del.title = 'Rasmni o‘chirish';
    del.disabled = !has;
    del.onclick = async () => {
      if (!confirm('“' + w.english + '” rasmi o‘chsinmi?')) return;
      delete mem[w.id];
      await idbDel(w.id);
      render();
      toast('🗑 Rasm o‘chirildi');
    };

    const dl = document.createElement('button');
    dl.className = 'dl';
    dl.textContent = '⬇';
    dl.title = 'Faylni to‘g‘ri nom bilan yuklash';
    dl.disabled = !has;
    dl.onclick = () => {
      const a = document.createElement('a');
      a.href = mem[w.id];
      a.download = w.file.replace(/\.png$/i, '.jpg');
      a.click();
    };

    btns.append(add, edt, del, dl);
    body.appendChild(btns);
    card.appendChild(body);

    // Drag & drop
    card.addEventListener('dragover', (e) => { e.preventDefault(); card.classList.add('dragover'); });
    card.addEventListener('dragleave', () => card.classList.remove('dragover'));
    card.addEventListener('drop', (e) => {
      e.preventDefault();
      card.classList.remove('dragover');
      const f = e.dataTransfer.files && e.dataTransfer.files[0];
      if (f && f.type.startsWith('image/')) setImage(w.id, f);
    });

    frag.appendChild(card);
  }
  grid.appendChild(frag);
  updateProgress();
}

function escapeHtml(s) {
  return String(s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
}

function updateProgress() {
  const n = ALL.filter((w) => mem[w.id]).length;
  $('doneCount').textContent = n;
  $('totalCount').textContent = ALL.length;
  $('progressBar').style.width = (ALL.length ? (n / ALL.length * 100).toFixed(1) : 0) + '%';
}

// ---------- Modal ----------
function openModal(w) {
  const src = mem[w.id] || deployedPath(w.file);
  const img = $('modalImg');
  if (src) {
    img.style.display = '';
    img.src = src;
    img.onerror = () => { img.style.display = 'none'; };
  } else {
    img.src = 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7';
    img.style.display = 'none';
  }
  $('modalCap').textContent = '#' + w.id + ' ' + w.english + ' — ' + w.uzbek + ' (' + w.file + ')' + (src ? '' : ' — rasm hali yo‘q');
  $('modal').hidden = false;
}
$('modalClose').onclick = () => ($('modal').hidden = true);
$('modal').onclick = (e) => { if (e.target.id === 'modal') $('modal').hidden = true; };

// ---------- Eksport ----------
function download(name, text, mime) {
  const a = document.createElement('a');
  a.href = URL.createObjectURL(new Blob([text], { type: mime || 'text/plain;charset=utf-8' }));
  a.download = name;
  a.click();
  setTimeout(() => URL.revokeObjectURL(a.href), 5000);
}

function dartEscape(s) {
  return s.replace(/\\/g, '\\\\').replace(/'/g, "\\'");
}

$('btnExportDart').onclick = () => {
  const withImg = ALL.filter((w) => mem[w.id]);
  if (!withImg.length) { toast('❌ Avval rasm qo‘shing'); return; }
  let out = '// Avto-generatsiya: Rasm Boshqarish sayti\n';
  out += '// ' + withImg.length + " ta rasmli so'z\n\n";
  out += 'const List<PictureWord> pictureWords = [\n';
  for (const w of withImg) {
    out += "  PictureWord(english: '" + dartEscape(w.english) + "', uzbek: '" + dartEscape(w.uzbek) +
      "', imagePath: 'assets/picture_quiz/" + w.file.replace(/\.png$/i, '.jpg') + "'),\n";
  }
  out += '];\n';
  download('picture_words.dart', out);
  toast('⬇️ picture_words.dart (' + withImg.length + ' ta)');
};

$('btnExportJson').onclick = () => {
  const map = ALL.map((w) => ({ id: w.id, english: w.english, uzbek: w.uzbek, category: w.category, file: w.file, custom: isCustom(w.id), hasImage: !!mem[w.id] }));
  download('manifest.json', JSON.stringify(map, null, 1), 'application/json');
};

$('btnMissing').onclick = () => {
  const miss = ALL.filter((w) => !mem[w.id]);
  const txt = 'Rasmi yo‘q: ' + miss.length + ' ta\n\n' + miss.map((w) => '#' + w.id + ' ' + w.english + ' — ' + w.uzbek + ' (' + w.file + ')').join('\n');
  download('missing.txt', txt);
};

// ---------- Bulk yuklash: fayl nomi bo'yicha avtomatik moslash ----------
const bulkInput = document.createElement('input');
bulkInput.type = 'file';
bulkInput.accept = 'image/*';
bulkInput.multiple = true;
bulkInput.hidden = true;
document.body.appendChild(bulkInput);
const bulkBtn = document.createElement('button');
bulkBtn.textContent = "📥 Ko'p rasm yuklash";
bulkBtn.title = 'Internetdan olingan rasmlarni bir vaqtda tanlang — nomi bo‘yicha avtomatik biriktiriladi';
bulkBtn.onclick = () => bulkInput.click();
document.querySelector('.actions').appendChild(bulkBtn);

function normName(n) {
  return n.toLowerCase().replace(/\.[a-z0-9]+$/i, '').replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
}
bulkInput.onchange = async () => {
  const bySlug = {};
  for (const w of ALL) bySlug[w.file.replace(/\.png$/i, '')] = w.id;
  let ok = 0, fail = 0;
  const doneIds = [];
  for (const f of bulkInput.files) {
    const id = bySlug[normName(f.name)];
    if (!id) { fail++; continue; }
    try {
      const dataUrl = await processFile(f);
      mem[id] = dataUrl;
      try { await idbPut(id, dataUrl); } catch (e) { /* ignore */ }
      ok++;
      doneIds.push(id);
    } catch (e) { fail++; }
  }
  bulkInput.value = '';
  render();
  toast('✅ ' + ok + ' ta biriktirildi' + (fail ? ', ❌ ' + fail + ' ta mos kelmadi' : ''));
  // Cloud (R2) ga ham yuborish
  try {
    if (window.CloudSync) {
      for (const bid of doneIds) {
        const bw = ALL.find((x) => String(x.id) === String(bid));
        if (bw && mem[bid]) window.CloudSync.uploadImage(bw.file, mem[bid]);
      }
      if (doneIds.length) {
        if (!window.CloudSync.token()) toast('⚠️ Rasmlar brauzerda! Cloud token yo‘q — APK ga chiqmaydi');
        else toast('☁️ Cloud ga yuklanmoqda...');
      }
    }
  } catch (e) { /* ignore */ }
};

$('btnClear').onclick = async () => {
  if (!confirm('Brauzerdagi barcha yuklangan rasmlar o‘chsinmi?')) return;
  for (const k of Object.keys(mem)) delete mem[k];
  await idbClear();
  render();
  toast('🗑 Tozalandi');
};

// ---------- So'z qo'shish / tahrirlash ----------
let editingId = null; // null = yangi so'z, aks holda tahrirlanayotgan id
function refreshCats() {
  const keep = $('catFilter').value;
  $('catFilter').innerHTML = '<option value="">Barcha bo‘limlar</option>';
  const cats = [...new Set(ALL.map((w) => w.category))].sort();
  for (const c of cats) {
    const o = document.createElement('option');
    o.value = c; o.textContent = c;
    $('catFilter').appendChild(o);
  }
  if (cats.includes(keep)) $('catFilter').value = keep;
  $('catList').innerHTML = cats.map((c) => '<option value="' + escapeHtml(c) + '">').join('');
}
function openWordModal(id) {
  editingId = id == null ? null : id;
  const w = id == null ? null : ALL.find((x) => String(x.id) === String(id));
  $('wTitle').textContent = w ? '✏️ Tahrirlash (#' + w.id + ')' : '＋ So‘z qo‘shish';
  $('fEn').value = w ? w.english : '';
  $('fUz').value = w ? w.uzbek : '';
  $('fCat').value = w ? w.category : '';
  $('fImg').value = '';
  const del = $('wDelete');
  if (!w) { del.hidden = true; }
  else if (isCustom(w.id)) { del.hidden = false; del.textContent = 'So‘zni o‘chirish 🗑'; }
  else if (overrides[w.id]) { del.hidden = false; del.textContent = 'Tahrirni bekor qilish ↩'; }
  else { del.hidden = true; }
  $('wmodal').hidden = false;
  setTimeout(() => $('fEn').focus(), 50);
}
function closeWordModal() { $('wmodal').hidden = true; editingId = null; }
$('btnAddWord').onclick = () => openWordModal(null);
$('wCancel').onclick = closeWordModal;
$('wmodal').onclick = (e) => { if (e.target.id === 'wmodal') closeWordModal(); };
$('wSave').onclick = async () => {
  const en = $('fEn').value.trim();
  const uz = $('fUz').value.trim();
  const cat = $('fCat').value.trim() || 'Umumiy';
  if (!en || !uz) { toast('❌ Inglizcha va o‘zbekchani yozing'); return; }
  const f = $('fImg').files[0];
  if (editingId == null) {
    const id = 'c' + Date.now();
    customs.push({ id, english: en, uzbek: uz, category: cat, file: slugify(en) });
    saveLocal(); refreshAll(); refreshCats();
    if (f) { await setImage(id, f); } else { render(); }
    toast('✅ Yangi so‘z qo‘shildi');
  } else {
    if (isCustom(editingId)) {
      const c = customs.find((x) => String(x.id) === String(editingId));
      if (c) { c.english = en; c.uzbek = uz; c.category = cat; }
    } else {
      overrides[editingId] = { english: en, uzbek: uz, category: cat };
    }
    saveLocal(); refreshAll(); refreshCats();
    if (f) { await setImage(editingId, f); } else { render(); }
    toast('✅ Saqlandi');
  }
  closeWordModal();
};
$('wDelete').onclick = async () => {
  if (editingId == null) return;
  if (isCustom(editingId)) {
    if (!confirm('Bu so‘z butunlay o‘chsinmi? (rasmi bilan)')) return;
    customs = customs.filter((x) => String(x.id) !== String(editingId));
    delete mem[editingId];
    await idbDel(editingId);
    toast('🗑 So‘z o‘chirildi');
  } else {
    delete overrides[editingId];
    toast('↩ Tahrir bekor qilindi');
  }
  saveLocal(); refreshAll(); refreshCats(); render();
  closeWordModal();
};

// ---------- Filtrlar ----------
$('search').oninput = render;
$('catFilter').onchange = render;
$('statusFilter').onchange = render;

// ---------- Start ----------
(async function init() {
  loadLocal();
  refreshAll();
  refreshCats();
  const saved = await idbGetAll();
  for (const r of saved) if (r && r.id && r.dataUrl) mem[r.id] = r.dataUrl;
  // O'chirilgan maxsus so'zlarning rasmlarini tozalash
  for (const k of Object.keys(mem)) {
    if (isCustom(k) && !customs.find((x) => String(x.id) === String(k))) delete mem[k];
  }
  render();
})();
