// views/all_users_chat_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../controllers/auth_controller.dart';
import '../controllers/settings_controller.dart';
import 'chat_screen.dart';
import 'wallpaper_screen.dart';
import '../controllers/wallpaper_controller.dart';

class AllUsersChatScreen extends StatefulWidget {
  final String? chatBackground;

  const AllUsersChatScreen({super.key, this.chatBackground});

  @override
  State<AllUsersChatScreen> createState() => _AllUsersChatScreenState();
}

class _AllUsersChatScreenState extends State<AllUsersChatScreen> {
  final AuthController authController = Get.find<AuthController>();
  String searchQuery = '';
  bool isRefreshing = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final WallpaperController _wallpaperController = Get.find<WallpaperController>();

  @override
  void initState() {
    super.initState();
    _refreshUsers();
  }

  @override
  void dispose() {
    // Clean up any active operations
    super.dispose();
  }

  Future<void> _refreshUsers() async {
    setState(() => isRefreshing = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => isRefreshing = false);
  }

  void _handleUserTap(DocumentSnapshot user) async {
    final otherUser = user.data() as Map<String, dynamic>;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) return;

    final conversationId = [currentUserId, otherUser['uid']]..sort();
    final chatId = conversationId.join('_');

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final conversationDoc = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(chatId)
          .get();

      if (!conversationDoc.exists) {
        await FirebaseFirestore.instance
            .collection('conversations')
            .doc(chatId)
            .set({
          'participants': [currentUserId, otherUser['uid']],
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            receiverId: otherUser['uid'],
            receiverName: otherUser['fullName'] ?? 'User',
            receiverAvatar: otherUser['photoUrl'] ?? '',
            conversationId: chatId,
            chatId: chatId,
            otherUserId: otherUser['uid'],
            otherUserName: otherUser['fullName'] ?? 'User',
            otherUser: otherUser,
            chatBackground: widget.chatBackground,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to start chat: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Add safety check for build phase
    if (!mounted) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final theme = Theme.of(context);

final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.primary;

    if (currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to chat')),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      body: Obx(() {
        final wallpaperValue = _wallpaperController.wallpaper.value;
        BoxDecoration decoration;
        if (wallpaperValue.isEmpty) {
          decoration = BoxDecoration(color: backgroundColor);
        } else if (wallpaperValue.startsWith('asset:')) {
          final path = wallpaperValue.substring(6);
          decoration = BoxDecoration(
            image: DecorationImage(
              image: AssetImage(path),
              fit: BoxFit.cover,
            ),
          );
        } else if (wallpaperValue.startsWith('#')) {
          decoration = BoxDecoration(color: Color(int.parse('FF${wallpaperValue.substring(1)}', radix: 16)));
        } else {
          decoration = BoxDecoration(color: backgroundColor);
        }
        return Container(
          decoration: decoration,
          child: Column(
            children: [
              AppBar(
                backgroundColor: theme.colorScheme.primary,
                elevation: 1,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: theme.colorScheme.onPrimary),
                  onPressed: () {
                    Get.find<SettingsController>().triggerFeedback();
                    Get.back();
                  },
                ),
                title: Text('Chat With Users', style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                )),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.wallpaper),
                    color: theme.colorScheme.onPrimary,
                    tooltip: 'Change Chat Wallpaper',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const WallpaperScreen()),
                      );
                    },
                  ),
                ],
              ),
              Expanded(
                child: _buildBody(context, currentUserId, theme),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildBody(BuildContext context, String currentUserId, ThemeData theme) {
    return Column(
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
                // Add safety check for build phase
                if (!mounted) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !isRefreshing) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final users = snapshot.data!.docs.where((doc) => doc['uid'] != currentUserId).toList();
                if (users.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('No one is online', style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: users.length,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    // Add safety check for build phase
                    if (!mounted) {
                      return const SizedBox.shrink();
                    }
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
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Theme.of(context).colorScheme.onPrimary
                                        : Theme.of(context).colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
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
    );
  }
}
