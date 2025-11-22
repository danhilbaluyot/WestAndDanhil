// Part 1: Imports
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 1. ADD THIS IMPORT
import 'package:flutter/material.dart';
import 'package:ecommerce_app/screen/login_screen.dart';
import 'package:ecommerce_app/screen/admin_panel_screen.dart'; // 2. ADD THIS
import 'package:ecommerce_app/widgets/product_card.dart'; // ProductCard widget
import 'package:ecommerce_app/screens/product_detail_screen.dart'; // 1. ADD THIS IMPORT
import 'package:ecommerce_app/providers/cart_provider.dart'; // 1. ADD THIS
import 'package:ecommerce_app/screens/cart_screen.dart'; // 2. ADD THIS
import 'package:provider/provider.dart'; // 3. ADD THIS
import 'package:ecommerce_app/screens/order_history_screen.dart'; // 1. ADD THIS
import 'package:ecommerce_app/screens/profile_screen.dart'; // 1. ADD THIS
import 'package:ecommerce_app/widgets/notification_icon.dart'; // 1. ADD THIS
import 'package:ecommerce_app/screens/chat_screen.dart'; // ADD THIS FOR CHAT

// Part 2: Widget Definition
// 3. Change StatelessWidget to StatefulWidget
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  // 4. Create the State class
  State<HomeScreen> createState() => _HomeScreenState();
}

// 5. Rename the main class to _HomeScreenState and extend State
class _HomeScreenState extends State<HomeScreen> {
  // 1. A state variable to hold the user's role. Default to 'user'.
  String _userRole = 'user';

  // 2. Get the current user from Firebase Auth
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // 3. Get Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 3. This function runs ONCE when the screen is first created
  @override
  void initState() {
    super.initState();
    // 4. Call our function to get the role as soon as the screen loads
    _fetchUserRole();
    // 5. Load the cart from Firestore
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CartProvider>(context, listen: false).loadCartFromFirestore();
    });
  }

  // 5. This is our new function to get data from Firestore
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
          final data = doc.data()!;
          if (data.containsKey('role') && data['role'] is String) {
            _userRole = data['role'] as String;
          }
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print("Error fetching user role: $e");
      // If there's an error, they'll just keep the 'user' role
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 1. --- THIS IS THE CHANGE ---
        //    DELETE your old title:
        /*
        title: Text(_currentUser != null ? 'Welcome!' : 'Home'),
        */

        // 2. ADD this new title:
        title: Image.asset(
          'assets/images/app_logo.png', // 3. The path to your logo
          height: 40, // 4. Set a fixed height
        ),
        // 5. 'centerTitle' is now handled by our global AppBarTheme
        actions: [
          // 1. --- ADD THIS NEW WIDGET ---
          // This is a special, efficient way to use Provider
          Consumer<CartProvider>(
            // 2. The "builder" function rebuilds *only* the icon
            builder: (context, cart, child) {
              // 3. The "Badge" widget adds a small label
              return Badge(
                // 4. Get the count from the provider
                label: Text(cart.itemCount.toString()),
                // 5. Only show the badge if the count is > 0
                isLabelVisible: cart.itemCount > 0,
                // 6. This is the child (our icon button)
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () {
                    // 7. Navigate to the CartScreen
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CartScreen(),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          // 2. --- ADD THIS NEW BUTTON ---
          IconButton(
            icon: const Icon(Icons.receipt_long), // A "receipt" icon
            tooltip: 'My Orders',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const OrderHistoryScreen(),
                ),
              );
            },
          ),

          // 3. --- ADD OUR NEW WIDGET ---
          const NotificationIcon(),
          // --- END OF NEW WIDGET ---

          // 4. --- THIS IS THE MAGIC ---
          //    This is a "collection-if". The IconButton will only
          //    be built IF _userRole is equal to 'admin'.
          if (_userRole == 'admin')
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Admin Panel',
              onPressed: () {
                // 5. This is why we imported admin_panel_screen.dart
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdminPanelScreen(),
                  ),
                );
              },
            ),

          // 6. --- REPLACE THE LOGOUT BUTTON WITH PROFILE BUTTON ---
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Query the products collection, newest first
        stream: FirebaseFirestore.instance
            .collection('products')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No products found. Add some in the Admin Panel!'),
            );
          }

          final products = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(10.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 3 / 4,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              // 1. Get the whole document
              final productDoc = products[index];
              // 2. Get the data map
              final productData = productDoc.data() as Map<String, dynamic>;

              final name = (productData['name'] ?? 'No name').toString();
              final imageUrl = (productData['imageUrl'] ?? '').toString();

              // Safely parse price to double
              final rawPrice = productData['price'];
              double price;
              if (rawPrice is num) {
                price = rawPrice.toDouble();
              } else if (rawPrice is String) {
                price = double.tryParse(rawPrice) ?? 0.0;
              } else {
                price = 0.0;
              }

              // Safely parse rating to double
              final rawRating = productData['rating'];
              double rating;
              if (rawRating is num) {
                rating = rawRating.toDouble();
              } else if (rawRating is String) {
                rating = double.tryParse(rawRating) ?? 0.0;
              } else {
                rating = 0.0;
              }

              // 3. Find your old ProductCard
              return ProductCard(
                productName: name,
                price: price,
                imageUrl: imageUrl,
                rating: rating, // ADD THIS LINE
                // 4. --- THIS IS THE NEW PART ---
                //    Add the onTap property
                onTap: () {
                  // 5. Navigate to the new screen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProductDetailScreen(
                        // 6. Pass the data to the new screen
                        productData: productData,
                        productId: productDoc.id, // 7. Pass the unique ID!
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),

      // --- ADD FLOATING ACTION BUTTON FOR USERS ---
      floatingActionButton: _userRole == 'user'
          ? StreamBuilder<DocumentSnapshot>(
              // Listen to *this user's* chat document
              stream: _firestore
                  .collection('chats')
                  .doc(_currentUser!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                int unreadCount = 0;
                // Check if the doc exists and has our count field
                if (snapshot.hasData && snapshot.data!.exists) {
                  // Ensure data is not null before casting
                  final data = snapshot.data!.data();
                  if (data != null) {
                    unreadCount =
                        (data as Map<String, dynamic>)['unreadByUserCount'] ??
                        0;
                  }
                }

                // Wrap the FAB in the Badge widget
                return Badge(
                  // Show the count in the badge
                  label: Text('$unreadCount'),
                  // Only show the badge if the count is > 0
                  isLabelVisible: unreadCount > 0,
                  // The FAB is now the *child* of the Badge
                  child: FloatingActionButton.extended(
                    icon: const Icon(Icons.support_agent),
                    label: const Text('Contact Admin'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              ChatScreen(chatRoomId: _currentUser.uid),
                        ),
                      );
                    },
                  ),
                );
              },
            )
          : null, // If admin, don't show the FAB
    );
  }
}
