import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:true_martial_arts_app/screens/home_screen.dart';
import 'package:true_martial_arts_app/screens/login_screen.dart';
import 'package:true_martial_arts_app/services/auth_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder( // listens continuously, no manual nav necessary
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // loading state handled prior to screen rendering
        // prevents wrong screen from flashing for even a second
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // routes to home only when Firebase confirms valid session
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // falls through to login screen if no active session (user unauthenticated)
        return const LoginScreen();
      },
    );
  }
}