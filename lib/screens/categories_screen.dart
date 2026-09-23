// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import '../data/words.dart';
import '../models/word.dart';
import '../services/progress_service.dart';
import 'quiz_screen.dart';
import 'flashcards_screen.dart';

class CategoriesScreen extends StatefulWidget {
  /// Agar berilsa (EN->UZ yoki UZ->EN tugmasidan kelinsa),
  /// kategoriya bosilganda to'g'ridan-to'g'ri shu yo'nalishda test boshlanadi.
  final QuizMode? fixedMode;
  const CategoriesScreen({super.key, this.fixedMode});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  int _stars = 0;
  Set<String> _unlocked = {'Kundalik'};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await ProgressService.ensureWelcomeBonus();
    final stars = await ProgressService.getStars();
    final unlocked = await ProgressService.getUnlockedCategories();
    if (!mounted) return;
    setState(() {
      _stars = stars;
      _unlocked = unlocked.toSet();
      _loading = false;
    });
  }

  bool _isOpen(String c) {
    if (categoryUnlockCost(c) == 0) return true;
    return _unlocked.contains(c);
  }

  String get _modeLabel {
    if (widget.fixedMode == QuizMode.enToUz) return 'EN → UZ • Bo‘lim tanlang';
    if (widget.fixedMode == QuizMode.uzToEn) return 'UZ → EN • Bo‘lim tanlang';
    return 'Kategoriyalar (${categoriesByDifficulty.length} ta so‘z turkumi)';
  }

  void _onCategoryTap(String category) {
    if (!_isOpen(category)) {
      _showUnlockDialog(category);
      return;
    }
    // EN->UZ yoki UZ->EN tugmasidan kelingan bo'lsa — darhol test boshlash
    if (widget.fixedMode != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuizScreen(mode: widget.fixedMode!, category: category),
        ),
      ).then((_) => _load());
      return;
    }
    _showModeSheet(context, category);
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
            if (!enough) ...[
              SizedBox(height: 8),
              Text(
                'Yulduz yetmayapti! Ochiq bo‘limlarda test ishlang — har bir to‘g‘ri javobga +1 ⭐ beriladi.',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
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
                    final ok =
                        await ProgressService.unlockCategory(category);
                    if (!mounted) return;
                    Navigator.pop(context);
                    if (ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                '$category ochildi! 🎉 Testni boshlang')),
                      );
                      _load();
                    }
                  }
                : null,
            icon: Icon(Icons.star),
            label: Text('$cost ⭐ ga ochish'),
          ),
        ],
      ),
    );
  }

  void _startQuiz(BuildContext context, String category, QuizMode mode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(mode: mode, category: category),
      ),
    ).then((_) => _load());
  }

  void _openFlashcards(BuildContext context, String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlashcardsScreen(initialCategory: category),
      ),
    ).then((_) => _load());
  }

  void _showModeSheet(BuildContext context, String category) {
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
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
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
              Text(
                '$category ($count ta so‘z)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Center(
                child: Text('Har to‘g‘ri javob = +1 ⭐',
                    style: TextStyle(color: Colors.amber[800], fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _startQuiz(context, category, QuizMode.enToUz);
                },
                icon: Icon(Icons.translate),
                label: Text('EN → UZ test'),
                style: FilledButton.styleFrom(minimumSize: Size(double.infinity, 52)),
              ),
              SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.pop(context);
                  _startQuiz(context, category, QuizMode.uzToEn);
                },
                icon: Icon(Icons.swap_horiz),
                label: Text('UZ → EN test'),
                style: FilledButton.styleFrom(minimumSize: Size(double.infinity, 52)),
              ),
              SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _openFlashcards(context, category);
                },
                icon: Icon(Icons.style),
                label: Text('Flashcard ko‘rish'),
                style: OutlinedButton.styleFrom(minimumSize: Size(double.infinity, 52)),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossCount = width < 360 ? 2 : (width < 600 ? 2 : (width < 900 ? 3 : 4));
    final aspect = width < 360 ? 0.85 : 1.05;
    final titleSize = width < 360 ? 14.0 : 15.0;
    final emojiSize = width < 360 ? 30.0 : 34.0;
    return Scaffold(
      appBar: AppBar(
        title: Text(_modeLabel),
        actions: [
          Center(
            child: Padding(
              padding: EdgeInsets.only(right: 16),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber.shade700),
                ),
                child: Text('⭐ $_stars',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 800),
            child: _loading
                ? Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      if (widget.fixedMode != null)
                        Padding(
                          padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: Text(
                              'Bo‘limlar osondan qiyinga tartiblangan (1→15). Har to‘g‘ri javob +1 ⭐. Keyingi bo‘lim avvalgisidan +10 ⭐ qimmat! 🔓',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: Colors.brown[700]),
                            ),
                          ),
                        ),
                      Expanded(
                        child: GridView.builder(
                          padding: EdgeInsets.all(12),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossCount,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: aspect,
                          ),
                          // Osondan qiyinga tartibda (narx bo'yicha o'sib boradi)
                          itemCount: categoriesByDifficulty.length,
                          itemBuilder: (_, i) {
                            final c = categoriesByDifficulty[i];
                            final count = wordCountByCategory(c);
                            final open = _isOpen(c);
                            final cost = categoryUnlockCost(c);
                            final order = i + 1;
                            return Card(
                              color: open ? null : Colors.grey.shade100,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => _onCategoryTap(c),
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Tartib raqami + narx (osondan qiyinga)
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: open
                                              ? Color(0xFF6C5CE7).withValues(alpha: 0.12)
                                              : Colors.grey[700],
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          cost == 0
                                              ? '$order • Bepul 🎉'
                                              : '$order • $cost ⭐',
                                          style: TextStyle(
                                            color: open
                                                ? Color(0xFF6C5CE7)
                                                : Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // Bo'lim nomiga mos rasm (topilmasa emoji)
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            child: Image.asset(
                                              categoryImage(c),
                                              width: emojiSize + 14,
                                              height: emojiSize + 14,
                                              fit: BoxFit.contain,
                                              color: open
                                                  ? null
                                                  : Colors.grey.withValues(
                                                      alpha: 0.7),
                                              colorBlendMode: open
                                                  ? null
                                                  : BlendMode.saturation,
                                              errorBuilder: (_, __, ___) =>
                                                  Text(categoryEmoji(c),
                                                      style: TextStyle(
                                                          fontSize: emojiSize,
                                                          color: open
                                                              ? null
                                                              : Colors.grey)),
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
                                                    size: 18,
                                                    color: Colors.grey[700]),
                                              ),
                                            ),
                                        ],
                                      ),
                                      SizedBox(height: 6),
                                      Text(c,
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: titleSize,
                                              color: open ? null : Colors.grey[600])),
                                      SizedBox(height: 2),
                                      Text('$count ta so‘z',
                                          style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                      if (!open)
                                        Padding(
                                          padding: EdgeInsets.only(top: 4),
                                          child: Text('Ochish uchun bosing',
                                              style: TextStyle(
                                                  color: Color(0xFF6C5CE7),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600)),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
