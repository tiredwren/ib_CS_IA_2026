// signin/signup/user doc creation

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'notification_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _adminCode = "424321438";

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  UserModel? _userModel;
  UserModel? get currUser => _userModel;

  // active firestore subscription, cancelled on sign out
  StreamSubscription<DocumentSnapshot>? _userSub;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _subscribe(user.uid);
      } else {
        _unsub();
        _userModel = null;
        notifyListeners();
      }
    });
  }

  // live snapshot on user doc — reacts to any admin edit (nextPay, rank, etc.) without re-auth
  void _subscribe(String uid) {
    _unsub(); // drop any existing listener first

    _userSub = _db.collection('users').doc(uid).snapshots().listen((doc) async {
      if (!doc.exists) return;

      final updated = UserModel.fromFirestore(doc);
      final prevPay = _userModel?.nextPay;
      _userModel = updated;

      // only reschedule if nextPay changed, avoids redundant notif ops on unrelated updates
      if (updated.role == 'student' && updated.nextPay != null) {
        if (prevPay == null || prevPay != updated.nextPay) {
          debugPrint('nextPay -> ${updated.nextPay}, rescheduling notif');
          await Notifs.schedRem(updated.nextPay!);
        }
      }

      notifyListeners();
    }, onError: (e) => debugPrint('user stream error: $e'));
  }

  void _unsub() {
    _userSub?.cancel();
    _userSub = null;
  }

  Future<String?> signIn(String email, String password) async {
    try {
      final res = await _auth.signInWithEmailAndPassword(email: email, password: password);
      // eager subscribe in case authStateChanges fires after caller reads _userModel
      _subscribe(res.user!.uid);
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

  // admin signup requires valid admin code
  Future<String?> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String age,
    String? program,  // students only
    String? position, // admins only
    String? adminCode,
  }) async {
    try {
      final isAdmin = adminCode != null && adminCode.isNotEmpty;

      if (isAdmin && adminCode != _adminCode) {
        return "invalid admin code; please contact an administrator if there has been an issue.";
      }

      final res = await _auth.createUserWithEmailAndPassword(email: email, password: password);

      UserModel newUser;

      if (isAdmin) {
        // position stored in program field for admin accounts
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
        // students start at white belt
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
      _subscribe(res.user!.uid);
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

  Future<void> signOut() async {
    _unsub();
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

  // read from cache, avoids redundant fetches
  bool get isAdmin => _userModel?.role == 'admin';

  // snapshot listener handles this automatically, but kept for explicit refresh eg. post rank update
  Future<void> refresh() async {
    if (currentUser != null) _subscribe(currentUser!.uid);
  }
}