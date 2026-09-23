// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import '../data/words.dart';
import '../models/word.dart';
import '../services/progress_service.dart';
import 'quiz_screen.dart';
import 'flashcards_screen.dart';
import 'mistakes_screen.dart';
import 'categories_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, int> _stats = {'tests': 0, 'correct': 0, 'questions': 0, 'best': 0, 'stars': 0};
  int _mistakeCount = 0;
  Set<String> _unlocked = {'Kundalik'};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // 1-kirishda 10 ⭐ bonus beriladi (faqat bir marta, shu launchda dialog bilan)
    final bonusGivenNow = await ProgressService.ensureWelcomeBonus();
    final s = await ProgressService.getStats();
    final m = await ProgressService.getMistakes();
    final u = await ProgressService.getUnlockedCategories();
    if (!mounted) return;
    setState(() {
      _stats = s;
      _mistakeCount = m.length;
      _unlocked = u.toSet();
    });
    if (bonusGivenNow && mounted) {
      // Qayta kirishlarda dialog takrorlanmasligi uchun darhol sarflaymiz
      ProgressService.bonusGrantedThisLaunch = false;
      // UI to'liq chizilishini kutamiz, keyin dialog + snackbar
      await Future.delayed(Duration(milliseconds: 500));
      if (!mounted) return;
      _showBonusDialog();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('+10 ⭐ Bonus hisobingizga qo‘shildi!',
              style: TextStyle(fontWeight: FontWeight.bold)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.amber[700],
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  int get _stars => _stats['stars'] ?? 0;

  bool _isOpen(String c) {
    if (categoryUnlockCost(c) == 0) return true;
    return _unlocked.contains(c);
  }

  double get _accuracy {
    final q = _stats['questions'] ?? 0;
    if (q == 0) return 0;
    return ((_stats['correct'] ?? 0) / q * 100);
  }

  void _go(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    ).then((_) => _load());
  }

  void _startCategoryTest(String category, QuizMode mode) {
    _go(QuizScreen(mode: mode, category: category));
  }

  Future<void> _tryUnlock(String category) async {
    final cost = categoryUnlockCost(category);
    final ok = await ProgressService.unlockCategory(category);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$category ochildi! 🎉 Testni boshlang')),
      );
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Yulduz yetmaydi! $cost ⭐ kerak, sizda $_stars ⭐ bor. Test ishlang!')),
      );
    }
  }

  void _showBonusDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🎁', style: TextStyle(fontSize: 56)),
            SizedBox(height: 8),
            Text('Xush kelibsiz!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              'Sizga bonus sifatida 10 ⭐ berildi!\nYulduz yig‘ib yangi bo‘limlarni oching.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.shade700),
              ),
              child: Text('⭐ 10 bonus',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
                minimumSize: Size(double.infinity, 48)),
            child: Text('Boshlash 🚀'),
          ),
        ],
      ),
    );
  }

  void _showUnlockDialog(String category) {
    final cost = categoryUnlockCost(category);
    final enough = _stars >= cost;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                categoryImage(category),
                width: 44,
                height: 44,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    Text(categoryEmoji(category),
                        style: TextStyle(fontSize: 32)),
              ),
            ),
            SizedBox(width: 10),
            Expanded(child: Text(category)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🔒 Bu bo‘lim yopiq. Ochish uchun $cost ⭐ kerak.'),
            SizedBox(height: 8),
            Text('Sizda: $_stars ⭐',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              'Har bir to‘g‘ri javobga +1 ⭐ beriladi. Ochiq bo‘limlarda test ishlang!',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Keyinroq'),
          ),
          FilledButton.icon(
            onPressed: enough
                ? () async {
                    Navigator.pop(context);
                    await _tryUnlock(category);
                  }
                : null,
            icon: Icon(Icons.star),
            label: Text('$cost ⭐ ga ochish'),
          ),
        ],
      ),
    );
  }

  void _showCategorySheet(String category) {
    if (!_isOpen(category)) {
      _showUnlockDialog(category);
      return;
    }
    final count = wordCountByCategory(category);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)),
                ),
              ),
              SizedBox(height: 12),
              // Bo'lim rasmi — o'z nomiga mos
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    categoryImage(category),
                    width: 96,
                    height: 96,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Text(
                        categoryEmoji(category),
                        style: TextStyle(fontSize: 64)),
                  ),
                ),
              ),
              SizedBox(height: 8),
              Text('$category ($count ta so‘z)',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Center(
                child: Text('Har to‘g‘ri javob = +1 ⭐',
                    style: TextStyle(
                        color: Colors.amber[800],
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
              SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _startCategoryTest(category, QuizMode.enToUz);
                },
                icon: Icon(Icons.translate),
                label: Text('EN → UZ test'),
                style: FilledButton.styleFrom(minimumSize: Size(double.infinity, 52)),
              ),
              SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.pop(context);
                  _startCategoryTest(category, QuizMode.uzToEn);
                },
                icon: Icon(Icons.swap_horiz),
                label: Text('UZ → EN test'),
                style: FilledButton.styleFrom(minimumSize: Size(double.infinity, 52)),
              ),
              SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _go(FlashcardsScreen(initialCategory: category));
                },
                icon: Icon(Icons.style),
                label: Text('Flashcard'),
                style: OutlinedButton.styleFrom(minimumSize: Size(double.infinity, 52)),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  // Rasmli test vaqtincha o'chirilgan (faqat so'zlar rejimi).
  // Qaytarish uchun bu funksiyani tiklash kifoya.
