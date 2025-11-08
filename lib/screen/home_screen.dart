import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/screen/login_screen.dart';
import 'package:ecommerce_app/screen/admin_panel_screen.dart';

// Convert to StatefulWidget so we can fetch and react to the user's role
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 1. A state variable to hold the user's role. Default to 'user'.
  String _userRole = 'user';
  // 2. Get the current user from Firebase Auth
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    // 4. Call our function to get the role as soon as the screen loads
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    // 6. If no one is logged in, do nothing
    if (_currentUser == null) return;
    try {
      // 7. Go to the 'users' collection, find the document
      //    matching the current user's ID
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid)
          .get();

      // 8. If the document exists...
      if (doc.exists && doc.data() != null) {
        // 9. ...call setState() to save the role to our variable
        setState(() {
          _userRole = (doc.data()?['role'] as String?) ?? 'user';
        });
      }
    } catch (e) {
      debugPrint("Error fetching user role: $e");
      // If there's an error, they'll just keep the 'user' role
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentUser != null ? 'Welcome, ${_currentUser.email}' : 'Home',
        ),
        actions: [
          // Show Admin Panel button only to admin users
          if (_userRole == 'admin')
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Admin Panel',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdminPanelScreen(),
                  ),
                );
              },
            ),

          // Logout button (always visible)
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _signOut,
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'This is the Home Screen. Products will be listed here!',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
