import 'package:furnix/LoginScreen.dart';
import 'package:flutter/material.dart';
import 'package:furnix/MyHomePage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 2), () {
      checkUserLogin();
    });
  }

  Future<void> checkUserLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('userEmail');
    String? uid = prefs.getString('userUID');
    // Retrieve UID

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => (email != null && uid != null)
            ? MyHomePage(uid: uid) // Pass the retrieved UID
            : LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/logo.png", // Ensure the logo is in assets
              height: 150,
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50.0),
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey[300],
                color: Colors.deepPurple,
                minHeight: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
