// views/all_users_chat_screen.dart

// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'chat_screen.dart';
// We no longer need to import the AppDrawer

class AllUsersChatScreen extends StatefulWidget {
  const AllUsersChatScreen({super.key});

  @override
  State<AllUsersChatScreen> createState() => _AllUsersChatScreenState();
}

class _AllUsersChatScreenState extends State<AllUsersChatScreen> {
  String searchQuery = '';
  bool isRefreshing = false;
  // We no longer need the ScaffoldKey
  // final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> _refreshUsers() async {
    setState(() {
      isRefreshing = true;
    });
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? theme.colorScheme.surfaceVariant : theme.colorScheme.primary;

    if (currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to chat')),
      );
    }

    return Scaffold(
      // key and drawer properties are removed
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 1,
        // Remove automaticallyImplyLeading: false to allow a back button if needed,
        // but we will provide a custom leading icon anyway.

        // --- NEW: ADD THE HOME BUTTON ---
        leading: IconButton(
          icon: Icon(Icons.home_outlined,
              color: theme.appBarTheme.iconTheme?.color),
          onPressed: () {
            // Navigate to the main home screen, removing all other screens.
            // Get.until((route) => Get.currentRoute == '/home');
          },
        ),
        title: Text('Chat With Users', style: theme.appBarTheme.titleTextStyle),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12.w),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value.trim()),
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.inputDecorationTheme.fillColor,
                border: theme.inputDecorationTheme.border,
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshUsers,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('uid', isNotEqualTo: currentUserId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !isRefreshing) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No other users found'));
                  }

                  final users = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final fullName =
                        (data['fullName'] ?? '').toString().toLowerCase();
                    final email =
                        (data['email'] ?? '').toString().toLowerCase();
                    return fullName.contains(searchQuery.toLowerCase()) ||
                        email.contains(searchQuery.toLowerCase());
                  }).toList();

                  if (users.isEmpty) {
                    return const Center(
                        child: Text('No users match your search.'));
                  }

                  return ListView.builder(
                    itemCount: users.length,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final userData = user.data() as Map<String, dynamic>;
                      final name = userData['fullName'] ?? 'Unknown';
                      final email = userData['email'] ?? '';
                      final avatar = userData['profilePic'] ?? '';
                      final isOnline = userData['isOnline'] == true;
                      final receiverId = user.id;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 8.h),
                        child: Card(
                          color: theme.colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          elevation: 2,
                          child: ListTile(
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 24.r,
                                  backgroundImage: avatar.isNotEmpty
                                      ? NetworkImage(avatar)
                                      : null,
                                  child: avatar.isEmpty
                                      ? Text(
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurface,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                if (isOnline)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 12.w,
                                      height: 12.h,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: theme.colorScheme.surface,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Text(
                              name,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              email,
                              style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant),
                            ),
                            onTap: () async {
                              // OPTIMIZED QUERY LOGIC
                              final sortedParticipants = [
                                currentUserId,
                                receiverId
                              ]..sort();

                              final querySnapshot = await FirebaseFirestore
                                  .instance
                                  .collection('conversations')
                                  .where('participants',
                                      isEqualTo: sortedParticipants)
                                  .limit(1)
                                  .get();

                              String conversationId;

                              if (querySnapshot.docs.isNotEmpty) {
                                conversationId = querySnapshot.docs.first.id;
                              } else {
                                final newConvo = await FirebaseFirestore
                                    .instance
                                    .collection('conversations')
                                    .add({
                                  'participants': sortedParticipants,
                                  'createdAt': FieldValue.serverTimestamp(),
                                  'lastMessageTime':
                                      FieldValue.serverTimestamp(),
                                });
                                conversationId = newConvo.id;
                              }

                              Get.to(() => ChatScreen(
                                    receiverId: receiverId,
                                    receiverName: name,
                                    receiverAvatar: avatar,
                                    conversationId: conversationId,
                                    otherUserId: receiverId,
                                    otherUserName: name,
                                    otherUser: userData,
                                    chatId: conversationId,
                                  ));
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
