// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import '../models/word.dart';
import '../services/progress_service.dart';
import 'quiz_screen.dart';

class MistakesScreen extends StatefulWidget {
  const MistakesScreen({super.key});
  @override
  State<MistakesScreen> createState() => _MistakesScreenState();
}

class _MistakesScreenState extends State<MistakesScreen> {
  List<Word> _mistakes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final m = await ProgressService.getMistakes();
    if (!mounted) return;
    setState(() { _mistakes = m; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Xatolar (${_mistakes.length})'),
        actions: [
          if (_mistakes.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep),
              tooltip: 'Barchasini tozalash',
              onPressed: () async {
                await ProgressService.clearMistakes();
                _load();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 600),
            child: _loading
                ? Center(child: CircularProgressIndicator())
                : _mistakes.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('🎉', style: TextStyle(fontSize: 64)),
                        SizedBox(height: 12),
                        Text('Xatolar yo‘q!',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text(
                          'Test ishlang — xato qilsangiz so‘zlar shu yerda saqlanadi va qayta mashq qilasiz.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QuizScreen(
                                  mode: QuizMode.enToUz,
                                  customWords: _mistakes,
                                ),
                              ),
                            ).then((_) => _load());
                          },
                          icon: Icon(Icons.replay),
                          label: Text('Xatolar bo‘yicha test boshlash'),
                          style: FilledButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _mistakes.length,
                        itemBuilder: (_, i) {
                          final w = _mistakes[i];
                          return Dismissible(
                            key: ValueKey(w.english),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.green,
                              alignment: Alignment.centerRight,
                              padding: EdgeInsets.only(right: 20),
                              child: Icon(Icons.check, color: Colors.white),
                            ),
                            onDismissed: (_) async {
                              await ProgressService.removeMistake(w.english);
                              _load();
                            },
                            child: Card(
                              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: ListTile(
                                title: Text('${w.english} — ${w.uzbek}',
                                    style: TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text(w.category),
                                trailing: IconButton(
                                  icon: Icon(Icons.check_circle_outline, color: Colors.green),
                                  tooltip: 'Yodladim',
                                  onPressed: () async {
                                    await ProgressService.removeMistake(w.english);
                                    _load();
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('O‘ngga sursangiz yoki ✅ bossangiz — yodlangan hisoblanadi',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ),
                  ],
                ),
          ),
        ),
      ),
    );
  }
}
