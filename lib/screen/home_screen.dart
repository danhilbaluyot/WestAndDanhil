// Part 1: Imports
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ecommerce_app/screen/login_screen.dart';

// Part 2: Widget Definition
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          // 1. Add an IconButton to the AppBar
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // 2. Call Firebase to sign out
              FirebaseAuth.instance.signOut();
              // Since some flows replace the AuthWrapper on the navigator stack
              // we also clear routes and send the user to LoginScreen.
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: const Center(child: Text('You are logged in!')),
    );
  }
}
