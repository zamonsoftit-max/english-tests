# English Test — So'z yodlash ilovasi

Flutter'da yozilgan: EN→UZ / UZ→EN test, Flashcard, Xatolar ustida ishlash, Statistika.
120 ta tayyor so'z bor. Har bir testda 10 ta savol, 4 variantli.

## 1. Flutter o'rnatish (Windows)

1. https://docs.flutter.dev/get-started/install/windows dan Flutter SDK ni yuklab oling
2. `C:\flutter` ga oching, so'ng PATH ga `C:\flutter\bin` ni qo'shing
3. Tekshirish:
```powershell
flutter doctor
```

## 2. Loyihani ishga tushirish

Bu papka (`English test`) allaqachon Flutter loyiha asosi (lib/ + pubspec.yaml).

Lekin `android/`, `ios/`, `web/` papkalari yo'q bo'lsa — ularni generatsiya qiling:

```powershell
cd "C:\Users\user\Desktop\English test"
flutter create --project-name english_vocab_test .
flutter pub get
flutter run
```

Chrome'da ishga tushirish uchun:
```powershell
flutter run -d chrome
```

Telefonda ishga tushirish uchun: telefonni USB orqali ulang, Developer mode yoqing, so'ng `flutter run` qiling.

## 3. Fayl tuzilmasi

```
lib/
  main.dart                — ilova kirish nuqtasi
  models/word.dart         — Word, QuizMode, QuestionResult
  data/words.dart          — 120 ta tayyor lug'at
  services/progress_service.dart — statistika + xatolar (SharedPreferences)
  screens/
    home_screen.dart       — bosh sahifa
    quiz_screen.dart       — 10 savollik test
    result_screen.dart     — natija + batafsil tahlil
    flashcards_screen.dart — kartochkalar
    mistakes_screen.dart   — xatolar ro'yxati
```

## 4. So'z qo'shish

`lib/data/words.dart` ni oching va ro'yxatga qo'shing:

```dart
Word(english: 'example', uzbek: 'misol', category: 'Maktab'),
```

## 5. APK olish (telefonga o'rnatish uchun)

```powershell
flutter build apk --release
```

Fayl shu yerda bo'ladi: `build\app\outputs\flutter-apk\app-release.apk`
