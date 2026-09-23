// ignore_for_file: avoid_print
import 'dart:io';
void main() {
  final lines = File('lib/data/picture_words.dart').readAsLinesSync();
  // Faqat real qatorlar (// izohlarni tashlab) — aks holda green-apple.png
  // misoli ham MISSING bo'lib chiqadi.
  final real = lines.where((l) => !l.trimLeft().startsWith('//')).join('\n');
  final re = RegExp(r"imagePath:\s*'([^']+)'");
  final paths = re.allMatches(real).map((m) => m.group(1)!).toList();
  print('TOTAL pictureWords: ${paths.length}');
  final existing = Directory('assets/picture_quiz').listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toSet();
  final missing = <String>[];
  for (final p in paths) {
    final fname = p.split('/').last;
    if (!existing.contains(fname)) missing.add(fname);
  }
  print('MISSING count: ${missing.length}');
  for (final m in missing) print('MISSING: $m');
  final referenced = paths.map((p) => p.split('/').last).toSet();
  final extra = existing.where((f) => f.endsWith('.png') && !referenced.contains(f)).toList();
  print('EXTRA count: ${extra.length}: $extra');
  // sizes
  final files = Directory('assets/picture_quiz').listSync().whereType<File>().where((f) => f.path.endsWith('.png')).toList();
  files.sort((a,b) => a.lengthSync().compareTo(b.lengthSync()));
  print('SMALLEST 5:');
  for (var i=0;i<5 && i<files.length;i++) print('${files[i].uri.pathSegments.last} ${files[i].lengthSync()}');
  print('LARGEST 5:');
  for (var i=files.length-5;i<files.length;i++) if(i>=0) print('${files[i].uri.pathSegments.last} ${files[i].lengthSync()}');
  // header check
  for (var i=0;i<5 && i<files.length;i++) {
    final bytes = files[i].readAsBytesSync().take(12).toList();
    print('${files[i].uri.pathSegments.last} header: $bytes');
  }
}
