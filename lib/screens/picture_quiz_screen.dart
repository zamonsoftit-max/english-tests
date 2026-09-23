// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../data/picture_words.dart';
import '../models/word.dart';
import 'result_screen.dart';

class _PictureQuestion {
  final PictureWord item;
  final List<String> options;
  final String correct;
  _PictureQuestion({required this.item, required this.options, required this.correct});
}

class PictureQuizScreen extends StatefulWidget {
  /// Qaysi kategoriyalardan savol olinadi.
  /// null yoki bo'sh bo'lsa — barcha rasmlardan aralash (10 ta tasodifiy).
  /// Masalan: ['Meva', 'Sabzavot'] — Meva-Sabzavot testi.
  ///
  /// YANGI SAVOL QO'SHISH uchun bu faylni o'zgartirish SHART EMAS:
  /// 1) rasmni `assets/picture_quiz/` papkasiga tashlang,
  /// 2) `lib/data/picture_words.dart` ro'yxatiga 1 qator qo'shing — kifoya.
  final List<String>? categories;

  const PictureQuizScreen({super.key, this.categories});

  @override
  State<PictureQuizScreen> createState() => _PictureQuizScreenState();
}

class _PictureQuizScreenState extends State<PictureQuizScreen> {
  late List<_PictureQuestion> _questions;
  late List<PictureWord> _pool;
  int _index = 0;
  String? _selected;
  bool _answered = false;
  int _advanceToken = 0;
  final List<QuestionResult> _results = [];

  // Bosh ekran uslubi: gradient ranglar HomeScreen bilan bir xil
  static const _gradStart = Color(0xFF6C5CE7);
  static const _gradEnd = Color(0xFF00CEC9);

  @override
  void initState() {
    super.initState();
    _pool = _resolvePool();
    _questions = _buildQuestions();
  }

  List<PictureWord> _resolvePool() {
    // Faqat aniq rasmlar: Kundalik / Fe'l / Sifat testga kirmaydi
    // (ularning fotolari noto'g'ri edi — o'yin logotipi, diagramma va h.k.)
    final cats = sanitizePictureCategories(widget.categories);
    if (cats == null || cats.isEmpty) {
      return concretePictureWords;
    }
    final filtered = pictureWords
        .where((w) => cats.contains(w.category))
        .toList();
    // Kategoriya bo'sh bo'lib qolsa — aniq rasmlardan olish
    if (filtered.isEmpty) return concretePictureWords;
    return filtered;
  }

  String get _title {
    final c = widget.categories;
    if (c == null || c.isEmpty) return 'Rasmli test 🖼️';
    if (c.length == 1 && c.first == 'Meva') return 'Mevalar 🍎';
    if (c.length == 1 && c.first == 'Sabzavot') return 'Sabzavotlar 🥕';
    if (c.length == 2 && c.contains('Meva') && c.contains('Sabzavot')) {
      return 'Meva-Sabzavot 🍎🥕';
    }
    return 'Rasmli test 🖼️ (${c.join(', ')})';
  }

  List<_PictureQuestion> _buildQuestions() {
    final rnd = Random();
    final base = List<PictureWord>.from(_pool)..shuffle(rnd);
    // Kichik bo'limlarda ham to'liq 10 savol bo'lishi uchun takrorlab to'ldiramiz.
    final picked = <PictureWord>[];
    while (picked.length < 10 && base.isNotEmpty) {
      for (final p in base) {
        if (picked.length >= 10) break;
        picked.add(p);
      }
    }
    return picked.map((p) {
      final opts = <String>{p.uzbek};
      // Chalg'ituvchi javoblar ham shu mavzudan bo'ladi (o'rganish osonroq)
      final pool = List<PictureWord>.from(_pool)..shuffle(rnd);
      for (final o in pool) {
        if (opts.length >= 4) break;
        opts.add(o.uzbek);
      }
      // Bo'limda 4 tadan kam so'z bo'lsa — aniq rasmlar bazasidan to'ldiramiz.
      if (opts.length < 4) {
        final fallback = List<PictureWord>.from(concretePictureWords)..shuffle(rnd);
        for (final o in fallback) {
          if (opts.length >= 4) break;
          opts.add(o.uzbek);
        }
      }
      final list = opts.toList()..shuffle(rnd);
      return _PictureQuestion(item: p, options: list, correct: p.uzbek);
    }).toList();
  }

