// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/progress_service.dart';
import 'services/remote_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Bonusni ilova ochilishidayoq kafolatlash (dialog HomeScreen da chiqadi)
  try {
    await ProgressService.ensureWelcomeBonus();
  } catch (_) {
    // SharedPreferences tayyor bo'lmasa HomeScreen da qayta uriniladi
  }
  // Cloudflare dagi yangiliklarni yuklash (bo'lmasa built-in ro'yxat).
  try {
    await RemoteConfig.syncOnStartup();
  } catch (_) {}
  runApp(const VocabApp());
}

class VocabApp extends StatelessWidget {
  const VocabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'English Test — So\'z yodlash',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF6C5CE7),
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
