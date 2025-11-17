import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:ecommerce_app/screen/auth_wrapper.dart';
import 'package:ecommerce_app/providers/cart_provider.dart'; // 1. ADD THIS
import 'package:provider/provider.dart'; // 2. ADD THIS
import 'package:firebase_auth/firebase_auth.dart'; // 3. ADD THIS
import 'package:google_fonts/google_fonts.dart'; // 1. ADD THIS IMPORT

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set web persistence
  await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);

  // Create the CartProvider instance
  final cartProvider = CartProvider();

  // Initialize auth listener
  cartProvider.initializeAuthListener();

  runApp(
    ChangeNotifierProvider.value(value: cartProvider, child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'eCommerce App',

      // 1. --- THIS IS THE NEW, COMPLETE THEME ---
      theme: ThemeData(
        // 2. Set the main color scheme
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue, // Changed to blue color palette
          brightness: Brightness.light,
          primary: Colors.blue,
          onPrimary: Colors.white,
          secondary: Colors.blueAccent,
          background: Colors.white, // Clean white background
        ),
        useMaterial3: true,

        // 3. Set the background color for all screens
        scaffoldBackgroundColor: Colors.white,

        // 4. --- (FIX) APPLY THE GOOGLE FONT ---
        // This applies "Lato" to all text in the app
        textTheme: GoogleFonts.latoTextTheme(Theme.of(context).textTheme),

        // 5. --- (FIX) GLOBAL BUTTON STYLE ---
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue, // Use blue color
            foregroundColor: Colors.white, // Text color
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Rounded corners
            ),
          ),
        ),

        // 6. --- (FIX) GLOBAL TEXT FIELD STYLE ---
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          labelStyle: TextStyle(color: Colors.blue.withOpacity(0.8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 2.0),
          ),
        ),

        // 7. --- (FIX) GLOBAL CARD STYLE ---
        cardTheme: CardThemeData(
          elevation: 1, // A softer shadow
          color: Colors.white, // Pure white cards on the off-white bg
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          // 8. This ensures the images inside the card are rounded
          clipBehavior: Clip.antiAlias,
        ),

        // 9. --- (NEW) GLOBAL APPBAR STYLE ---
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white, // Clean white AppBar
          foregroundColor: Colors.black, // Black icons and text
          elevation: 0, // No shadow, modern look
          centerTitle: true,
        ),
      ),

      // --- END OF NEW THEME ---
      home: const AuthWrapper(),
    );
  }
}
