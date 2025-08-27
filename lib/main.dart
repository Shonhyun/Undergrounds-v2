import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:learningexamapp/firebase_options.dart';
import 'package:learningexamapp/screens/splash_screen.dart';
import 'package:learningexamapp/screens/auth_pages/register_screen.dart';
import 'package:learningexamapp/screens/main_screen.dart';
import 'package:learningexamapp/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    print("Firebase initialization error: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      // themeMode: ThemeMode.system,
      themeMode: ThemeMode.dark,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const MainScreen(),
        '/register': (context) => const RegisterPage(),
      },
    );
  }
}
