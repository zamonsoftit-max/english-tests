// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'dart:math';
import 'package:flutter/material.dart';
import '../data/words.dart';
import '../models/word.dart';
import '../services/progress_service.dart';

class FlashcardsScreen extends StatefulWidget {
  final String? initialCategory;
  const FlashcardsScreen({super.key, this.initialCategory});
  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  late List<Word> _cards = [];
  int _index = 0;
  bool _showUz = false;
  String? _filter;
  Set<String> _unlocked = {'Kundalik'};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialCategory;
    _loadUnlocks();
  }

  Future<void> _loadUnlocks() async {
    final u = await ProgressService.getUnlockedCategories();
    if (!mounted) return;
    setState(() {
      _unlocked = u.toSet();
      _loading = false;
      _cards = _filteredCards()..shuffle(Random());
    });
  }

  bool _isOpen(String c) {
    if (categoryUnlockCost(c) == 0) return true;
    return _unlocked.contains(c);
  }

  List<Word> _filteredCards() {
    if (_filter == null) {
      // Faqat ochiq bo'limlar (qulflanganlar test/yulduz bilan ochiladi)
      return allWords.where((w) => _isOpen(w.category)).toList();
    }
    return allWords.where((w) => w.category == _filter).toList();
  }

  void _shuffle() {
    setState(() {
      var pool = _filteredCards();
      pool.shuffle(Random());
      _cards = pool;
      _index = 0;
      _showUz = false;
    });
  }

  void _next() {
    if (_index + 1 < _cards.length) {
      setState(() { _index++; _showUz = false; });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Oxirgi karta! Aralashtirib qayta boshlang 🔀')),
      );
    }
  }

  void _prev() {
    if (_index > 0) setState(() { _index--; _showUz = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('Flashcard')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Flashcard')),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Bu bo‘limda so‘z yo‘q yoki bo‘lim qulfli 🔒\nTest ishlang va ⭐ yig‘ib oching!',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    final w = _cards[_index];
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final isSmall = width < 360;
    // Past bo'yli ekranda tugmalar ixchamlashadi ("Bottom overflowed" bo'lmasligi uchun).
    final isShort = size.height < 640;
    final btnH = isShort ? 44.0 : 48.0;
    final cardFont = isSmall ? 30.0 : (width < 600 ? 36.0 : 44.0);
    return Scaffold(
      appBar: AppBar(
        title: Text('Flashcard'),
        actions: [
          IconButton(onPressed: _shuffle, icon: Icon(Icons.shuffle), tooltip: 'Aralashtirish'),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _catChip(null, '⭐ Ochiqlari'),
                        ...categoriesByDifficulty.map((c) => _catChip(c, '${categoryEmoji(c)} $c')),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('${_index + 1} / ${_cards.length}',
                      style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600)),
                  SizedBox(height: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showUz = !_showUz),
                      child: AnimatedSwitcher(
                        duration: Duration(milliseconds: 350),
                        child: Container(
                          key: ValueKey('$_index-$_showUz'),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _showUz
                                  ? [Color(0xFF00B894), Color(0xFF00CEC9)]
                                  : [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10)),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_showUz ? 'O‘ZBEKCHA' : 'INGLIZCHA',
                                  style: TextStyle(color: Colors.white70, letterSpacing: 3, fontSize: 12)),
                              SizedBox(height: 12),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24),
                                // Uzun so'zlar (masalan cauliflower, pomegranate)
                                // kichik telefonda sig'may qolmasligi uchun
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _showUz ? w.uzbek : w.english,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    style: TextStyle(color: Colors.white, fontSize: cardFont, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              SizedBox(height: 12),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('${categoryEmoji(w.category)} ${w.category}',
                                    style: TextStyle(color: Colors.white)),
                              ),
                              SizedBox(height: 24),
                              Text('Ko‘rish uchun bosing 👆',
                                  style: TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  // Telefonda tugmalar sig'masa Wrap ishlaydi
                  if (isSmall)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _prev,
                                icon: Icon(Icons.arrow_back, size: 18),
                                label: Text('Oldingi', style: TextStyle(fontSize: 13)),
                                style: OutlinedButton.styleFrom(minimumSize: Size(0, btnH)),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: FilledButton.tonalIcon(
                                onPressed: _next,
                                icon: Icon(Icons.arrow_forward, size: 18),
                                label: Text('Keyingi', style: TextStyle(fontSize: 13)),
                                style: FilledButton.styleFrom(minimumSize: Size(0, btnH)),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await ProgressService.addMistake(w.english);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('“${w.english}” xatolar ro‘yxatiga qo‘shildi')),
                                  );
                                },
                                icon: Icon(Icons.close, color: Colors.red, size: 18),
                                label: Text('Bilmayman', style: TextStyle(fontSize: 13)),
                                style: OutlinedButton.styleFrom(minimumSize: Size(0, btnH)),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () async {
                                  await ProgressService.removeMistake(w.english);
                                  _next();
                                },
                                icon: Icon(Icons.check, size: 18),
                                label: Text('Bilaman', style: TextStyle(fontSize: 13)),
                                style: FilledButton.styleFrom(minimumSize: Size(0, btnH)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _prev,
                                icon: Icon(Icons.arrow_back),
                                label: Text('Oldingi'),
                                style: OutlinedButton.styleFrom(minimumSize: Size(0, btnH)),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await ProgressService.addMistake(w.english);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('“${w.english}” xatolar ro‘yxatiga qo‘shildi')),
                                  );
                                },
                                icon: Icon(Icons.close, color: Colors.red),
                                label: Text('Bilmayman'),
                                style: OutlinedButton.styleFrom(minimumSize: Size(0, btnH)),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () async {
                                  await ProgressService.removeMistake(w.english);
                                  _next();
                                },
                                icon: Icon(Icons.check),
                                label: Text('Bilaman'),
                                style: FilledButton.styleFrom(minimumSize: Size(0, btnH)),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonalIcon(
                            onPressed: _next,
                            icon: Icon(Icons.arrow_forward),
                            label: Text('Keyingi'),
                            style: FilledButton.styleFrom(minimumSize: Size(double.infinity, btnH)),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _catChip(String? value, String label) {
    final sel = _filter == value;
    final locked = value != null && !_isOpen(value);
    final displayLabel = locked ? '🔒 $label' : label;
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(displayLabel,
            style: TextStyle(color: locked ? Colors.grey[600] : null)),
        selected: sel,
        onSelected: (_) {
          if (value != null && !_isOpen(value)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      '🔒 $value yopiq! ${categoryUnlockCost(value)} ⭐ yig‘ib test bo‘limidan oching')),
            );
            return;
          }
          setState(() => _filter = value);
          _shuffle();
        },
      ),
    );
  }
}
