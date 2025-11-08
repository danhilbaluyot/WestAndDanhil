import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/screen/auth_wrapper.dart';

// Import the native splash package so we can preserve/remove the native splash
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  // 1. Preserve the splash screen
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  // Safety: ensure the native splash is removed after 3 seconds even if
  // Firebase initialization stalls (prevents index.html splash from staying forever).
  Future.delayed(const Duration(seconds: 3), () {
    try {
      FlutterNativeSplash.remove();
    } catch (_) {}
  });

  // 2. Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, st) {
    // If Firebase fails to initialize, print details and show a simple error app
    debugPrint('Firebase.initializeApp failed: $e');
    debugPrint('$st');
    // Remove the native splash so our error UI is visible
    FlutterNativeSplash.remove();

    // Show a minimal app that displays the initialization error so the user
    // doesn't just see the static splash (index.html) and thinks the app is frozen.
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          appBar: AppBar(title: const Text('Initialization Error')),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Failed to initialize Firebase.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(e.toString()),
                  const SizedBox(height: 12),
                  const Text('See console logs for stack trace.'),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return;
  }

  // 2b. One-time Firestore connectivity test (will log success/failure).
  // This helps diagnose whether the app can reach Firestore at startup.
  try {
    final firestore = FirebaseFirestore.instance;
    final docRef = firestore.collection('diagnostics').doc('connectivity_test');
    // Write a timestamp; this requires write permissions in your Firestore rules.
    await docRef.set({'checkedAt': FieldValue.serverTimestamp()});
    final snapshot = await docRef.get();
    debugPrint(
      'Firestore connectivity test: success. Document exists=${snapshot.exists}',
    );
  } catch (e) {
    debugPrint('Firestore connectivity test failed: $e');
  }

  // 3. Run the app
  runApp(const MyApp());

  // 4. Remove the splash screen after app is ready
  FlutterNativeSplash.remove();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. MaterialApp is the root of your app
    return MaterialApp(
      // 2. This removes the "Debug" banner
      debugShowCheckedModeBanner: false,
      title: 'eCommerce App',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      // 3. Use AuthWrapper as the home so the app reacts to auth state
      home: const AuthWrapper(),
    );
  }
}
