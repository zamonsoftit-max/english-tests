import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/word.dart';
import '../data/words.dart';
import '../data/picture_words.dart';

// Worker manzilini shu yerga yozing (deploydan keyin).
// Masalan: https://english-test-api.siz.workers.dev
const String kApiBase = 'https://english-test-api.picture-admin.workers.dev';

/// Cloudflare Worker dagi so'zlarni yuklab, lokal const ro'yxatlarni almashtiradi.
/// Internet bo'lmasa yoki API_BASE bo'sh bo'lsa — built-in ro'yxat ishlayveradi.
class RemoteConfig {
  static const _kCacheWords = 'remote_words_json';
  static const _kCacheTime = 'remote_words_time';

  static Future<void> syncOnStartup() async {
    // 1. Avval keshni yuklash (tez ochilishi uchun)
    await _applyCache();
    // 2. Keyin tarmoqdan yangilash
    if (kApiBase.isEmpty) return;
    try {
      final r = await http
          .get(Uri.parse('$kApiBase/api/words'))
          .timeout(const Duration(seconds: 8));
      if (r.statusCode != 200) return;
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      final list = (data['words'] as List?) ?? [];
      if (list.isEmpty) return;
      final version = (data['updatedAt'] ?? '').toString();
      _applyRemote(list, version);
      // Keshga saqlash (version bilan — yangi rasm ?v=... bilan keladi)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kCacheWords, jsonEncode(list));
      await prefs.setString(_kCacheTime, version.isNotEmpty ? version : DateTime.now().toIso8601String());
    } catch (_) {
      // Offline — jimjimador fallback
    }
  }

  static Future<void> _applyCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kCacheWords);
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw) as List;
      if (list.isEmpty) return;
      final version = prefs.getString(_kCacheTime) ?? '';
      _applyRemote(list, version);
    } catch (_) {}
  }

  static void _applyRemote(List list, [String version = '']) {
    final words = <Word>[];
    final pics = <PictureWord>[];
    for (final e in list) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final w = Word.fromJson(m);
      if (w.english.isEmpty || w.uzbek.isEmpty) continue;
      words.add(w);
      pics.add(PictureWord.fromJson(m, kApiBase, version));
    }
    if (words.isNotEmpty) {
      allWords = words;
      pictureWords = pics;
    }
  }
}
