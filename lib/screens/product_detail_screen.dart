import 'package:flutter/material.dart';
import 'package:ecommerce_app/providers/cart_provider.dart'; // 1. ADD THIS
import 'package:provider/provider.dart'; // 2. ADD THIS
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 1. Change StatelessWidget to StatefulWidget
class ProductDetailScreen extends StatefulWidget {
  // 2. We will pass in the product's data (the map)
  final Map<String, dynamic> productData;
  // 3. We'll also pass the unique product ID (critical for 'Add to Cart' later)
  final String productId;

  // 4. The constructor takes both parameters
  const ProductDetailScreen({
    super.key,
    required this.productData,
    required this.productId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

// 5. Rename the main class to _ProductDetailScreenState and extend State
class _ProductDetailScreenState extends State<ProductDetailScreen> {
  // 6. ADD OUR NEW STATE VARIABLE FOR QUANTITY
  int _quantity = 1;

  // 7. ADD THIS FUNCTION
  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  // 8. ADD THIS FUNCTION
  void _decrementQuantity() {
    // We don't want to go below 1
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  // ADD STATE FOR COMMENTS
  final TextEditingController _commentController = TextEditingController();
  String _userRole = 'user'; // Default to user
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return;
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          final data = doc.data()!;
          if (data.containsKey('role') && data['role'] is String) {
            _userRole = data['role'] as String;
          }
        });
      }
    } catch (e) {
      print("Error fetching user role: $e");
    }
  }

  Future<void> _addComment() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null || _commentController.text.trim().isEmpty) return;

    try {
      // Fetch user role
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final userRole = userDoc.exists && userDoc.data() != null
          ? userDoc.data()!['role'] ?? 'user'
          : 'user';

      await _firestore
          .collection('products')
          .doc(widget.productId)
          .collection('comments')
          .add({
            'text': _commentController.text.trim(),
            'userId': currentUser.uid,
            'userEmail': currentUser.email ?? 'Anonymous',
            'userRole': userRole,
            'timestamp': FieldValue.serverTimestamp(),
          });
      _commentController.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Comment added!')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add comment: $e')));
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await _firestore
          .collection('products')
          .doc(widget.productId)
          .collection('comments')
          .doc(commentId)
          .delete();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Comment deleted!')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete comment: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Extract data from the map for easier use
    final String name = widget.productData['name'];
    final String description = widget.productData['description'];
    final String imageUrl = widget.productData['imageUrl'];
    final double price = widget.productData['price'];
    final double rating = widget.productData['rating'] ?? 0.0;

    // 1. ADD THIS LINE: Get the CartProvider
    // We set listen: false because we are not rebuilding, just calling a function
    final cart = Provider.of<CartProvider>(context, listen: false);

    // 2. The main screen widget
    return Scaffold(
      appBar: AppBar(
        // 3. Show the product name in the top bar
        title: Text(name),
      ),
      // 4. This allows scrolling if the description is very long
      body: SingleChildScrollView(
        child: Column(
          // 5. Make children fill the width
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 6. The large product image
            Image.network(
              imageUrl,
              height: 300, // Give it a fixed height
              fit: BoxFit.cover, // Make it fill the space
              // 7. Add the same loading/error builders as the card
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const SizedBox(
                  height: 300,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox(
                  height: 300,
                  child: Center(child: Icon(Icons.broken_image, size: 100)),
                );
              },
            ),

            // 8. A Padding widget to contain all the text
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 9. Product Name (large font)
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 10. Price (large font, different color)
                  Text(
                    '₱${price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Rating Stars
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          size: 24,
                          color: Colors.amber,
                        );
                      }),
                      const SizedBox(width: 8),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 11. A horizontal dividing line
                  const Divider(thickness: 1),
                  const SizedBox(height: 16),

                  // 12. The full description
                  Text(
                    'About this item',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5, // Adds line spacing for readability
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 13. --- ADD THIS NEW SECTION ---
                  //    (before the "Add to Cart" button)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 14. DECREMENT BUTTON
                      IconButton.filledTonal(
                        icon: const Icon(Icons.remove),
                        onPressed: _decrementQuantity,
                      ),

                      // 15. QUANTITY DISPLAY
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          '$_quantity', // 16. Display our state variable
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // 17. INCREMENT BUTTON
                      IconButton.filled(
                        icon: const Icon(Icons.add),
                        onPressed: _incrementQuantity,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // --- END OF NEW SECTION ---

                  // 18. The "Add to Cart" button
                  ElevatedButton.icon(
                    onPressed: () {
                      // 4. THIS IS THE UPDATED LOGIC!
                      // Call the addItem function from our provider with quantity
                      cart.addItem(widget.productId, name, price, _quantity);

                      // 5. Show a confirmation pop-up with quantity
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added $_quantity x $name to cart!'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.shopping_cart_outlined),
                    label: const Text('Add to Cart'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // COMMENTS SECTION
                  const Divider(thickness: 1),
                  const SizedBox(height: 16),
                  Text(
                    'Comments',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  // ADD COMMENT FORM (only if logged in)
                  if (_auth.currentUser != null) ...[
                    TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        labelText: 'Add a comment...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _addComment,
                      child: const Text('Post Comment'),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    const Text('Please log in to add comments.'),
                    const SizedBox(height: 16),
                  ],

                  // DISPLAY COMMENTS
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('products')
                        .doc(widget.productId)
                        .collection('comments')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Text('Error loading comments.');
                      }
                      final comments = snapshot.data!.docs;
                      if (comments.isEmpty) {
                        return const Text(
                          'No comments yet. Be the first to comment!',
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final commentDoc = comments[index];
                          final commentData =
                              commentDoc.data() as Map<String, dynamic>;
                          final commentText = commentData['text'] ?? '';
                          final userEmail =
                              commentData['userEmail'] ?? 'Anonymous';
                          final userRole = commentData['userRole'] ?? 'user';
                          final timestamp =
                              commentData['timestamp'] as Timestamp?;
                          final formattedTime = timestamp != null
                              ? '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year} ${timestamp.toDate().hour}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
                              : 'Unknown time';

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '$userEmail ($userRole)',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (_userRole == 'admin')
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () =>
                                              _deleteComment(commentDoc.id),
                                        ),
                                    ],
                                  ),
                                  Text(commentText),
                                  const SizedBox(height: 4),
                                  Text(
                                    formattedTime,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