/*
  void _showPictureSheet() {
    // Rasimli test uchun mavzu tanlash: ustida rasm, tagida javoblar
    // Faqat aniq rasmlar (Kundalik / Fe'l / Sifat kirmaydi — fotolari noto'g'ri)
    int countFor(List<String>? cats) {
      return pictureCountFor(cats);
    }

    // Faqat rasmga tushadigan aniq kategoriyalar
    final pictureCats =
        categoriesByDifficulty.where((c) => pictureCategories.contains(c)).toList();

    Widget picButton({
      required String emoji,
      required String title,
      required String subtitle,
      required List<String>? cats,
      required Color color,
      String? imagePath,
    }) {
      return Card(
        margin: EdgeInsets.only(bottom: 10),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.pop(context);
            _go(PictureQuizScreen(categories: cats));
          },
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: imagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            imagePath,
                            width: 44,
                            height: 44,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Text(emoji,
                                style: TextStyle(fontSize: 28)),
                          ),
                        )
                      : Text(emoji, style: TextStyle(fontSize: 28)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text(subtitle,
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Rasmli test 🖼️',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Ustida rasm, tagida 4 ta javob • 10 savol • +1 ⭐',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                SizedBox(height: 16),
                picButton(
                  emoji: '🍎🥕',
                  title: 'Meva-Sabzavot aralash',
                  subtitle:
                      '${countFor(['Meva', 'Sabzavot'])} ta rasm • Tavsiya etiladi',
                  cats: ['Meva', 'Sabzavot'],
                  color: Color(0xFFE67E22),
                ),
                picButton(
                  emoji: '🍎',
                  title: 'Faqat Mevalar',
                  subtitle: '${countFor(['Meva'])} ta rasm • 10 savol',
                  cats: ['Meva'],
                  color: Color(0xFFE74C3C),
                  imagePath: categoryImage('Meva'),
                ),
                picButton(
                  emoji: '🥕',
                  title: 'Faqat Sabzavotlar',
                  subtitle: '${countFor(['Sabzavot'])} ta rasm • 10 savol',
                  cats: ['Sabzavot'],
                  color: Color(0xFF27AE60),
                  imagePath: categoryImage('Sabzavot'),
                ),
                picButton(
                  emoji: '🖼️',
                  title: 'Barchasi aralash',
                  subtitle:
                      '${countFor(null)} ta rasm • Har safar tasodifiy 10 ta',
                  cats: null,
                  color: Color(0xFF6C5CE7),
                ),
                SizedBox(height: 8),
                Text('Aniq mavzular • ${pictureCats.length} ta bo‘lim',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700])),
                SizedBox(height: 4),
                Text(
                    'Mavhum so‘zlar (salom, yaxshi, yugurmoq) rasmga tushmaydi — shuning uchun faqat aniq otlar qoldirildi',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                SizedBox(height: 8),
                // Har bir bo'lim alohida rasmli test — faqat aniq rasmlar.
                ...pictureCats.map((c) {
                  final colors = [
                    Color(0xFF6C5CE7),
                    Color(0xFF0984E3),
                    Color(0xFFE67E22),
                    Color(0xFF00B894),
                    Color(0xFFD63031),
                    Color(0xFFE84393),
                  ];
                  final color =
                      colors[pictureCats.indexOf(c) % colors.length];
                  final n = countFor([c]);
                  return picButton(
                    emoji: categoryEmoji(c),
                    title: c,
                    subtitle: '$n ta rasm • 10 savol',
                    cats: [c],
                    color: color,
                    imagePath: categoryImage(c),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
*/

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 360;
    // Eng oson 6 bo'lim bosh sahifada ko'rsatiladi (osondan qiyinga)
    const featured = ['Kundalik', 'Oila', 'Ovqat', 'Maktab', 'Tana', 'Sifat'];
    // Kichik telefonlarda kartalar sig'ishi uchun nisbat moslashadi.
    // Hujayra ataylab balandroq olingan — aks holda ichidagi matn
    // sig'may "Bottom overflowed" xatosi chiqadi.
    final gridAspect = isSmall ? 0.82 : 1.0;

    return Scaffold(
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 600),
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  // Ichidagi matn + chiplar sig'may "Bottom overflowed"
                  // chiqmasligi uchun balandlik zaxira bilan olingan.
                  expandedHeight: isSmall ? 208 : 224,
                  pinned: true,
                  // ⭐ Yulduzlar soni doim o'ng tepada ko'rinadi
                  actions: [
                    Padding(
                      padding: EdgeInsets.only(right: 12, top: 8, bottom: 8),
                      child: Center(child: _topStarsBadge()),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF6C5CE7), Color(0xFF00CEC9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: EdgeInsets.all(isSmall ? 16 : 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('Salom! 👋',
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: isSmall ? 14 : 16)),
                              Text(
                                'English Test',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isSmall ? 24 : 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "So'z yodlash — test usuli bilan",
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: isSmall ? 13 : 15),
                              ),
                              SizedBox(height: isSmall ? 8 : 12),
                              // Telefonda sig'may qolsa pastga tushadi
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _statChip('⭐ $_stars', isSmall),
                                  _statChip('${_stats['tests']} test', isSmall),
                                  _statChip('${_accuracy.toStringAsFixed(0)}% aniqlik', isSmall),
                                  _statChip('Rekord: ${_stats['best']}/10', isSmall),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _menuCard(
                        icon: Icons.translate,
                        color: Color(0xFF6C5CE7),
                        title: 'EN → UZ test',
                        subtitle: 'Bo‘lim tanlang: Oila, Ovqat, Maktab... +1 ⭐',
                        onTap: () => _go(CategoriesScreen(fixedMode: QuizMode.enToUz)),
                      ),
                      _menuCard(
                        icon: Icons.swap_horiz,
                        color: Color(0xFF0984E3),
                        title: 'UZ → EN test',
                        subtitle: 'Bo‘lim tanlang, to‘g‘ri javobga +1 ⭐',
                        onTap: () => _go(CategoriesScreen(fixedMode: QuizMode.uzToEn)),
                      ),
                      // Rasmli test vaqtincha o'chirilgan — faqat so'zlar rejimi.
                      _menuCard(
                        icon: Icons.style,
                        color: Color(0xFF00B894),
                        title: 'Flashcard',
                        subtitle: 'Kartochkalarni aylantirib yodlash',
                        onTap: () => _go(FlashcardsScreen()),
                      ),
                      _menuCard(
                        icon: Icons.error_outline,
                        color: Color(0xFFD63031),
                        title: 'Xatolar ustida ishlash',
                        subtitle: _mistakeCount == 0
                            ? 'Hozircha xato yo\'q — ajoyib!'
                            : '$_mistakeCount ta so\'zda xato qilgansiz',
                        trailing: _mistakeCount > 0
                            ? Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Color(0xFFD63031),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('$_mistakeCount',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              )
                            : null,
                        onTap: () => _go(MistakesScreen()),
                      ),

                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Bo‘limlar ⭐',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          TextButton(
                            onPressed: () => _go(CategoriesScreen()),
                            child: Text('Barchasi ➜'),
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Birinchi kirishda 10 ⭐ bonus! Har to‘g‘ri javob +1 ⭐. Bo‘limlar osondan qiyinga +10 ⭐ dan ochiladi! 🔓',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ),
                      SizedBox(height: 8),
                      // Telefon: 2 ustunli grid, har biri katta bosiladigan
                      // isSmall telefonlarda balandlikka joy qoldirish uchun 0.92
                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: gridAspect,
                        ),
                        itemCount: featured.length,
                        itemBuilder: (_, i) {
                          final c = featured[i];
                          final count = wordCountByCategory(c);
                          final order = categoriesByDifficulty.indexOf(c) + 1;
                          return _categoryCard(c, count, order, isSmall: isSmall);
                        },
                      ),
                      SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _go(CategoriesScreen()),
                          icon: Icon(Icons.grid_view),
                          label: Text('Barcha kategoriyalar (${categoriesByDifficulty.length} ta)'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text('Statistikani tozalash?'),
                              content: Text('Barcha natija va xatolar o\'chadi.'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: Text('Bekor qilish')),
                                FilledButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: Text('Ha, tozalash')),
                              ],
                            ),
                          );
                          if (ok == true) {
                            await ProgressService.resetStats();
                            await ProgressService.clearMistakes();
                            _load();
                          }
                        },
                        icon: Icon(Icons.refresh),
                        label: Text('Statistikani tozalash (qayta 10 ⭐ bonus)'),
                        style: OutlinedButton.styleFrom(minimumSize: Size(double.infinity, 48)),
                      ),
                      SizedBox(height: 24),
                      Center(
                          child: Text('${allWords.length} ta so‘z • 10 savollik testlar • +1 ⭐ / to‘g‘ri javob',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey))),
                      SizedBox(height: 16),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryCard(String category, int count, int order, {bool isSmall = false}) {
    final open = _isOpen(category);
    final cost = categoryUnlockCost(category);
    return Card(
      margin: EdgeInsets.zero,
      color: open ? null : Colors.grey.shade100,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showCategorySheet(category),
        child: Padding(
          padding: EdgeInsets.all(isSmall ? 10 : 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tartib raqami (1-oson ... 15-qiyin)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: open
                      ? Color(0xFF6C5CE7).withValues(alpha: 0.12)
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  cost == 0 ? '$order • Bepul' : '$order • $cost ⭐',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: open ? Color(0xFF6C5CE7) : Colors.grey[800],
                  ),
                ),
              ),
              SizedBox(height: 4),
              Stack(
                alignment: Alignment.center,
                children: [
                  // Bo'lim nomiga mos rasm (topilmasa emoji)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      categoryImage(category),
                      width: isSmall ? 48 : 56,
                      height: isSmall ? 48 : 56,
                      fit: BoxFit.contain,
                      color: open
                          ? null
                          : Colors.grey.withValues(alpha: 0.7),
                      colorBlendMode:
                          open ? null : BlendMode.saturation,
                      errorBuilder: (_, __, ___) => Text(
                          categoryEmoji(category),
                          style: TextStyle(
                              fontSize: isSmall ? 30 : 36)),
                    ),
                  ),
                  if (!open)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.lock,
                            size: 18, color: Colors.grey[700]),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 6),
              Text(category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: isSmall ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: open ? null : Colors.grey[600])),
              SizedBox(height: 2),
              Text('$count ta so‘z',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              SizedBox(height: 6),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: open
                      ? Color(0xFF6C5CE7).withValues(alpha: 0.12)
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!open) ...[
                      Icon(Icons.lock, size: 12, color: Colors.grey[700]),
                      SizedBox(width: 4),
                    ],
                    Flexible(
                      child: Text(
                          open ? 'Test boshlash' : '$cost ⭐ ga ochish',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: open
                                  ? Color(0xFF6C5CE7)
                                  : Colors.grey[800],
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topStarsBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.shade700, width: 1.2),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('⭐', style: TextStyle(fontSize: 16)),
          SizedBox(width: 4),
          Text('$_stars',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.brown[800])),
        ],
      ),
    );
  }

  Widget _statChip(String text, [bool isSmall = false]) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 9 : 12, vertical: isSmall ? 4 : 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
              color: Colors.white,
              fontSize: isSmall ? 11 : 12,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _menuCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ),
              trailing ?? Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
