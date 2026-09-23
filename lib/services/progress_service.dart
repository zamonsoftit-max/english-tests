// ignore_for_file: prefer_const_constructors
import 'package:shared_preferences/shared_preferences.dart';
import '../data/words.dart';
import '../models/word.dart';

class ProgressService {
  static const _kTotalTests = 'total_tests';
  static const _kTotalCorrect = 'total_correct';
  static const _kTotalQuestions = 'total_questions';
  static const _kBestScore = 'best_score';
  static const _kMistakes = 'mistake_words'; // english so'zlar ro'yxati
  static const _kStars = 'total_stars'; // ⭐ yulduzlar balansi
  static const _kUnlocked = 'unlocked_categories'; // ochilgan kategoriyalar
  static const _kBonusGiven = 'welcome_bonus_given'; // 10 ⭐ bonus berilganmi
  static const _kBonusV2 = 'welcome_bonus_v2_given'; // eski versiyadagilarga qayta bonus
  static const int welcomeBonusStars = 10;

  static Future<void> saveTestResult({
    required int correct,
    required int total,
    required List<Word> wrongWords,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final totalTests = prefs.getInt(_kTotalTests) ?? 0;
    final totalCorrect = prefs.getInt(_kTotalCorrect) ?? 0;
    final totalQuestions = prefs.getInt(_kTotalQuestions) ?? 0;
    final best = prefs.getInt(_kBestScore) ?? 0;
    final stars = prefs.getInt(_kStars) ?? 0;

    await prefs.setInt(_kTotalTests, totalTests + 1);
    await prefs.setInt(_kTotalCorrect, totalCorrect + correct);
    await prefs.setInt(_kTotalQuestions, totalQuestions + total);
    // Har bir to'g'ri javob = 1 ⭐ yulduz
    await prefs.setInt(_kStars, stars + correct);
    if (correct > best) {
      await prefs.setInt(_kBestScore, correct);
    }

    // xatolarni qo'shish
    final old = prefs.getStringList(_kMistakes) ?? <String>[];
    final set = old.toSet();
    for (final w in wrongWords) {
      set.add(w.english);
    }
    await prefs.setStringList(_kMistakes, set.toList());
  }

  static Future<Map<String, int>> getStats() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'tests': prefs.getInt(_kTotalTests) ?? 0,
      'correct': prefs.getInt(_kTotalCorrect) ?? 0,
      'questions': prefs.getInt(_kTotalQuestions) ?? 0,
      'best': prefs.getInt(_kBestScore) ?? 0,
      'stars': prefs.getInt(_kStars) ?? 0,
    };
  }

  // ---------- 🎁 Bonus tizimi (k first kirishda 10 ⭐) ----------

  /// Shu app ishga tushishida bonus berildimi (main yoki Home dan qat'i nazar).
  /// Dialogni bir marta ko'rsatish uchun ishlatiladi.
  static bool bonusGrantedThisLaunch = false;

  /// Ilk kirishda 10 ⭐ bonus beradi. Faqat bir marta ishlaydi.
  /// Agar shu ishga tushishda berilgan bo'lsa true qaytadi (dialog ko'rsatish uchun).
  static Future<bool> ensureWelcomeBonus() async {
    final prefs = await SharedPreferences.getInstance();
    // V2 migratsiya: eski flag true bo'lsa ham bir marta qayta +10 beramiz,
    // shunda yangilagan foydalanuvchi ham bonusni ko'radi.
    final v2given = prefs.getBool(_kBonusV2) ?? false;
    if (!v2given) {
      final stars = prefs.getInt(_kStars) ?? 0;
      await prefs.setInt(_kStars, stars + welcomeBonusStars);
      await prefs.setBool(_kBonusGiven, true);
      await prefs.setBool(_kBonusV2, true);
      bonusGrantedThisLaunch = true;
      return true;
    }
    final given = prefs.getBool(_kBonusGiven) ?? false;
    if (given) {
      // Oldin berilgan bo'lsa ham, shu launchda berilgan bo'lsa dialog uchun true
      return bonusGrantedThisLaunch;
    }
    final stars = prefs.getInt(_kStars) ?? 0;
    await prefs.setInt(_kStars, stars + welcomeBonusStars);
    await prefs.setBool(_kBonusGiven, true);
    await prefs.setBool(_kBonusV2, true);
    bonusGrantedThisLaunch = true;
    return true;
  }

  static Future<bool> isWelcomeBonusGiven() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kBonusGiven) ?? false;
  }

  // ---------- ⭐ Yulduz tizimi ----------

  static Future<int> getStars() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kStars) ?? 0;
  }

  static Future<void> addStars(int n) async {
    if (n <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kStars, (prefs.getInt(_kStars) ?? 0) + n);
  }

  /// Ochiq kategoriyalar ro'yxati. Birinchi marta ['Kundalik'] qaytadi.
  static Future<List<String>> getUnlockedCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kUnlocked);
    if (list == null) {
      await prefs.setStringList(_kUnlocked, defaultUnlockedCategories);
      return List<String>.from(defaultUnlockedCategories);
    }
    // Eski versiyadan yangilanganlarda Kundalik doim ochiq bo'lsin
    if (!list.contains('Kundalik')) {
      list.add('Kundalik');
      await prefs.setStringList(_kUnlocked, list);
    }
    return list;
  }

  static Future<bool> isCategoryUnlocked(String category) async {
    if (categoryUnlockCost(category) == 0) return true;
    final unlocked = await getUnlockedCategories();
    return unlocked.contains(category);
  }

  /// Kategoriyani yulduz evaziga ochish.
  /// Yulduz yetsa true qaytadi va yulduz ayiriladi, yetmasa false.
  static Future<bool> unlockCategory(String category) async {
    final cost = categoryUnlockCost(category);
    if (cost == 0) return true;
    final prefs = await SharedPreferences.getInstance();
    final unlocked = await getUnlockedCategories();
    if (unlocked.contains(category)) return true;
    final stars = prefs.getInt(_kStars) ?? 0;
    if (stars < cost) return false;
    await prefs.setInt(_kStars, stars - cost);
    unlocked.add(category);
    await prefs.setStringList(_kUnlocked, unlocked);
    return true;
  }

  static Future<List<Word>> getMistakes() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kMistakes) ?? <String>[];
    final map = {for (final w in allWords) w.english: w};
    return [for (final e in list) if (map.containsKey(e)) map[e]!];
  }

  static Future<void> removeMistake(String english) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kMistakes) ?? <String>[];
    list.remove(english);
    await prefs.setStringList(_kMistakes, list);
  }

  static Future<void> addMistake(String english) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kMistakes) ?? <String>[];
    if (!list.contains(english)) {
      list.add(english);
      await prefs.setStringList(_kMistakes, list);
    }
  }

  static Future<void> clearMistakes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kMistakes);
  }

  static Future<void> resetStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTotalTests);
    await prefs.remove(_kTotalCorrect);
    await prefs.remove(_kTotalQuestions);
    await prefs.remove(_kBestScore);
    await prefs.remove(_kStars);
    await prefs.remove(_kUnlocked);
    await prefs.remove(_kBonusGiven);
    await prefs.remove(_kBonusV2);
    bonusGrantedThisLaunch = false;
  }
}
