// Part 1: Imports
import 'package:ecommerce_app/screen/home_screen.dart';
import 'package:ecommerce_app/screen/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Part 2: Widget Definition
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Attempt to create the auth stream. If this throws (e.g., Firebase
    // hasn't initialized properly), fall back to showing the LoginScreen so
    // the UI is visible instead of the static splash/logo.
    Stream<User?>? authStream;
    try {
      authStream = FirebaseAuth.instance.authStateChanges();
    } catch (e) {
      debugPrint('AuthWrapper: failed to get authStateChanges(): $e');
      return Scaffold(
        body: Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.yellow[700],
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: const SafeArea(
                child: Text(
                  'DEBUG: Firebase not ready - showing LoginScreen',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
            const Expanded(child: LoginScreen()),
          ],
        ),
      );
    }

    // 2. We use a StreamBuilder to listen for auth changes
    return StreamBuilder<User?>(
      // 3. This is the stream from Firebase
      stream: authStream,

      // 4. The builder runs every time the auth state changes
      builder: (context, snapshot) {
        // Debug prints to help diagnose why the login UI may not appear
        debugPrint('AuthWrapper: connectionState=${snapshot.connectionState}');
        debugPrint('AuthWrapper: hasData=${snapshot.hasData}');
        debugPrint('AuthWrapper: error=${snapshot.error}');

        // 5. If the snapshot is still loading, show a spinner
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 6. If the snapshot has data, a user is logged in
        if (snapshot.hasData) {
          debugPrint('AuthWrapper: user logged in uid=${snapshot.data?.uid}');
          return const HomeScreen(); // Show the home screen
        }

        // 7. If the snapshot has no data, no user is logged in
        debugPrint('AuthWrapper: no user, showing LoginScreen');
        // Wrap LoginScreen with a small banner so it's obvious this branch runs
        return Scaffold(
          body: Column(
            children: [
              Container(
                width: double.infinity,
                color: Colors.yellow[700],
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 12,
                ),
                child: const SafeArea(
                  child: Text(
                    'DEBUG: No authenticated user - showing LoginScreen',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
              const Expanded(child: LoginScreen()),
            ],
          ),
        );
      },
    );
  }
}
