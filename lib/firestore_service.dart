import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Check if email is registered in Firebase Auth
  Future<bool> isEmailRegistered(String email) async {
    try {
      List<String> methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      print("Error checking email in Firebase Auth: $e");
      return false;
    }
  }

  // Email & Password Sign-Up / Login
  Future<UserCredential?> authenticateWithEmail({
    required String email,
    required String password,
    String? name,
    required bool isSignUp,
  }) async {
    try {
      if (isSignUp) {
        bool emailExists = await isEmailRegistered(email);
        if (emailExists) {
          throw Exception("Email already registered. Please log in.");
        }

        UserCredential credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        User? user = credential.user;

        if (user != null) {
          await _firestore.collection("users").doc(user.uid).set({
            'uid': user.uid,
            'name': name ?? "User",
            'email': email,
            'image': "",
          });
        }

        return credential;
      } else {
        return await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } catch (e) {
      print("Auth Error: $e");
      throw Exception("Authentication failed: ${e.toString()}");
    }
  }

  // Google Sign-In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User canceled login

      final GoogleSignInAuthentication googleAuth = await googleUser
          .authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
          credential);
      final User? user = userCredential.user;

      if (user == null) return null;

      bool emailExists = await isEmailRegistered(user.email!);
      if (emailExists) {
        throw Exception("Email already registered. Please log in.");
      }

      // Store user details in Firestore
      await _firestore.collection("users").doc(user.uid).set({
        'uid': user.uid,
        'name': user.displayName ?? "No Name",
        'email': user.email,
        'image': user.photoURL ?? "",
        'password': "", // Google users don't have a password
      });

      return userCredential;
    } catch (e) {
      print("Google Sign-In Error: $e");
      throw Exception("Google Sign-In failed: ${e.toString()}");
    }
  }


  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      print("Sign out error: $e");
      throw Exception("Sign out failed: ${e.toString()}");
    }
  }
}
