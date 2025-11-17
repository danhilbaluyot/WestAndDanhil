import 'dart:async'; // For StreamSubscription
import 'package:flutter/foundation.dart'; // Gives us ChangeNotifier
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 1. A simple class to hold the data for an item in the cart
class CartItem {
  final String id; // The unique product ID
  final String name;
  final double price;
  int quantity; // Quantity can change, so it's not final

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1, // Default to 1 when added
  });

  // 1. ADD THIS: Convert CartItem to a Map for Firestore
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'price': price, 'quantity': quantity};
  }
}

// 1. The CartProvider class "mixes in" ChangeNotifier
class CartProvider with ChangeNotifier {
  // 2. This is the private list of items.
  //    No one outside this class can access it directly.
  final List<CartItem> _items = [];

  // 3. A public "getter" to let widgets *read* the list of items
  List<CartItem> get items => _items;

  // 4. A public "getter" to calculate the total number of items
  int get itemCount {
    // This 'fold' is a cleaner way to sum a list.
    return _items.fold(0, (total, item) => total + item.quantity);
  }

  // 5. RENAME 'totalPrice' to 'subtotal'
  //    This is the total price *before* tax.
  double get subtotal {
    double total = 0.0;
    for (var item in _items) {
      total += (item.price * item.quantity);
    }
    return total;
  }

  // 6. ADD this new getter for VAT (12%)
  double get vat {
    return subtotal * 0.12; // 12% of the subtotal
  }

  // 7. ADD this new getter for the FINAL total
  double get totalPriceWithVat {
    return subtotal + vat;
  }

  // 6. Get the current user ID
  String? _userId;

  // 7. Get Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 8. Get Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 9. Subscription for auth changes
  StreamSubscription<User?>? _authSubscription;

  // 10. ADD THIS: Empty constructor
  CartProvider() {
    print('CartProvider created.');
  }

  // 11. ADD THIS: New public method to initialize auth listener
  void initializeAuthListener() {
    print('CartProvider auth listener initialized');
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        print('User logged out, clearing cart.');
        _userId = null;
        _items.clear();
      } else {
        print('User logged in: ${user.uid}. Fetching cart...');
        _userId = user.uid;
        _fetchCart();
      }
      notifyListeners();
    });
  }

  // 12. ADD THIS: Private method to fetch cart from Firestore
  Future<void> _fetchCart() async {
    if (_userId == null) return;

    try {
      final doc = await _firestore.collection('userCarts').doc(_userId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final cartItems = data['cartItems'] as List<dynamic>? ?? [];

        _items.clear();
        for (var item in cartItems) {
          if (item is Map<String, dynamic>) {
            _items.add(
              CartItem(
                id: item['id'],
                name: item['name'],
                price: item['price'],
                quantity: item['quantity'] ?? 1,
              ),
            );
          }
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching cart: $e');
    }
  }

  // 8. The main logic: "Add Item to Cart"
  void addItem(String id, String name, double price, int quantity) {
    // 9. Check if the item is already in the cart
    var index = _items.indexWhere((item) => item.id == id);

    if (index != -1) {
      // 10. If YES: add the new quantity to the existing quantity
      _items[index].quantity += quantity;
    } else {
      // 11. If NO: add it to the list as a new item with the specified quantity
      _items.add(
        CartItem(id: id, name: name, price: price, quantity: quantity),
      );
    }

    // 12. Save to Firestore if logged in
    if (_userId != null) {
      _saveCartToFirestore();
    }

    // 13. CRITICAL: This tells all "listening" widgets to rebuild!
    notifyListeners();
  }

  // 14. The "Remove Item from Cart" logic
  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);

    // 15. Save to Firestore if logged in
    if (_userId != null) {
      _saveCartToFirestore();
    }

    notifyListeners(); // Tell widgets to rebuild
  }

  // 16. Save the cart to Firestore
  Future<void> _saveCartToFirestore() async {
    if (_userId == null) return;

    try {
      final cartData = _items.map((item) => item.toJson()).toList();
      await _firestore.collection('userCarts').doc(_userId).set({
        'cartItems': cartData,
      });
    } catch (e) {
      print('Error saving cart to Firestore: $e');
    }
  }

  // 17. Load the cart from Firestore
  Future<void> loadCartFromFirestore() async {
    if (_userId == null) return;

    try {
      final doc = await _firestore.collection('userCarts').doc(_userId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final cartItems = data['cartItems'] as List<dynamic>? ?? [];

        _items.clear();
        for (var item in cartItems) {
          if (item is Map<String, dynamic>) {
            _items.add(
              CartItem(
                id: item['id'],
                name: item['name'],
                price: item['price'],
                quantity: item['quantity'] ?? 1,
              ),
            );
          }
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error loading cart from Firestore: $e');
    }
  }

  // 18. ADD THIS: Creates an order in the 'orders' collection
  Future<void> placeOrder() async {
    // 19. Check if we have a user and items
    if (_userId == null || _items.isEmpty) {
      // Don't place an order if cart is empty or user is logged out
      throw Exception('Cart is empty or user is not logged in.');
    }

    try {
      // 20. Convert our List<CartItem> to a List<Map> using toJson()
      final List<Map<String, dynamic>> cartData = _items
          .map((item) => item.toJson())
          .toList();

      // 21. Get all our new calculated values
      final double sub = subtotal;
      final double v = vat;
      final double total = totalPriceWithVat;
      final int count = itemCount;

      // 22. Create a new document in the 'orders' collection
      await _firestore.collection('orders').add({
        'userId': _userId,
        'items': cartData, // Our list of item maps
        'subtotal': sub, // 23. ADD THIS
        'vat': v, // 24. ADD THIS
        'totalPrice': total, // 25. This is now the VAT-inclusive price
        'itemCount': count,
        'status': 'Pending', // 26. IMPORTANT: For admin verification
        'createdAt': FieldValue.serverTimestamp(), // For sorting
      });

      // 24. Note: We DO NOT clear the cart here.
      //    We'll call clearCart() separately from the UI after this succeeds.
    } catch (e) {
      print('Error placing order: $e');
      // 25. Re-throw the error so the UI can catch it
      rethrow;
    }
  }

  // 26. ADD THIS: Clears the cart locally AND in Firestore
  Future<void> clearCart() async {
    // 27. Clear the local list
    _items.clear();

    // 28. If logged in, clear the Firestore cart as well
    if (_userId != null) {
      try {
        // 29. Set the 'cartItems' field in their cart doc to an empty list
        await _firestore.collection('userCarts').doc(_userId).set({
          'cartItems': [],
        });
        print('Firestore cart cleared.');
      } catch (e) {
        print('Error clearing Firestore cart: $e');
      }
    }

    // 30. Notify all listeners (this will clear the UI)
    notifyListeners();
  }
}
