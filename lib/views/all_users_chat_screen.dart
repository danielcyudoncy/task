// views/all_users_chat_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'chat_screen.dart';

class AllUsersChatScreen extends StatelessWidget {
  const AllUsersChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to chat')),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.primary,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        title: const Text('All Users'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Search not implemented yet
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('uid', isNotEqualTo: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          }

          if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: TextStyle(color: Colors.white)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text('No other users found',
                    style: TextStyle(color: Colors.white)));
          }

          final users = snapshot.data!.docs;

          return ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            itemCount: users.length,
            separatorBuilder: (_, __) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              final user = users[index];
              final userData = user.data() as Map<String, dynamic>;
              final name = userData['fullName'] ?? 'Unknown';
              final email = userData['email'] ?? '';
              final avatar = userData['profilePic'] ?? '';
              final receiverId = user.id;

              return GestureDetector(
                onTap: () async {
                  final conversationQuery = await FirebaseFirestore.instance
                      .collection('conversations')
                      .where('participants', arrayContains: currentUserId)
                      .get();

                  DocumentSnapshot? existingConvo;

                  for (final doc in conversationQuery.docs) {
                    final data = doc.data();
                    final participants =
                        List<String>.from(data['participants']);
                    if (participants.contains(receiverId) &&
                        participants.length == 2) {
                      existingConvo = doc;
                      break;
                    }
                  }

                  String conversationId;

                  if (existingConvo != null) {
                    conversationId = existingConvo.id;
                  } else {
                    final newConvo = await FirebaseFirestore.instance
                        .collection('conversations')
                        .add({
                      'participants': [currentUserId, receiverId],
                      'createdAt': FieldValue.serverTimestamp(),
                      'lastMessageTime': FieldValue.serverTimestamp(),
                      'unreadCount': {
                        currentUserId: 0,
                        receiverId: 0,
                      },
                      'pinnedUsers': [],
                    });
                    conversationId = newConvo.id;
                  }

                  Get.to(() => ChatScreen(
                        receiverId: receiverId,
                        receiverName: name,
                        receiverAvatar: avatar,
                        conversationId: conversationId,
                        otherUserId: '',
                        otherUserName: null,
                        otherUser: const {},
                        chatId: '',
                      ));
                },
                child: Card(
                  color: theme.colorScheme.surface,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28.r,
                          backgroundColor:
                              theme.colorScheme.surfaceVariant.withOpacity(0.5),
                          backgroundImage:
                              avatar.isNotEmpty ? NetworkImage(avatar) : null,
                          child: avatar.isEmpty
                              ? Text(
                                  name[0].toUpperCase(),
                                  style: textTheme.titleLarge?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : null,
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                email,
                                style: textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
