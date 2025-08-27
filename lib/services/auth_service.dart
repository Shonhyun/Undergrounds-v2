import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:learningexamapp/screens/auth_pages/login_screen.dart';
import 'package:learningexamapp/screens/main_screen.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> signup({
    required String email,
    required String password,
    required String fullName,
    required BuildContext context,
    required String schoolName,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      String uid = userCredential.user!.uid;

      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'fullName': fullName,
        'role': 'student',
        'isBanned': false,
        'dateJoined': FieldValue.serverTimestamp(),
        'schoolName': schoolName,
      });

      final subjects = ['ee', 'esas', 'math', 'refresher'];
      for (final subject in subjects) {
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('enrollments')
            .doc(subject)
            .set({'enrolled': false});
      }

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }

      return null; // Successful signup
    } on FirebaseAuthException catch (e) {
      return e.code; // Return the error code
    } catch (e) {
      return 'unknown-error'; // Return generic error
    }
  }

  Future<String?> signin({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        String uid = userCredential.user!.uid;

        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(uid).get();

        if (userDoc.exists && userDoc['isBanned'] == true) {
          await _auth.signOut();
          if (!context.mounted) return null;
          return 'banned'; // Special code for banned user
        }
      }

      if (!context.mounted) return null;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
      return null; // Successful sign-in
    } on FirebaseAuthException catch (e) {
      return e.code; // Return the error code
    } catch (e) {
      return 'unknown-error'; // Return generic error
    }
  }

  Future<void> signout({required BuildContext context}) async {
    await _auth.signOut();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  Future<String?> deleteAccount({required BuildContext context}) async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        String uid = user.uid;

        // Delete user data from Firestore
        await _firestore.collection('users').doc(uid).delete();

        // Delete the user from Firebase Authentication
        await user.delete();

        // Navigate to the login screen
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }

        return null; // Successful deletion
      } else {
        return 'no-user'; // No user is currently signed in
      }
    } on FirebaseAuthException catch (e) {
      return e.code; // Return the error code
    } catch (e) {
      return 'unknown-error'; // Return generic error
    }
  }
}
