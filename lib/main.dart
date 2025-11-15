import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/firebase_options.dart';
import 'screens/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(StudentHubApp());
}

class StudentHubApp extends StatelessWidget {
  const StudentHubApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniMate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF5F7F5),
        primaryColor: const Color(0xFF8BA888),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8BA888),
          primary: const Color(0xFF8BA888),
          secondary: const Color(0xFF6B8E68),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF8BA888),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF6B8E68),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
  ),
),
      ),
    );
  }
}