import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_option.dart'; // Move Firebase config here
import 'SplashScreen.dart';
import 'LoginScreen.dart'; // Import the Login screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Use this instead of hardcoding
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: SplashScreen(),
      routes: {
        '/login': (context) => LoginScreen(), // 🔥 Add missing route
      },
    );
  }
}
