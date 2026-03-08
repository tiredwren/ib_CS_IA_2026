// helper for signin/signup/user doc creation

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // secret code required to register an admin account
  static const String _adminCode = "424321438";

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  UserModel? _userModel;
  UserModel? get currentUserModel => _userModel;

  // listen to auth state on init, load user data when signed in
  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _loadUser(user.uid);
      } else {
        _userModel = null;
        notifyListeners();
      }
    });
  }

  // sign in with email + password
  Future<String?> signIn(String email, String password) async {
    try {
      final res = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _loadUser(res.user!.uid);
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return 'No user found with this email.';
      if (e.code == 'wrong-password') return 'Incorrect password.';
      if (e.code == 'invalid-email') return 'Invalid email address.';
      if (e.code == 'user-disabled') return 'This account has been disabled.';
      return 'An error occurred. Please try again.';
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  // sign up -- admin path requires valid admin code
  Future<String?> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? program,   // students only
    String? position,  // admins only
    String? adminCode,
  }) async {
    try {
      final isAdmin = adminCode != null && adminCode.isNotEmpty;

      if (isAdmin && adminCode != _adminCode) {
        return "invalid admin code; please contact an administrator if there has been an issue.";
      }

      final res = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      UserModel newUser;

      if (isAdmin) {
        // admin account -- store position in program field
        newUser = UserModel(
          uid: res.user!.uid,
          email: email,
          firstN: firstName,
          lastN: lastName,
          program: position ?? '',
          rank: "n/a",
          role: "admin",
          created: DateTime.now(),
        );
      } else {
        if (program == null) return "program selection is required for students.";
        // student account -- starts at white belt
        newUser = UserModel(
          uid: res.user!.uid,
          email: email,
          firstN: firstName,
          lastN: lastName,
          program: program,
          rank: 'White Belt',
          role: 'student',
          created: DateTime.now(),
        );
      }

      await _db.collection('users').doc(res.user!.uid).set(newUser.toMap());

      _userModel = newUser;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') return 'Password is too weak. Please use a stronger password.';
      if (e.code == 'email-already-in-use') return 'An account already exists with this email.';
      if (e.code == 'invalid-email') return 'Invalid email address.';
      return 'An error occurred during sign up.';
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  // fetch user doc from firestore and cache locally
  Future<void> _loadUser(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        _userModel = UserModel.fromFirestore(doc);
        notifyListeners();
      }
    } catch (e) {
      print('error loading user: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _userModel = null;
    notifyListeners();
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return 'No user found with this email.';
      if (e.code == 'invalid-email') return 'Invalid email address.';
      return 'An error occurred. Please try again.';
    }
  }

  bool get isAdmin => _userModel?.role == 'admin';

  // force re-fetch of user doc, e.g. after rank update
  Future<void> refreshUserData() async {
    if (currentUser != null) {
      await _loadUser(currentUser!.uid);
      notifyListeners();
    }
  }
}