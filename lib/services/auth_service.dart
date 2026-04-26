import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
// Note: To use GitHub sign in on web/mobile, you can use flutter_appauth or firebase auth providers directly.

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Stream of auth state changes
  Stream<User?> get userChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with Email/Password
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Email sign in error: \$e');
      rethrow;
    }
  }

  // Sign up with Email/Password
  Future<UserCredential?> signUpWithEmail(String email, String password, String name) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Immediately update the display name so it shows on the dashboard
      await userCredential.user?.updateDisplayName(name);
      return userCredential;
    } catch (e) {
      print('Email sign up error: \$e');
      rethrow;
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      if (kIsWeb) {
        return await _auth.signInWithPopup(googleProvider);
      } else {
        return await _auth.signInWithProvider(googleProvider);
      }
    } catch (e) {
      print('Google sign in error: \$e');
      rethrow;
    }
  }

  // Sign in with GitHub (Using Firebase OAuth Provider)
  Future<UserCredential?> signInWithGitHub() async {
    try {
      GithubAuthProvider githubProvider = GithubAuthProvider();
      if (kIsWeb) {
        return await _auth.signInWithPopup(githubProvider);
      } else {
        return await _auth.signInWithProvider(githubProvider);
      }
    } catch (e) {
      print('GitHub sign in error: \$e');
      rethrow;
    }
  }

  // Update Display Name
  Future<void> updateUserName(String name) async {
    try {
      await currentUser?.updateDisplayName(name);
    } catch (e) {
      print('Update name error: \$e');
      rethrow;
    }
  }

  // Update Password
  Future<void> updatePassword(String newPassword) async {
    try {
      await currentUser?.updatePassword(newPassword);
    } catch (e) {
      print('Update password error: \$e');
      rethrow;
    }
  }

  // Delete Account
  Future<void> deleteAccount() async {
    try {
      await currentUser?.delete();
    } catch (e) {
      print('Delete account error: \$e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
