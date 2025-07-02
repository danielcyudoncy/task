// views/all_users_chat_screen.dart

// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'chat_screen.dart';

class AllUsersChatScreen extends StatefulWidget {
  // --- NEW: This screen now accepts the wallpaper preference ---
  final String? chatBackground;

  const AllUsersChatScreen({super.key, this.chatBackground});

  @override
  State<AllUsersChatScreen> createState() => _AllUsersChatScreenState();
}

class _AllUsersChatScreenState extends State<AllUsersChatScreen> {
  String searchQuery = '';
  bool isRefreshing = false;

  Future<void> _refreshUsers() async {
    setState(() {
      isRefreshing = true;
    });
    // Simulate network delay for a better refresh indicator experience
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        isRefreshing = false;
      });
    }
  }

  // --- MODIFIED: This function no longer fetches the wallpaper. It uses the one passed to the widget. ---
  Future<void> _handleUserTap(QueryDocumentSnapshot user) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // --- THE KEY CHANGE ---
      // We get the chat background from the widget property passed by the AppDrawer.
      final chatBackground = widget.chatBackground;

      final otherUser = user.data() as Map<String, dynamic>;
      final currentUserId = FirebaseAuth.instance.currentUser!.uid;

      // This logic to find/create a conversation remains the same.
      final querySnapshot = await FirebaseFirestore.instance
          .collection('conversations')
          .where('members', arrayContains: currentUserId)
          .get();

      if (!mounted) return;

      String conversationId = '';
      final existingConversation = querySnapshot.docs.where((doc) {
        final members = List<String>.from(doc['members']);
        return members.contains(otherUser['uid']);
      }).toList();

      if (existingConversation.isNotEmpty) {
        conversationId = existingConversation.first.id;
      } else {
        final newConversation =
            await FirebaseFirestore.instance.collection('conversations').add({
          'members': [currentUserId, otherUser['uid']],
          'lastMessage': '',
          'timestamp': FieldValue.serverTimestamp(),
        });
        if (!mounted) return;
        conversationId = newConversation.id;
      }

      Navigator.of(context, rootNavigator: true)
          .pop(); // Dismiss loading dialog

      if (!mounted) return;

      // Navigate to the final ChatScreen, passing the pre-loaded background along.
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            receiverId: otherUser['uid'],
            receiverName: otherUser['fullName'] ?? 'User',
            receiverAvatar: otherUser['photoUrl'] ?? '',
            conversationId: conversationId,
            chatId: conversationId,
            otherUserId: otherUser['uid'],
            otherUserName: otherUser['fullName'] ?? 'User',
            otherUser: otherUser,
            chatBackground:
                chatBackground, // Pass the preference down the chain
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to start chat: $e')));
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
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.home_outlined, color: theme.colorScheme.onSurface),
          onPressed: () {
            Get.offAllNamed('/home');
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
                      final avatar = userData['photoUrl'] ?? '';
                      final isOnline = userData['isOnline'] == true;

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
                            onTap: () => _handleUserTap(user),
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
