// RASM TIZIMI (429 ta rasmning barchasi joyida: 331 foto + 98 kartochka-rasm)
// Test tuzilishi: RASM -> inglizcha savol "What is this?" -> 4 ta javob -> avtomatik keyingi -> natija 8/10.
//
// MUHIM QOIDA (19.09.2026 tuzatish, 2-bosqich audit):
// - Rasmli testda faqat ANIQ otlar: Oila, Ovqat, Maktab, Tana, Tabiat, Meva,
//   Sabzavot, Uy, Texnika, Sayohat, Kiyim, Hayvon (378 ta so'z).
// - Mavhumlar (Kundalik, Fe'l, Sifat: hello, good, run...) testga KIRMAYDI,
//   chunki ularning Wikimedia fotolari noto'g'ri edi.
// - 1-bosqich: 61 ta mavhum foto o'chirildi.
// - 2-bosqich (to'liq audit 368 ta): yana 96 ta butunlay noto'g'ri foto o'chirildi:
//   man=haykal, milk=mikroskop, head=burgut, hand=sigaret, sun=barg,
//   plane=cherkov, computer=sichqoncha, robot=3D-printer, bed=mehmonxona,
//   fridge=kulba, sheep=skelet, whale=skelet, eagle=nebula, hen=tuxum...
//   Jami 157 ta so'zda endi katta emoji chiqadi (har doim to'g'ri).
// - 3-bosqich: yana 54 ta shubhali/noaniq foto o'chirildi.
// - 4-bosqich (emoji o'rniga rasmlar): Wikimedia dan ~190 ta to'g'ri foto
//   yuklandi, xavfli/noto'g'ri chiqqanlari o'chirildi, qolgan 98 ta so'zga
//   lokal kartochka-PNG yaratildi (gradient fon + rangli Twemoji + kategoriya).
//   Endi 429/429 rasm joyida: MISSING=0, emoji-vidjet umuman ishlatilmaydi.
//   lib/data/picture_words.dart -> pictureCategories ga qarang.
//
// YANGI RASM + SAVOL QO'SHISH (2 qadam, dastur logikasi o'zgarmaydi):
// 1) Shu papkaga .png tashlang. Nom qoidasi: inglizcha so'z kichik harfda, bo'shliq o'rniga '-'.
//    Masalan: green-apple.png, computer-mouse.png, older-brother.png
//    Tavsiya: 800x600 px (4:3), 100-300 KB, .png (800x800 ham bo'ladi).
//    Manba tavsiyasi: Wikimedia Commons (erkin litsenziyali fotosuratlar).
//    Faqat ANIQ otlarga rasm qo'shing! Mavhum so'zga rasm qo'shmang — emoji yetadi.
// 2) lib/data/picture_words.dart ro'yxatiga 1 qator qo'shing:
//    PictureWord(english: 'green apple', uzbek: 'yashil olma',
//      imagePath: 'assets/picture_quiz/green-apple.png', emoji: '🍏', category: 'Meva'),
//
// Eslatma:
// - pubspec.yaml da `assets/picture_quiz/` papkasi ro'yxatda, har bir faylni alohida yozish shart emas.
// - Rasm topilmasa ilova avtomatik katta emoji ko'rsatadi, xatolik chiqmaydi.
// - Test internet va faylsiz ham ishlaydi (emoji zaxira sifatida).
