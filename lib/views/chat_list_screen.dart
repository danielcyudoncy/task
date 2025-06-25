// views/chat_list_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:task/views/chat_screen.dart';

import '../controllers/auth_controller.dart';


class ChatListScreen extends StatelessWidget {
  final AuthController authController = Get.find<AuthController>();

  ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implement search functionality
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('conversations')
            .where('participants',
                arrayContains: FirebaseAuth.instance.currentUser!.uid)
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat, size: 48.sp, color: Colors.grey),
                  SizedBox(height: 16.h),
                  Text(
                    'No conversations yet',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          final conversations = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation =
                  conversations[index].data() as Map<String, dynamic>;
              final participants =
                  conversation['participants'] as List<dynamic>;
              final receiverId = participants.firstWhere(
                (id) => id != FirebaseAuth.instance.currentUser!.uid,
              ) as String;
              final lastMessage = conversation['lastMessage'] ?? '';
              final lastMessageTime =
                  conversation['lastMessageTime'] as Timestamp?;
              final unreadCount = conversation['unreadCount'] ?? 0;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(receiverId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(title: Text('Loading...'));
                  }

                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  final userName = userData['name'] ?? 'Unknown User';
                  final userAvatar = userData['profilePic'] ?? '';

                  return Card(
                    margin:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: userAvatar.isNotEmpty
                            ? NetworkImage(userAvatar)
                            : null,
                        child: userAvatar.isEmpty
                            ? Text(
                                userName.isNotEmpty
                                    ? userName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  color: isDark ? Colors.black : Colors.white,
                                ),
                              )
                            : null,
                      ),
                      title: Text(
                        userName,
                        style: TextStyle(
                          fontWeight: unreadCount > 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 16.sp,
                        ),
                      ),
                      subtitle: Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (lastMessageTime != null)
                            Text(
                              _formatTime(lastMessageTime.toDate()),
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[600],
                              ),
                            ),
                          if (unreadCount > 0)
                            Container(
                              padding: EdgeInsets.all(6.r),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                unreadCount.toString(),
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        Get.to(
                          () => ChatScreen(
                            receiverId: receiverId,
                            receiverName: userName,
                            receiverAvatar: userAvatar,
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return DateFormat('HH:mm').format(date);
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM dd').format(date);
    }
  }
}
