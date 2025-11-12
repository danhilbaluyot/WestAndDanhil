import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ecommerce_app/widgets/order_card.dart'; // 1. Import our new card

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 2. Get the current user
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      // 3. Check if the user is logged in
      body: user == null
          ? const Center(child: Text('Please log in to see your orders.'))
          // 4. If logged in, show the StreamBuilder
          : StreamBuilder<QuerySnapshot>(
              // 5. --- THIS IS THE CRITICAL NEW QUERY ---
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  // 6. Filter the 'orders' collection
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),

              builder: (context, snapshot) {
                // 8. Handle loading state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 9. Handle error state
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                // 10. Handle no data (no orders)
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('You have not placed any orders yet.'),
                  );
                }

                // 11. We have data! Get the list of order documents
                final orderDocs = snapshot.data!.docs;

                // 12. Sort the orders by createdAt descending (newest first)
                orderDocs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aTimestamp = aData['createdAt'] as Timestamp?;
                  final bTimestamp = bData['createdAt'] as Timestamp?;
                  if (aTimestamp == null && bTimestamp == null) return 0;
                  if (aTimestamp == null) return 1;
                  if (bTimestamp == null) return -1;
                  return bTimestamp.compareTo(aTimestamp); // Descending
                });

                // 13. Use ListView.builder to show the list
                return ListView.builder(
                  itemCount: orderDocs.length,
                  itemBuilder: (context, index) {
                    // 14. Get the data for a single order
                    final orderData =
                        orderDocs[index].data() as Map<String, dynamic>;

                    // 15. Return our custom OrderCard widget
                    return OrderCard(orderData: orderData);
                  },
                );
              },
            ),
    );
  }
}
