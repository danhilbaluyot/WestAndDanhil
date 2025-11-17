import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting the date

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. This function will mark a single notification as "read"
  void _markNotificationAsRead(QueryDocumentSnapshot doc) {
    if (doc['isRead'] == false) {
      // 2. Update the document to mark as read
      doc.reference.update({'isRead': true});
    }
  }

  // Function to mark all notifications as read
  void _markAllAsRead() async {
    final user = _user;
    if (user == null) return;

    final batch = _firestore.batch();
    final querySnapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in querySnapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text(
              'Mark All Read',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: _user == null
          ? const Center(child: Text('Please log in.'))
          : StreamBuilder<QuerySnapshot>(
              // 5. Get ALL notifications for this user
              stream: _firestore
                  .collection('notifications')
                  .where('userId', isEqualTo: _user.uid)
                  .snapshots(),

              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading notifications: ${snapshot.error}',
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('You have no notifications.'),
                  );
                }

                final docs = snapshot.data!.docs;

                // Sort notifications by createdAt descending (newest first)
                docs.sort((a, b) {
                  final aTime =
                      (a['createdAt'] as Timestamp?)?.toDate() ??
                      DateTime.fromMillisecondsSinceEpoch(0);
                  final bTime =
                      (b['createdAt'] as Timestamp?)?.toDate() ??
                      DateTime.fromMillisecondsSinceEpoch(0);
                  return bTime.compareTo(aTime);
                });

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final timestamp = (data['createdAt'] as Timestamp?);
                    final formattedDate = timestamp != null
                        ? DateFormat(
                            'MM/dd/yy hh:mm a',
                          ).format(timestamp.toDate())
                        : '';

                    // Check if this notification is unread
                    final bool isUnread = data['isRead'] == false;

                    return Dismissible(
                      key: Key(docs[index].id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        // Delete the notification
                        docs[index].reference.delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Notification deleted')),
                        );
                      },
                      child: ListTile(
                        // Show a "new" icon if it is unread
                        leading: isUnread
                            ? const Icon(
                                Icons.circle,
                                color: Colors.red,
                                size: 12,
                              )
                            : const Icon(
                                Icons.circle_outlined,
                                color: Colors.grey,
                                size: 12,
                              ),
                        title: Text(
                          data['title'] ?? 'No Title',
                          style: TextStyle(
                            fontWeight: isUnread
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text('${data['body'] ?? ''}\n$formattedDate'),
                        isThreeLine: true,
                        onTap: () {
                          // Mark this notification as read when tapped
                          _markNotificationAsRead(docs[index]);
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
