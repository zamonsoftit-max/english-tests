// ignore_for_file: prefer_const_constructors

class Word {
  final String english;
  final String uzbek;
  final String category;

  const Word({
    required this.english,
    required this.uzbek,
    required this.category,
  });

  factory Word.fromJson(Map<String, dynamic> j) => Word(
        english: (j['english'] ?? '').toString(),
        uzbek: (j['uzbek'] ?? '').toString(),
        category: (j['category'] ?? 'Umumiy').toString(),
      );

  Map<String, dynamic> toJson() =>
      {'english': english, 'uzbek': uzbek, 'category': category};
}

enum QuizMode { enToUz, uzToEn }

class QuestionResult {
  final Word word;
  final String userAnswer;
  final String correctAnswer;
  final bool isCorrect;

  const QuestionResult({
    required this.word,
    required this.userAnswer,
    required this.correctAnswer,
    required this.isCorrect,
  });
}
