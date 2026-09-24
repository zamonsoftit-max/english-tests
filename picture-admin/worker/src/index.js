// English Test — Cloudflare Workers backend (to'liq backend).
// KV: so'zlar JSON. R2: rasmlar. Admin token bilan himoyalangan.
//
// Routes:
//   GET  /api/health
//   GET  /api/words            -> { updatedAt, count, words: [{id,english,uzbek,category,file,imageUrl}] }
//   PUT  /api/words            -> Bearer ADMIN_TOKEN, body {words:[...]} -> KV ga saqlaydi
//   POST /api/upload?file=xxx  -> Bearer ADMIN_TOKEN, body: rasm baytlari -> R2 ga saqlaydi
//   GET  /images/<file>        -> R2 dan rasm beradi
//
// Sozlash: worker/README-BACKEND.md ga qarang.

function corsHeaders(req, env) {
  const origin = req.headers.get('Origin') || '*';
  const allowed = env.ALLOWED_ORIGIN || '*';
  return {
    'Access-Control-Allow-Origin': allowed === '*' ? origin : allowed,
    'Access-Control-Allow-Methods': 'GET, PUT, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Max-Age': '86400',
  };
}

function json(data, status = 200, req = null, env = null) {
  const h = { 'Content-Type': 'application/json; charset=utf-8' };
  if (req && env) Object.assign(h, corsHeaders(req, env));
  return new Response(JSON.stringify(data), { status, headers: h });
}

function needAdmin(req, env) {
  const auth = req.headers.get('Authorization') || '';
  const token = auth.startsWith('Bearer ') ? auth.slice(7) : '';
  if (!env.ADMIN_TOKEN || token !== env.ADMIN_TOKEN) return false;
  return true;
}

function cleanWord(w, i) {
  const english = String(w.english || '').trim().slice(0, 60);
  const uzbek = String(w.uzbek || '').trim().slice(0, 60);
  const category = String(w.category || 'Umumiy').trim().slice(0, 30) || 'Umumiy';
  const file = String(w.file || '').trim().slice(0, 80) || ('word-' + (i + 1) + '.png');
  if (!english || !uzbek) return null;
  return { id: w.id ?? i + 1, english, uzbek, category, file };
}

export default {
  async fetch(req, env) {
    const url = new URL(req.url);
    const path = url.pathname;

    // Preflight
    if (req.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: corsHeaders(req, env) });
    }

    // Health
    if (path === '/api/health') {
      return json({ ok: true, time: new Date().toISOString() }, 200, req, env);
    }

    // Words o'qish — ochiq (ilovalar o'qiydi)
    if (path === '/api/words' && req.method === 'GET') {
      try {
        const raw = env.WORDS_KV ? await env.WORDS_KV.get('words_v1') : null;
        if (!raw) return json({ updatedAt: null, count: 0, words: [] }, 200, req, env);
        const data = JSON.parse(raw);
        return json(data, 200, req, env);
      } catch (e) {
        return json({ error: 'KV read failed: ' + e.message }, 500, req, env);
      }
    }

    // Words yozish — faqat admin
    if (path === '/api/words' && (req.method === 'PUT' || req.method === 'POST')) {
      if (!needAdmin(req, env)) return json({ error: 'unauthorized' }, 401, req, env);
      try {
        const body = await req.json();
        const arr = Array.isArray(body.words) ? body.words : [];
        if (arr.length > 5000) return json({ error: 'too many words' }, 400, req, env);
        const cleaned = [];
        for (let i = 0; i < arr.length; i++) {
          const c = cleanWord(arr[i], i);
          if (c) cleaned.push(c);
        }
        const data = { updatedAt: new Date().toISOString(), count: cleaned.length, words: cleaned };
        if (env.WORDS_KV) await env.WORDS_KV.put('words_v1', JSON.stringify(data));
        else return json({ error: 'KV not bound' }, 500, req, env);
        return json({ ok: true, count: cleaned.length, updatedAt: data.updatedAt }, 200, req, env);
      } catch (e) {
        return json({ error: 'save failed: ' + e.message }, 500, req, env);
      }
    }

    // Rasm yuklash — faqat admin. Body: raw image bytes, ?file=apple.png
    if (path === '/api/upload' && req.method === 'POST') {
      if (!needAdmin(req, env)) return json({ error: 'unauthorized' }, 401, req, env);
      try {
        const file = (url.searchParams.get('file') || '').replace(/[^a-z0-9\-\.]+/gi, '-').slice(0, 80);
        if (!file) return json({ error: 'file param required' }, 400, req, env);
        const ct = req.headers.get('Content-Type') || 'image/jpeg';
        const buf = await req.arrayBuffer();
        if (!buf || buf.byteLength === 0) return json({ error: 'empty body' }, 400, req, env);
        if (buf.byteLength > 5 * 1024 * 1024) return json({ error: 'file too big (max 5MB)' }, 400, req, env);
        if (env.IMAGES_BUCKET) {
          await env.IMAGES_BUCKET.put('images/' + file, buf, {
            // DIQQAT: immutable 1 yil qo'ysangiz — bir xil nomdagi rasm
            // yangilanganda telefonlar eskisini ko'rsataveradi.
            // Shuning uchun qisqa kesh (60 sek) + Flutter ?v=updatedAt beradi.
            httpMetadata: { contentType: ct, cacheControl: 'public, max-age=60, must-revalidate' },
          });
        } else {
          return json({ error: 'R2 not bound' }, 500, req, env);
        }
        return json({ ok: true, file, url: '/images/' + file }, 200, req, env);
      } catch (e) {
        return json({ error: 'upload failed: ' + e.message }, 500, req, env);
      }
    }

    // Rasm o'qish — ochiq
    if (path.startsWith('/images/') && req.method === 'GET') {
      try {
        if (!env.IMAGES_BUCKET) return new Response('R2 not bound', { status: 500 });
        const key = path.slice(1); // images/xxx
        const obj = await env.IMAGES_BUCKET.get(key);
        if (!obj) return new Response('Not found', { status: 404 });
        const headers = new Headers();
        obj.writeHttpMetadata(headers);
        // Yangi rasm tez ko'rinishi uchun qisqa kesh (Eski: 1 yil immutable edi).
        headers.set('Cache-Control', 'public, max-age=60, must-revalidate');
        headers.set('ETag', obj.etag || '');
        headers.set('Access-Control-Allow-Origin', '*');
        return new Response(obj.body, { headers });
      } catch (e) {
        return new Response('R2 read failed', { status: 500 });
      }
    }

    return json({ error: 'not found' }, 404, req, env);
  },
};
