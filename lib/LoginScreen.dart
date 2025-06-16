import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:furnix/RegistrationScreen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'MyHomePage.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isPasswordVisible = false;
  bool isLoading = false;
  bool isGoogleLoading = false;
  String errorMessage = "";

  void _login() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userEmail', emailController.text.trim()); // ✅ Save Email
      await prefs.setString('userUID', uid); // ✅ Save UID

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyHomePage(uid: uid)),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.message ?? "Login failed. Please try again.";
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => isGoogleLoading = true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut(); // Ensures fresh account selection
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => isGoogleLoading = false);
        return; // User canceled sign-in
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        String uid = user.uid;
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userUID', uid); // ✅ Save UID
        await prefs.setString('userEmail', user.email!); // ✅ Save Email

        bool emailExists = await checkEmailExists(user.email!);
        if (emailExists) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MyHomePage(uid: uid)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Email not registered. Please sign up.")),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google Sign-In Failed: ${e.toString()}")),
      );
    } finally {
      setState(() => isGoogleLoading = false);
    }
  }

  Future<bool> checkEmailExists(String email) async {
    QuerySnapshot query = await FirebaseFirestore.instance
        .collection("users")
        .where("email", isEqualTo: email)
        .get();
    return query.docs.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Login",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                ),
                SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(emailController, "Email", Icons.email, isEmail: true),
                      _buildTextField(passwordController, "Password", Icons.lock, isPassword: true),
                      SizedBox(height: 20),
                      isLoading
                          ? CircularProgressIndicator()
                          : _buildButton("Login", _login),
                      SizedBox(height: 10),
                      isGoogleLoading
                          ? CircularProgressIndicator()
                          : _buildButton("Login with Google", _signInWithGoogle, isGoogle: true),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    // Navigate to your registration screen (replace with actual route name)
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => RegistrationScreen()), // Replace RegisterScreen() with your actual register page widget
                    );
                  },
                  child: Text(
                    "Don't have an account? Sign up",
                    style: TextStyle(color: Colors.blue.shade700, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isPassword = false, bool isEmail = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.blue.shade700),
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed, {bool isGoogle = false}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isGoogle ? Colors.white : Colors.blue.shade700,
        foregroundColor: isGoogle ? Colors.black : Colors.white,
        minimumSize: Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: isGoogle ? BorderSide(color: Colors.blue.shade700) : BorderSide.none,
      ),
      child: Text(text, style: TextStyle(fontSize: 16)),
    );
  }
}

