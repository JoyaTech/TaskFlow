import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mindflow/services/auth_service.dart';
import 'package:mindflow/screens/onboarding_screen.dart';
import 'package:mindflow/screens/login_screen.dart';
import 'package:mindflow/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading spinner while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'טוען את MindFlow...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // User is logged in
        if (snapshot.hasData && snapshot.data != null) {
          return const HomePage();
        }

        // User is not logged in - check if first time user
        return FutureBuilder<bool>(
          future: _isFirstTimeUser(),
          builder: (context, firstTimeSnapshot) {
            if (firstTimeSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final isFirstTime = firstTimeSnapshot.data ?? true;
            
            if (isFirstTime) {
              return const OnboardingScreen();
            } else {
              return const LoginScreen();
            }
          },
        );
      },
    );
  }

  /// Check if this is the first time the user opens the app
  Future<bool> _isFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    return !prefs.containsKey('onboarding_completed');
  }
}
