// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import '../models/word.dart';
import '../services/progress_service.dart';
import 'picture_quiz_screen.dart';
import 'quiz_screen.dart';
import 'mistakes_screen.dart';

class ResultScreen extends StatefulWidget {
  final List<QuestionResult> results;
  final QuizMode mode;
  final String? category;

  /// Rasmli testdan kelgan bo'lsa true — "Qayta" tugmasi
  /// matnli testga emas, yana Rasmli testga qaytadi.
  final bool isPictureQuiz;

  /// Rasmli testning kategoriya filtri (qayta boshlashda saqlanadi).
  final List<String>? pictureCategories;

  const ResultScreen(
      {super.key,
      required this.results,
      required this.mode,
      this.category,
      this.isPictureQuiz = false,
      this.pictureCategories});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _saved = false;
  int _totalStars = 0;

  @override
  void initState() {
    super.initState();
    _save();
  }

  Future<void> _save() async {
    final correct = widget.results.where((e) => e.isCorrect).length;
    final wrong = widget.results.where((e) => !e.isCorrect).map((e) => e.word).toList();
    await ProgressService.saveTestResult(correct: correct, total: widget.results.length, wrongWords: wrong);
    final stars = await ProgressService.getStars();
    if (mounted) {
      setState(() {
        _saved = true;
        _totalStars = stars;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final correct = widget.results.where((e) => e.isCorrect).length;
    final total = widget.results.length;
    final pct = total == 0 ? 0 : (correct / total * 100).round();
    final wrong = widget.results.where((e) => !e.isCorrect).toList();

    String emoji = '🎉';
    String text = 'Ajoyib!';
    if (pct < 40) { emoji = '💪'; text = 'Harakat qiling!'; }
    else if (pct < 70) { emoji = '🙂'; text = 'Yaxshi, davom eting!'; }
    else if (pct < 100) { emoji = '👏'; text = 'Zo\'r natija!'; }

    return Scaffold(
      appBar: AppBar(title: Text('Natija'), automaticallyImplyLeading: false),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: EdgeInsets.all(16),
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFF00CEC9)]),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Text(emoji, style: TextStyle(fontSize: 48)),
                Text(text, style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('$correct / $total  •  $pct%',
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('+$correct ⭐  •  Jami: $_totalStars ⭐',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
                if (!_saved) ...[
                  SizedBox(height: 8),
                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                ],
              ],
            ),
          ),
          SizedBox(height: 16),
          // Kichik telefonda (320px) tugmalar ustma-ust tushadi,
          // kattada yonma-yon
          LayoutBuilder(
            builder: (_, cons) {
              final narrow = cons.maxWidth < 360;
              final retry = FilledButton.icon(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => widget.isPictureQuiz
                        ? PictureQuizScreen(
                            categories: widget.pictureCategories)
                        : QuizScreen(
                            mode: widget.mode, category: widget.category)),
                ),
                icon: Icon(Icons.replay),
                label: Text('Qayta boshlash'),
                style: FilledButton.styleFrom(minimumSize: Size(double.infinity, 50)),
              );
              final home = OutlinedButton.icon(
                onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                icon: Icon(Icons.home),
                label: Text('Bosh sahifa', maxLines: 1, overflow: TextOverflow.ellipsis),
                style: OutlinedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
              );
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [retry, SizedBox(height: 8), home],
                );
              }
              return Row(
                children: [
                  Expanded(child: retry),
                  SizedBox(width: 8),
                  Expanded(child: home),
                ],
              );
            },
          ),
          if (wrong.isNotEmpty) ...[
            SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MistakesScreen()),
              ),
              icon: Icon(Icons.error_outline),
              label: Text('Xatolarni ko\'rish (${wrong.length})'),
            ),
          ],
          SizedBox(height: 16),
          Text('Batafsil:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 8),
          ...widget.results.map((r) => Card(
                color: r.isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                child: ListTile(
                  leading: Icon(r.isCorrect ? Icons.check_circle : Icons.cancel,
                      color: r.isCorrect ? Colors.green : Colors.red),
                  title: Text('${r.word.english} — ${r.word.uzbek}',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: r.isCorrect
                      ? Text('To\'g\'ri ✅')
                      : Text('Siz: ${r.userAnswer} • To\'g\'ri: ${r.correctAnswer}'),
                ),
              )),
          SizedBox(height: 24),
        ],
            ),
          ),
        ),
      ),
    );
  }
}
