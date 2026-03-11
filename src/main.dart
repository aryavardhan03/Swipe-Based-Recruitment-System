import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Swipe Recruitment App',

      theme: ThemeData(
        useMaterial3: false, // 🔥 IMPORTANT

        scaffoldBackgroundColor: Colors.grey[100],

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 2,

          // 🔥 FORCE ICON COLOR
          iconTheme: IconThemeData(
            color: Colors.black,
            size: 26,
          ),

          actionsIconTheme: IconThemeData(
            color: Colors.black,
            size: 26,
          ),

          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      home: const LoginScreen(),
    );
  }
}