  void _select(String opt) {
    if (_answered) return;
    final q = _questions[_index];
    final ok = opt == q.correct;
    final token = ++_advanceToken;
    setState(() {
      _selected = opt;
      _answered = true;
      _results.add(QuestionResult(
        // Rasmli so'zni oddiy Word ga o'girib natijaga yozamiz (⭐ saqlanishi uchun)
        word: Word(english: q.item.english, uzbek: q.item.uzbek, category: 'Rasmli'),
        userAnswer: opt,
        correctAnswer: q.correct,
        isCorrect: ok,
      ));
    });
    // Har bir savoldan keyin avtomatik keyingi savolga o'tish (800 ms pauza:
    // foydalanuvchi yashil/qizil javobni ko'rib ulguradi).
    Future.delayed(Duration(milliseconds: 800), () {
      if (!mounted || token != _advanceToken) return;
      _next();
    });
  }

  void _next() {
    if (_index + 1 >= _questions.length) {
      _advanceToken++;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            results: _results,
            mode: QuizMode.enToUz,
            category: 'Rasmli',
            // Rasmli testdan qayta boshlash shu ekranga qaytishi uchun:
            isPictureQuiz: true,
            pictureCategories: widget.categories,
          ),
        ),
      );
    } else {
      setState(() {
        _index++;
        _selected = null;
        _answered = false;
      });
    }
  }

  void _restart() {
    _advanceToken++; // kutilayotgan avtomatik o'tishni bekor qilish
    setState(() {
      _pool = _resolvePool();
      _questions = _buildQuestions();
      _index = 0;
      _selected = null;
      _answered = false;
      _results.clear();
    });
  }

  Future<void> _confirmRestart() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Qayta boshlash?'),
        content: Text('Joriy natija o‘chadi va test boshidan boshlanadi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Ha, qayta'),
          ),
        ],
      ),
    );
    if (ok == true) _restart();
  }

  @override
  Widget build(BuildContext context) {
    if (concretePictureWords.isEmpty || _questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Rasmli test 🖼️')),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🖼️', style: TextStyle(fontSize: 64)),
                SizedBox(height: 12),
                Text('Tez kunda rasmlar qo‘shiladi!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                SizedBox(height: 8),
                Text(
                  'assets/picture_quiz/ papkasiga rasmlarni tashlang va lib/data/picture_words.dart ro‘yxatiga qo‘shing.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final q = _questions[_index];
    final progress = (_index + 1) / _questions.length;
    final correctCount = _results.where((e) => e.isCorrect).length;
    final height = MediaQuery.of(context).size.height;
    // Past bo'yli telefonda (landshaft / kichik ekran) ustun sig'may
    // "Bottom overflowed" xatosi chiqmasligi uchun butunlay skrollanuvchi rejim.
    final isShort = height < 640;
    // Rasm balandligi ekranga moslashadi (katta ekranda 260, kichikda 180).
    final imgH = (height * 0.30).clamp(180.0, 260.0);

    return Scaffold(
      appBar: AppBar(
        title: Text('$_title (${_index + 1}/${_questions.length})'),
        actions: [
          // ⭐ Yig'ilgan to'g'ri javoblar — jonli hisoblagich (saqlash Natija ekranida)
          Center(
            child: Padding(
              padding: EdgeInsets.only(right: 8),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber.shade700),
                ),
                child: Text('⭐ $correctCount',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[800])),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Qayta boshlash',
            icon: Icon(Icons.replay),
            onPressed: _confirmRestart,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 600),
            child: isShort
                // Past ekran: hamma narsa skrollanadi (Expanded yo'q —
                // "Bottom overflowed" xatosi chiqmaydi).
                ? SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _headerRow(q),
                        SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                              value: progress, minHeight: 8),
                        ),
                        SizedBox(height: 12),
                        _imageCard(q, imgH),
                        SizedBox(height: 12),
                        _englishQuestionCard(),
                        SizedBox(height: 12),
                        ...q.options.map((opt) => _optionTile(opt, q)),
                        if (_answered) _answerHint(q),
                        SizedBox(height: 8),
                        _statusText(),
                        SizedBox(height: 8),
                        _restartButton(),
                      ],
                    ),
                  )
                : Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _headerRow(q),
                        SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                              value: progress, minHeight: 8),
                        ),
                        SizedBox(height: 12),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // 1) Har bir savolda RASM (alohida papkada saqlanadi)
                                _imageCard(q, imgH),
                                SizedBox(height: 12),
                                // 2) Rasm ostida INGLIZ TILIDAGI SAVOL (bosh ekran uslubida)
                                _englishQuestionCard(),
                                SizedBox(height: 12),
                                // 3) Savol ostida 4 ta JAVOB VARIANTI
                                ...q.options.map((opt) => _optionTile(opt, q)),
                                // Javobdan keyin inglizcha so'zni ko'rsatish (o'rganish uchun)
                                if (_answered) _answerHint(q),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        // 4) Avtomatik o'tish bo'lgani uchun "Keyingi" tugmasi yo'q.
                        // Pastda faqat holat + qayta boshlash.
                        _statusText(),
                        SizedBox(height: 8),
                        _restartButton(),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _statusText() {
    return Row(
      children: [
        Expanded(
          child: Text(
            _answered
                ? 'Keyingi savol ochilmoqda… ⏭️'
                : 'Javobni tanlang — keyingi savol avtomatik ochiladi 👆',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _restartButton() {
    return OutlinedButton.icon(
      onPressed: _confirmRestart,
      icon: Icon(Icons.replay),
      label: Text('Qayta boshlash'),
      style: OutlinedButton.styleFrom(
        minimumSize: Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _headerRow(_PictureQuestion q) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Savol ${_index + 1}/${_questions.length}',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
        Flexible(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _gradStart.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(q.item.category,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: _gradStart, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ),
      ],
    );
  }

  Widget _imageCard(_PictureQuestion q, [double imgH = 260]) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: imgH,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
          gradient: LinearGradient(
            colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        // 1) Cloudflare R2 (imageUrl) 2) lokal asset 3) emoji
        // BoxFit.contain — rasm kesilmasdan to'liq ko'rinadi
        // (cover bo'lsa portret/landshaft fotolar kesilib noto'g'ri chiqadi).
        child: q.item.imageUrl.isNotEmpty
            ? Image.network(
                q.item.imageUrl,
                // imageUrl ga ?v=updatedAt qo'shiladi — key ham shunga bog'langan
                // bo'lishi shart, aks holda Flutter eski keshni ko'rsataveradi.
                key: ValueKey(q.item.imageUrl),
                fit: BoxFit.contain,
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Image.asset(
                  q.item.imagePath,
                  key: ValueKey(q.item.imagePath),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => _emojiFallback(q),
                ),
              )
            : Image.asset(
          q.item.imagePath,
          key: ValueKey(q.item.imagePath),
          fit: BoxFit.contain,
          // Real foto bo'lsa — foto chiqadi.
          // Bo'lmasa — katta emoji-rasm chiqadi (barcha so'zlarda bor).
          errorBuilder: (_, __, ___) => _emojiFallback(q),
        ),
      ),
    );
  }

  Widget _emojiFallback(_PictureQuestion q) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(q.item.emoji, style: TextStyle(fontSize: 110)),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(q.item.category,
                style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  /// Bosh ekrandagi gradient (6C5CE7 → 00CEC9) uslubidagi inglizcha savol kartasi.
  Widget _englishQuestionCard() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_gradStart, _gradEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: _gradStart.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Text('Look at the picture 👆',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          SizedBox(height: 4),
          Text(
            'What is this?',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text('Choose the correct answer',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _answerHint(_PictureQuestion q) {
    final wasCorrect = _selected == q.correct;
    return Container(
      margin: EdgeInsets.only(top: 2, bottom: 10),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: wasCorrect ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: wasCorrect ? Colors.green : Colors.red, width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(wasCorrect ? Icons.check_circle : Icons.info_outline,
              size: 18, color: wasCorrect ? Colors.green : Colors.red),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              // Inglizcha so'zni shu yerda ko'rsatamiz (savolda ko'rsatmaymiz —
              // aks holda javob oldindan bilinib qoladi).
              '"${_capitalize(q.item.english)}" — ${q.correct}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  Widget _optionTile(String opt, _PictureQuestion q) {
    final isSel = _selected == opt;
    final isCorrectOpt = opt == q.correct;
    Color? bg;
    Color? border;
    IconData? icon;
    if (_answered) {
      if (isCorrectOpt) {
        bg = Colors.green.shade50;
        border = Colors.green;
        icon = Icons.check_circle;
      } else if (isSel) {
        bg = Colors.red.shade50;
        border = Colors.red;
        icon = Icons.cancel;
      }
    }
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _select(opt),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          constraints: BoxConstraints(minHeight: 56),
          decoration: BoxDecoration(
            color: bg ?? Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border ?? Colors.grey.shade300, width: 1.5),
          ),
          child: Row(
            children: [
              Expanded(
                  child: Text(opt,
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500))),
              if (icon != null) Icon(icon, color: border),
            ],
          ),
        ),
      ),
    );
  }
}
