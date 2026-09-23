// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'dart:math';
import 'package:flutter/material.dart';
import '../data/words.dart';
import '../models/word.dart';
import 'result_screen.dart';

class _QuizQuestion {
  final Word word;
  final List<String> options;
  final String correct;
  _QuizQuestion({required this.word, required this.options, required this.correct});
}

class QuizScreen extends StatefulWidget {
  final QuizMode mode;
  final List<Word>? customWords; // xatolarni takrorlash uchun
  final String? category; // kategoriya bo'yicha test, null = barchasi
  const QuizScreen({super.key, required this.mode, this.customWords, this.category});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<_QuizQuestion> _questions;
  int _index = 0;
  String? _selected;
  bool _answered = false;
  final List<QuestionResult> _results = [];

  @override
  void initState() {
    super.initState();
    _questions = _buildQuestions();
  }

  List<_QuizQuestion> _buildQuestions() {
    final rnd = Random();
    List<Word> base;
    if (widget.customWords != null) {
      base = List<Word>.from(widget.customWords!);
    } else if (widget.category != null) {
      base = allWords.where((w) => w.category == widget.category).toList();
    } else {
      base = List<Word>.from(allWords);
    }
    base.shuffle(rnd);
    final picked = base.take(10).toList();
    // Variantlar — imkoni boricha shu kategoriyadan, yetmasa umumiy bazadan
    return picked.map((w) {
      final correct = widget.mode == QuizMode.enToUz ? w.uzbek : w.english;
      final sameCat = List<Word>.from(
        widget.category != null
            ? allWords.where((e) => e.category == widget.category)
            : base,
      )..shuffle(rnd);
      final all = List<Word>.from(allWords)..shuffle(rnd);
      final opts = <String>{correct};
      for (final o in [...sameCat, ...all]) {
        if (opts.length >= 4) break;
        opts.add(widget.mode == QuizMode.enToUz ? o.uzbek : o.english);
      }
      final list = opts.toList()..shuffle(rnd);
      return _QuizQuestion(word: w, options: list, correct: correct);
    }).toList();
  }

  String get _questionText {
    final w = _questions[_index].word;
    return widget.mode == QuizMode.enToUz ? w.english : w.uzbek;
  }

  String get _questionHint =>
      widget.mode == QuizMode.enToUz ? 'Bu so\'zning o\'zbekchasini toping' : 'Bu so\'zning inglizchasini topish';

  String get _title {
    final dir = widget.mode == QuizMode.enToUz ? 'EN → UZ' : 'UZ → EN';
    if (widget.customWords != null) return '$dir • Xatolar';
    if (widget.category != null) return '$dir • ${widget.category}';
    return '$dir test';
  }

  void _select(String opt) {
    if (_answered) return;
    final q = _questions[_index];
    final ok = opt == q.correct;
    setState(() {
      _selected = opt;
      _answered = true;
      _results.add(QuestionResult(
        word: q.word,
        userAnswer: opt,
        correctAnswer: q.correct,
        isCorrect: ok,
      ));
    });
    // To'g'ri javobda hech qanday yozuv chiqmaydi (foydalanuvchi so'rovi)
  }

  void _next() {
    if (_index + 1 >= _questions.length) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            results: _results,
            mode: widget.mode,
            category: widget.category,
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

  Widget _optionTile(String opt, _QuizQuestion q) {
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
    } else if (isSel) {
      border = Color(0xFF6C5CE7);
    }
    final width = MediaQuery.of(context).size.width;
    final optionFont = width < 360 ? 15.0 : 16.0;
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
              Expanded(child: Text(opt, style: TextStyle(fontSize: optionFont, fontWeight: FontWeight.w500))),
              if (icon != null) Icon(icon, color: border),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(_title)),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Bu kategoriyada so‘z topilmadi', textAlign: TextAlign.center),
          ),
        ),
      );
    }
    final q = _questions[_index];
    final progress = (_index + 1) / _questions.length;
    final correctCount = _results.where((e) => e.isCorrect).length;
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final isSmall = width < 360;
    final isShort = height < 640;
    final questionFont = isSmall ? 26.0 : 32.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_title, style: TextStyle(fontSize: isSmall ? 16 : 18)),
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
                child: Text('⭐ $correctCount',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[800])),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 600),
            child: isShort
                ? SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _headerRow(),
                        SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(value: progress, minHeight: 8),
                        ),
                        SizedBox(height: 16),
                        _questionCard(isSmall, questionFont),
                        SizedBox(height: 16),
                        ...q.options.map((opt) => _optionTile(opt, q)),
                        SizedBox(height: 16),
                        _nextButton(),
                      ],
                    ),
                  )
                : Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _headerRow(),
                  SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(value: progress, minHeight: 8),
                  ),
                  SizedBox(height: 16),
                  _questionCard(isSmall, questionFont),
                  SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ...q.options.map((opt) {
                            return _optionTile(opt, q);
                          }),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  _nextButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerRow() {
    final q = _questions[_index];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Savol ${_index + 1}/${_questions.length}',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
        Flexible(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Color(0xFF6C5CE7).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(q.word.category,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Color(0xFF6C5CE7), fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ),
      ],
    );
  }

  Widget _questionCard(bool isSmall, double questionFont) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: isSmall ? 20 : 28, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C5CE7), Color(0xFF00CEC9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Color(0xFF6C5CE7).withValues(alpha: 0.3), blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Text(_questionHint, style: TextStyle(color: Colors.white70, fontSize: 14)),
          SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _questionText,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(color: Colors.white, fontSize: questionFont, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nextButton() {
    return FilledButton(
      onPressed: _answered ? _next : null,
      style: FilledButton.styleFrom(
        minimumSize: Size(double.infinity, 52),
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(
        _index + 1 >= _questions.length ? 'Natijani ko\'rish' : 'Keyingi ➜',
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}
