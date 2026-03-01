// helper for signin/signup/create new user docs

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String ADMIN_CODE = "424321438"; // secret code to create admin account

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  UserModel? _currentUserModel;
  UserModel? get currentUserModel => _currentUserModel;

  // constructor to load user data on app start
  AuthService() {
    // listen to auth state changes and load user data when user logs in
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _loadUserData(user.uid);
      } else {
        _currentUserModel = null;
        notifyListeners();
      }
    });
  }

  // sign in with email and password
  Future<String?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _loadUserData(result.user!.uid);
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'No user found with this email.';
      } else if (e.code == 'wrong-password') {
        return 'Incorrect password.';
      } else if (e.code == 'invalid-email') {
        return 'Invalid email address.';
      } else if (e.code == 'user-disabled') {
        return 'This account has been disabled.';
      }
      return 'An error occurred. Please try again.';
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  // sign UP with email and password
  Future<String?> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? program, // only for students
    String? position, // only for admins
    String? adminCode // can be left blank for student accs
  }) async {
    try {
      bool isAdminSignup = adminCode != null && adminCode.isNotEmpty;

      if (isAdminSignup && adminCode != ADMIN_CODE) { // entered admin code wrong
        return "invalid admin code; please contact an administrator if there has been an issue.";
      }

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // create user document in Firestore
      UserModel newUser;

      if (isAdminSignup) {
        // create new admin user
        newUser = UserModel(
          uid: result.user!.uid,
          email: email,
          firstName: firstName,
          lastName: lastName,
          program: position ?? '', // use program field to store admin position
          rank: "n/a", // admins don't have rank
          role: "admin",
          createdAt: DateTime.now(),
        );
      } else {
        // create new student user
        if (program == null) {
          return "program selection is required for students.";
        }
        newUser = UserModel(
          uid: result.user!.uid,
          email: email,
          firstName: firstName,
          lastName: lastName,
          program: program,
          rank: 'White Belt',
          role: 'student',
          createdAt: DateTime.now(),
        );
      }

      await _firestore.collection('users').doc(result.user!.uid).set(newUser.toMap());

      _currentUserModel = newUser;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return 'Password is too weak. Please use a stronger password.';
      } else if (e.code == 'email-already-in-use') {
        return 'An account already exists with this email.';
      } else if (e.code == 'invalid-email') {
        return 'Invalid email address.';
      }
      return 'An error occurred during sign up.';
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  // load user data from Firestore
  Future<void> _loadUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUserModel = UserModel.fromFirestore(doc);
        notifyListeners();
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  // sign out
  Future<void> signOut() async {
    await _auth.signOut();
    _currentUserModel = null;
    notifyListeners();
  }

  // reset password
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'No user found with this email.';
      } else if (e.code == 'invalid-email') {
        return 'Invalid email address.';
      }
      return 'An error occurred. Please try again.';
    }
  }

  // check if user holds admin status
  bool get isAdmin => _currentUserModel?.role == 'admin';

  // refresh user data
  Future<void> refreshUserData() async {
    if (currentUser != null) {
      await _loadUserData(currentUser!.uid);
      notifyListeners();
    }
  }
}